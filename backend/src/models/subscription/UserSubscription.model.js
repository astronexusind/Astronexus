// backend/src/models/subscription/UserSubscription.model.js
import mongoose from "mongoose";

/**
 * One document per user subscription purchase.
 * A user can have multiple records over time (history).
 * The ACTIVE subscription is the one where status="active" and expiresAt > now.
 */
const userSubscriptionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    planKey: {
      type: String,
      required: true,
      enum: ["weekly", "monthly", "yearly"],
    },
    status: {
      type: String,
      enum: ["active", "expired", "cancelled", "pending"],
      default: "pending",
    },
    startedAt:  { type: Date },
    expiresAt:  { type: Date, index: true },  // indexed for fast expiry queries

    // Payment reference — filled after Razorpay verification
    paymentId:  { type: String, default: "" },
    orderId:    { type: String, default: "" },
    amountPaid: { type: Number, default: 0 }, // in INR paise

    // Auto-renewal (future use)
    autoRenew:  { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Compound index: fast lookup for "is this user currently subscribed?"
userSubscriptionSchema.index({ userId: 1, status: 1, expiresAt: 1 });

export default mongoose.model("UserSubscription", userSubscriptionSchema);