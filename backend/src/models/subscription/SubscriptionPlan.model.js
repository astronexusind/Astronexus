// backend/src/models/subscription/SubscriptionPlan.model.js
import mongoose from "mongoose";

/**
 * Defines the available subscription plans.
 * Seeded once via admin or a seed script — not created per-user.
 * Matches exactly the 3 plans shown in the Flutter subscription screen.
 */
const subscriptionPlanSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      enum: ["weekly", "monthly", "yearly"],
    },
    name: { type: String, required: true },       // "Weekly", "Monthly", "Yearly"
    price: { type: Number, required: true },       // in INR paise (₹199 = 19900)
    displayPrice: { type: String, required: true },// "₹199" — shown in UI
    durationDays: { type: Number, required: true },// 7, 30, 365
    features: [{ type: String }],                 // feature list shown in UI
    isActive: { type: Boolean, default: true },   // admin can disable a plan
    razorpayPlanId: { type: String, default: "" },// filled after Razorpay setup
  },
  { timestamps: true }
);

export default mongoose.model("SubscriptionPlan", subscriptionPlanSchema);