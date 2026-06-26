// backend/src/models/user/user.js
// CHANGES from original:
//   Added subscriptionPlan, subscriptionExpiry, isPremium fields
//   Everything else is identical to the original
import mongoose from "mongoose";
import crypto from "crypto";

const astrologySchema = new mongoose.Schema({
  dateOfBirth: { type: Date },
  timeOfBirth: { type: String },
  placeOfBirth: { type: String }
}, { _id: false });

const userSchema = new mongoose.Schema(
  {
    name:     { type: String, required: true },
    phone:    { type: String, required: true, unique: true },
    password: { type: String, required: true, select: false },
    email:    { type: String, unique: true, sparse: true },

    // Permanent session ID for astrology conversations
    sessionId: {
      type: String,
      unique: true,
      index: true,
      default: () => crypto.randomBytes(16).toString("hex"),
    },

    profileImage: {
      url:      String,
      publicId: String,
    },

    astrologyProfile: astrologySchema,

    chatInitialized: { type: Boolean, default: false },

    role: {
      type:    String,
      enum:    ["user", "admin"],
      default: "user",
    },

    isBlocked: { type: Boolean, default: false },

    lastLoginAt: Date,

    // ── SUBSCRIPTION FIELDS (new) ──────────────────────────────────────────
    /**
     * isPremium: denormalized flag for fast middleware checks.
     * Set to true when a subscription is activated, false when it expires.
     * Source of truth is UserSubscription collection — this is a cache.
     */
    isPremium: {
      type:    Boolean,
      default: false,
      index:   true,
    },

    /**
     * Which plan the user is currently on.
     * null = free tier.
     */
    subscriptionPlan: {
      type:    String,
      enum:    ["weekly", "monthly", "yearly", null],
      default: null,
    },

    /**
     * When the current subscription expires.
     * Middleware compares this against Date.now() on every request.
     * null = no active subscription.
     */
    subscriptionExpiry: {
      type:    Date,
      default: null,
      index:   true,
    },
  },
  { timestamps: true }
);

// ── Virtual: isSubscriptionActive ──────────────────────────────────────────
// Use this in controllers to check if the subscription is actually still valid.
// Handles the edge case where isPremium=true but expiry has passed
// (e.g. if the cron job/renewal hasn't run yet).
userSchema.virtual("isSubscriptionActive").get(function () {
  return (
    this.isPremium === true &&
    this.subscriptionExpiry !== null &&
    this.subscriptionExpiry > new Date()
  );
});

const User = mongoose.models.User || mongoose.model("User", userSchema);
export default User;