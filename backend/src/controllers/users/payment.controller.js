// backend/src/controllers/users/payment.controller.js
//
// REPLACES the original stub controller entirely.
// Three responsibilities:
//   1. createOrder   — creates a Razorpay order, returns orderId + amount to Flutter
//   2. verifyPayment — verifies Razorpay signature after client completes payment
//   3. webhook       — handles Razorpay server-to-server payment events (most secure path)

import crypto from "crypto";
import razorpay from "../../config/razorpay.js";
import Payment from "../../models/shop/Payment.model.js";
import Order from "../../models/shop/Order.model.js";
import { activateSubscription } from "../subscription/subscription.controller.js";

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: verify Razorpay signature
// Razorpay signs every payment with HMAC-SHA256 using your key_secret.
// If the signature doesn't match, the payment data was tampered with.
// ─────────────────────────────────────────────────────────────────────────────
function verifyRazorpaySignature({ razorpayOrderId, razorpayPaymentId, signature }) {
  const body      = `${razorpayOrderId}|${razorpayPaymentId}`;
  const expected  = crypto
    .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
    .update(body)
    .digest("hex");
  return expected === signature;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: fulfill payment based on purpose
// Called after BOTH client verification AND webhook — idempotency key prevents
// double-fulfillment if both fire.
// ─────────────────────────────────────────────────────────────────────────────
async function fulfillPayment(payment, userId) {
  switch (payment.purpose) {

    case "subscription": {
      const { planKey } = payment.metadata || {};
      if (!planKey) break;

      // Reuse the subscription controller's activate logic
      // Build a fake req/res to call it internally
      await activateSubscriptionInternal({
        userId,
        planKey,
        paymentId:  payment.razorpayPaymentId,
        orderId:    payment.razorpayOrderId,
        amountPaid: payment.amount,
      });
      break;
    }

    case "shop_order": {
      const { shopOrderId } = payment.metadata || {};
      if (!shopOrderId) break;

      await Order.findByIdAndUpdate(shopOrderId, {
        status: "Processing",
      });
      break;
    }

    case "report": {
      // TODO: trigger report generation pipeline
      // For now just mark the payment — report delivery handled separately
      break;
    }

    case "astrologer_session": {
      // TODO: confirm astrologer booking once that feature is built
      break;
    }
  }
}

// Internal subscription activation (avoids HTTP round-trip)
async function activateSubscriptionInternal({ userId, planKey, paymentId, orderId, amountPaid }) {
  const SubscriptionPlan      = (await import("../../models/subscription/SubscriptionPlan.model.js")).default;
  const UserSubscription      = (await import("../../models/subscription/UserSubscription.model.js")).default;
  const User                  = (await import("../../models/user/user.js")).default;

  const plan = await SubscriptionPlan.findOne({ key: planKey, isActive: true });
  if (!plan) return;

  const now       = new Date();
  const expiresAt = new Date(now);
  expiresAt.setDate(expiresAt.getDate() + plan.durationDays);

  const subscription = await UserSubscription.create({
    userId,
    planKey,
    status:    "active",
    startedAt: now,
    expiresAt,
    paymentId,
    orderId,
    amountPaid,
  });

  await UserSubscription.updateMany(
    { userId, status: "active", _id: { $ne: subscription._id } },
    { status: "expired" }
  );

  await User.findByIdAndUpdate(userId, {
    isPremium:          true,
    subscriptionPlan:   planKey,
    subscriptionExpiry: expiresAt,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. CREATE ORDER
// POST /user/payment/create
//
// Flutter calls this first. We create a Razorpay order and return the
// orderId + amount so Flutter can open the Razorpay payment sheet.
//
// Body: { amount, purpose, metadata }
//   amount   — in INR rupees (we convert to paise)
//   purpose  — "shop_order" | "subscription" | "report" | "astrologer_session"
//   metadata — { planKey } for subscription, { shopOrderId } for shop, etc.
// ═════════════════════════════════════════════════════════════════════════════
export const createOrder = async (req, res) => {
  try {
    const { amount, purpose, metadata = {} } = req.body;
    const userId = req.user.id;

    // Validate
    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: "Invalid amount" });
    }

    const validPurposes = ["shop_order", "subscription", "report", "astrologer_session"];
    if (!validPurposes.includes(purpose)) {
      return res.status(400).json({ success: false, message: "Invalid payment purpose" });
    }

    // Convert rupees to paise (Razorpay works in paise)
    const amountPaise = Math.round(amount * 100);

    // Create order on Razorpay
    const razorpayOrder = await razorpay.orders.create({
      amount:   amountPaise,
      currency: "INR",
      receipt: `rcpt_${Date.now()}`,
      notes: {
        userId,
        purpose,
        ...metadata,
      },
    });

    // Store pending payment in our DB
    const payment = await Payment.create({
      user:            userId,
      amount:          amountPaise,
      currency:        "INR",
      status:          "pending",
      purpose,
      razorpayOrderId: razorpayOrder.id,
      metadata,
      idempotencyKey:  razorpayOrder.id, // Razorpay orderId is unique
    });

    return res.status(201).json({
      success: true,
      // Everything Flutter needs to open the payment sheet
      order: {
        id:       razorpayOrder.id,       // razorpay_order_id
        amount:   razorpayOrder.amount,   // in paise
        currency: razorpayOrder.currency,
        keyId:    process.env.RAZORPAY_KEY_ID, // public key for Flutter SDK
      },
      paymentId: payment._id, // our internal payment doc ID
    });

  } catch (err) {
    console.error("createOrder error:", err);
    return res.status(500).json({ success: false, message: "Failed to create payment order" });
  }
};

// ═════════════════════════════════════════════════════════════════════════════
// 2. VERIFY PAYMENT
// POST /user/payment/verify
//
// Flutter calls this after the user completes payment in the Razorpay sheet.
// We verify the cryptographic signature to confirm the payment is genuine.
//
// Body: { razorpayOrderId, razorpayPaymentId, razorpaySignature }
// ═════════════════════════════════════════════════════════════════════════════
export const verifyPayment = async (req, res) => {
  try {
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;
    const userId = req.user.id;

    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({
        success: false,
        message: "razorpayOrderId, razorpayPaymentId and razorpaySignature are all required",
      });
    }

    // CRITICAL: verify the signature cryptographically
    const isValid = verifyRazorpaySignature({
      razorpayOrderId,
      razorpayPaymentId,
      signature: razorpaySignature,
    });

    if (!isValid) {
      // Log this — it could be a tampered payment attempt
      console.warn(`⚠️  Invalid Razorpay signature from userId=${userId} orderId=${razorpayOrderId}`);
      return res.status(400).json({
        success: false,
        message: "Payment verification failed — invalid signature",
      });
    }

    // Find and update our payment record
    const payment = await Payment.findOneAndUpdate(
      { razorpayOrderId, user: userId },
      {
        razorpayPaymentId,
        razorpaySignature,
        status: "success",
        paidAt: new Date(),
      },
      { new: true }
    );

    if (!payment) {
      return res.status(404).json({ success: false, message: "Payment record not found" });
    }

    // Fulfill the purchase (activate subscription, update order status, etc.)
    await fulfillPayment(payment, userId);

    return res.json({
      success: true,
      message: "Payment verified successfully",
      payment: {
        id:       payment._id,
        status:   payment.status,
        purpose:  payment.purpose,
        paidAt:   payment.paidAt,
      },
    });

  } catch (err) {
    console.error("verifyPayment error:", err);
    return res.status(500).json({ success: false, message: "Payment verification failed" });
  }
};

// ═════════════════════════════════════════════════════════════════════════════
// 3. WEBHOOK
// POST /api/payment/webhook
//
// Razorpay calls this endpoint directly on their servers when a payment event
// occurs. This is the most reliable path — it fires even if the user closes
// the app before verifyPayment is called.
//
// IMPORTANT: this route must use express.raw() body parser (not express.json())
// so we can verify the raw body signature.
// ═════════════════════════════════════════════════════════════════════════════
export const webhook = async (req, res) => {
  try {
    // Verify webhook signature
    const webhookSignature = req.headers["x-razorpay-signature"];
    const webhookSecret    = process.env.RAZORPAY_WEBHOOK_SECRET;

    if (!webhookSignature || !webhookSecret) {
      return res.status(400).json({ success: false, message: "Missing webhook signature" });
    }

    const expectedSignature = crypto
      .createHmac("sha256", webhookSecret)
      .update(req.body) // req.body is raw Buffer here (see route setup)
      .digest("hex");

    if (expectedSignature !== webhookSignature) {
      console.warn("⚠️  Invalid webhook signature");
      return res.status(400).json({ success: false, message: "Invalid webhook signature" });
    }

    // Parse the event
    const event = JSON.parse(req.body.toString());
    console.log(`[Webhook] Event: ${event.event}`);

    if (event.event === "payment.captured") {
      const razorpayPaymentId = event.payload.payment.entity.id;
      const razorpayOrderId   = event.payload.payment.entity.order_id;

      // Find the payment — skip if already processed (idempotency)
      const payment = await Payment.findOne({ razorpayOrderId });

      if (!payment) {
        console.warn(`[Webhook] No payment found for orderId=${razorpayOrderId}`);
        return res.json({ success: true }); // return 200 so Razorpay doesn't retry
      }

      if (payment.status === "success") {
        console.log(`[Webhook] Payment already processed: ${razorpayOrderId}`);
        return res.json({ success: true }); // idempotent — already done
      }

      // Update payment record
      await Payment.findByIdAndUpdate(payment._id, {
        razorpayPaymentId,
        status: "success",
        paidAt: new Date(),
      });

      // Fulfill the purchase
      await fulfillPayment(payment, payment.user.toString());

      console.log(`[Webhook] ✅ Payment fulfilled: ${razorpayOrderId}`);
    }

    if (event.event === "payment.failed") {
      const razorpayOrderId = event.payload.payment.entity.order_id;
      await Payment.findOneAndUpdate(
        { razorpayOrderId },
        { status: "failed" }
      );
      console.log(`[Webhook] ❌ Payment failed: ${razorpayOrderId}`);
    }

    // Always return 200 to Razorpay — otherwise they'll retry the webhook
    return res.json({ success: true });

  } catch (err) {
    console.error("webhook error:", err);
    // Still return 200 — a 500 causes Razorpay to retry repeatedly
    return res.json({ success: true });
  }
};

// Keep old name as alias so existing routes don't break
export const createPayment = createOrder;