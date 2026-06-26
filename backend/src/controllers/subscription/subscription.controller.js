// backend/src/controllers/subscription/subscription.controller.js
import SubscriptionPlan from "../../models/subscription/SubscriptionPlan.model.js";
import UserSubscription from "../../models/subscription/UserSubscription.model.js";
import User from "../../models/user/user.js";

/**
 * GET /api/subscription/plans
 * Public — returns all active plans for the Flutter subscription screen.
 */
export const getPlans = async (req, res) => {
  try {
    const plans = await SubscriptionPlan.find({ isActive: true }).sort({ price: 1 });
    return res.json({ success: true, plans });
  } catch (err) {
    console.error("getPlans error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch plans" });
  }
};

/**
 * GET /api/subscription/status
 * Protected — returns the current user's subscription status.
 * Called by Flutter on app start to decide which features to show.
 */
export const getStatus = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select(
      "isPremium subscriptionPlan subscriptionExpiry"
    );

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const isActive =
      user.isPremium &&
      user.subscriptionExpiry &&
      user.subscriptionExpiry > new Date();

    // If subscription has lapsed but isPremium is still true, fix it
    if (user.isPremium && !isActive) {
      await User.findByIdAndUpdate(req.user.id, {
        isPremium:          false,
        subscriptionPlan:   null,
        subscriptionExpiry: null,
      });
    }

    return res.json({
      success: true,
      subscription: {
        isActive,
        plan:      isActive ? user.subscriptionPlan : null,
        expiresAt: isActive ? user.subscriptionExpiry : null,
      },
    });
  } catch (err) {
    console.error("getStatus error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch status" });
  }
};

/**
 * POST /api/subscription/activate
 * Protected — activates a subscription after successful payment.
 * Called AFTER Razorpay payment is verified (will be wired to payment webhook later).
 *
 * Body: { planKey, paymentId, orderId, amountPaid }
 *
 * NOTE: In production this will be called by the Razorpay webhook handler,
 * not directly by the client. For now it accepts direct calls for testing.
 */
export const activateSubscription = async (req, res) => {
  try {
    const { planKey, paymentId, orderId, amountPaid } = req.body;
    const userId = req.user.id;

    // Validate plan
    const plan = await SubscriptionPlan.findOne({ key: planKey, isActive: true });
    if (!plan) {
      return res.status(400).json({ success: false, message: "Invalid or inactive plan" });
    }

    const now       = new Date();
    const expiresAt = new Date(now);
    expiresAt.setDate(expiresAt.getDate() + plan.durationDays);

    // Create subscription record
    const subscription = await UserSubscription.create({
      userId,
      planKey,
      status:     "active",
      startedAt:  now,
      expiresAt,
      paymentId:  paymentId  || "",
      orderId:    orderId    || "",
      amountPaid: amountPaid || plan.price,
    });

    // Expire any previously active subscriptions for this user
    await UserSubscription.updateMany(
      { userId, status: "active", _id: { $ne: subscription._id } },
      { status: "expired" }
    );

    // Update User model (denormalized cache for fast middleware checks)
    await User.findByIdAndUpdate(userId, {
      isPremium:          true,
      subscriptionPlan:   planKey,
      subscriptionExpiry: expiresAt,
    });

    return res.json({
      success: true,
      message: `${plan.name} subscription activated successfully`,
      subscription: {
        plan:      planKey,
        expiresAt,
        startedAt: now,
      },
    });
  } catch (err) {
    console.error("activateSubscription error:", err);
    return res.status(500).json({ success: false, message: "Failed to activate subscription" });
  }
};

/**
 * POST /api/subscription/cancel
 * Protected — cancels the user's active subscription.
 * Does not issue refunds (handle refunds separately via Razorpay dashboard).
 */
export const cancelSubscription = async (req, res) => {
  try {
    const userId = req.user.id;

    await UserSubscription.updateMany(
      { userId, status: "active" },
      { status: "cancelled" }
    );

    await User.findByIdAndUpdate(userId, {
      isPremium:          false,
      subscriptionPlan:   null,
      subscriptionExpiry: null,
    });

    return res.json({
      success: true,
      message: "Subscription cancelled. Access continues until the end of your billing period.",
    });
  } catch (err) {
    console.error("cancelSubscription error:", err);
    return res.status(500).json({ success: false, message: "Failed to cancel subscription" });
  }
};

// ── ADMIN CONTROLLERS ──────────────────────────────────────────────────────

/**
 * POST /api/admin/subscription/seed-plans
 * Admin only — seeds the 3 subscription plans into the database.
 * Run once after first deployment.
 */
export const seedPlans = async (req, res) => {
  try {
    const plans = [
      {
        key:          "weekly",
        name:         "Weekly",
        price:        19900,       // ₹199 in paise
        displayPrice: "₹199",
        durationDays: 7,
        features:     ["Daily Horoscope", "Basic Insights", "Priority reminders"],
        isActive:     true,
      },
      {
        key:          "monthly",
        name:         "Monthly",
        price:        69900,       // ₹699 in paise
        displayPrice: "₹699",
        durationDays: 30,
        features:     ["Daily Horoscope", "Nutritional Astrology", "Exclusive Videos", "Chat Support"],
        isActive:     true,
      },
      {
        key:          "yearly",
        name:         "Yearly",
        price:        699900,      // ₹6,999 in paise
        displayPrice: "₹6,999",
        durationDays: 365,
        features:     ["All Monthly Features", "Priority Astrologer Support", "Premium Content"],
        isActive:     true,
      },
    ];

    const results = [];
    for (const plan of plans) {
      const result = await SubscriptionPlan.findOneAndUpdate(
        { key: plan.key },
        plan,
        { upsert: true, new: true }
      );
      results.push(result);
    }

    return res.json({ success: true, message: "Plans seeded successfully", plans: results });
  } catch (err) {
    console.error("seedPlans error:", err);
    return res.status(500).json({ success: false, message: "Failed to seed plans" });
  }
};

/**
 * GET /api/admin/subscription/all
 * Admin only — get all user subscriptions with user details.
 */
export const getAllSubscriptions = async (req, res) => {
  try {
    const subscriptions = await UserSubscription.find()
      .populate("userId", "name email phone")
      .sort({ createdAt: -1 })
      .limit(100);

    return res.json({ success: true, subscriptions });
  } catch (err) {
    console.error("getAllSubscriptions error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch subscriptions" });
  }
};