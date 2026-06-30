// backend/src/models/astrologer/Astrologer.model.js
import mongoose from "mongoose";

/**
 * Astrologer profile — created and managed by admin.
 * Each astrologer has their own login credentials so they can
 * manage their availability themselves (future feature).
 */
const astrologerSchema = new mongoose.Schema(
  {
    // ── Identity ────────────────────────────────────────────────────────────
    name:        { type: String, required: true, trim: true },
    email:       { type: String, required: true, unique: true, lowercase: true },
    phone:       { type: String, required: true },
    profileImage:{ type: String, default: "" }, // Cloudinary/S3 URL

    // ── Professional details ────────────────────────────────────────────────
    specialties: [{
      type: String,
      enum: ["Vedic", "Tarot", "Numerology", "Vastu", "Marriage", "Career",
             "Health", "Finance", "KP", "Nadi", "Palmistry", "Prashna"],
    }],
    languages:   [{ type: String }], // ["Hindi", "English", "Marathi"]
    experience:  { type: Number, default: 0 },  // years
    bio:         { type: String, default: "" },  // short description shown in card
    about:       { type: String, default: "" },  // detailed bio shown on profile page

    // ── Pricing (in INR per minute) ─────────────────────────────────────────
    pricing: {
      chat:  { type: Number, default: 30 },  // ₹/min for text chat
      call:  { type: Number, default: 50 },  // ₹/min for voice call
      video: { type: Number, default: 80 },  // ₹/min for video call
    },

    // ── Ratings & stats ─────────────────────────────────────────────────────
    rating:       { type: Number, default: 0, min: 0, max: 5 },
    totalReviews: { type: Number, default: 0 },
    totalSessions:{ type: Number, default: 0 },

    // ── Availability ────────────────────────────────────────────────────────
    isOnline:     { type: Boolean, default: false, index: true },
    isAvailable:  { type: Boolean, default: true },  // admin can disable
    isVerified:   { type: Boolean, default: false },  // admin verified credentials

    // ── Status ──────────────────────────────────────────────────────────────
    isActive: { type: Boolean, default: true, index: true },

    // ── Commission ──────────────────────────────────────────────────────────
    // AstroNexus takes this % of each session payment
    commissionPercent: { type: Number, default: 25 },

    // ── Agora video SDK ─────────────────────────────────────────────────────
    // Astrologer's Agora UID — assigned when they register
    agoraUid: { type: Number, unique: true, sparse: true },
  },
  { timestamps: true }
);

// Text search index for finding astrologers by name/specialty
astrologerSchema.index({ name: "text", bio: "text" });

export default mongoose.model("Astrologer", astrologerSchema);