// backend/src/models/astrologer/Booking.model.js
import mongoose from "mongoose";

/**
 * One document per session booking between a user and an astrologer.
 * Tracks the full lifecycle: pending → confirmed → in_progress → completed/cancelled
 */
const bookingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    astrologerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Astrologer",
      required: true,
      index: true,
    },

    // ── Session type ─────────────────────────────────────────────────────────
    sessionType: {
      type: String,
      enum: ["chat", "call", "video"],
      required: true,
    },

    // ── Lifecycle status ─────────────────────────────────────────────────────
    status: {
      type: String,
      enum: [
        "pending",      // user requested, awaiting astrologer confirmation
        "confirmed",    // astrologer confirmed, session about to start
        "in_progress",  // session currently running
        "completed",    // session ended normally
        "cancelled",    // cancelled by user or astrologer
        "no_show",      // astrologer didn't show up
      ],
      default: "pending",
      index: true,
    },

    // ── Timing ───────────────────────────────────────────────────────────────
    scheduledAt:  { type: Date },               // null = "now" (instant booking)
    startedAt:    { type: Date },               // when session actually started
    endedAt:      { type: Date },               // when session ended
    durationMinutes: { type: Number, default: 0 }, // actual duration (calculated on end)

    // ── Pricing snapshot (locked at booking time, not changed if astrologer updates price) ──
    ratePerMinute: { type: Number, required: true }, // INR per minute
    totalAmount:   { type: Number, default: 0 },     // calculated on session end
    platformFee:   { type: Number, default: 0 },     // AstroNexus commission
    astrologerPayout: { type: Number, default: 0 },  // what astrologer receives

    // ── Payment ──────────────────────────────────────────────────────────────
    paymentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Payment",
    },
    paymentStatus: {
      type: String,
      enum: ["pending", "held", "released", "refunded"],
      default: "pending",
    },

    // ── Video/Call session details ────────────────────────────────────────────
    // Agora channel name — unique per booking, used by both Flutter and astrologer app
    agoraChannel: { type: String, unique: true, sparse: true },
    agoraToken:   { type: String },              // generated on session start, expires

    // ── Notes ────────────────────────────────────────────────────────────────
    userNote:      { type: String, default: "" }, // user's question/context before session
    cancelReason:  { type: String, default: "" },

    // ── Review ───────────────────────────────────────────────────────────────
    review: {
      rating:    { type: Number, min: 1, max: 5 },
      comment:   { type: String, default: "" },
      createdAt: { type: Date },
    },
  },
  { timestamps: true }
);

// Compound index: fast lookup for "user's upcoming bookings"
bookingSchema.index({ userId: 1, status: 1, scheduledAt: 1 });
// Compound index: fast lookup for "astrologer's active sessions"
bookingSchema.index({ astrologerId: 1, status: 1 });

export default mongoose.model("Booking", bookingSchema);