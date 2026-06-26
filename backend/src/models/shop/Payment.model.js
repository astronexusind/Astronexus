// backend/src/models/shop/Payment.model.js
// CHANGES: Added razorpayOrderId, razorpayPaymentId, razorpaySignature,
//          purpose field (shop/subscription/astrologer), idempotencyKey
import mongoose from "mongoose";

const paymentSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    order: { type: mongoose.Schema.Types.ObjectId, ref: "Order" },

    // Amount in paise (₹1 = 100 paise) — Razorpay always works in paise
    amount: { type: Number, required: true },

    currency: { type: String, default: "INR" },

    method: {
      type: String,
      enum: ["UPI", "Card", "NetBanking", "Wallet", "CASH"],
      default: "UPI",
    },

    status: {
      type: String,
      enum: ["pending", "success", "failed", "refunded"],
      default: "pending",
    },

    // What this payment is for
    purpose: {
      type: String,
      enum: ["shop_order", "subscription", "astrologer_session", "report"],
      required: true,
    },

    // Razorpay specific fields
    razorpayOrderId:   { type: String, unique: true, sparse: true }, // from createOrder
    razorpayPaymentId: { type: String, unique: true, sparse: true }, // from client after payment
    razorpaySignature: { type: String },                             // verified server-side

    // Legacy field kept for backward compatibility
    transactionId: { type: String },

    // Prevents duplicate processing if webhook fires twice
    idempotencyKey: { type: String, unique: true, sparse: true },

    // Reference to what was purchased (planKey for subscriptions)
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },

    // When Razorpay confirmed the payment
    paidAt: { type: Date },
  },
  { timestamps: true }
);

export default mongoose.model("Payment", paymentSchema);