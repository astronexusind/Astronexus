// backend/src/controllers/astrologer/astrologer.controller.js
import crypto from "crypto";
import Astrologer from "../../models/astrologer/Astrologer.model.js";
import Booking from "../../models/astrologer/Booking.model.js";
import Payment from "../../models/shop/Payment.model.js";
import User from "../../models/user/user.js";
import { generateAgoraRtcToken, mongoIdToAgoraUid } from "../../config/agora.js";

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: generate a unique Agora channel name for a booking
// ─────────────────────────────────────────────────────────────────────────────
function generateAgoraChannel(bookingId) {
  return `astronexus_${bookingId}_${crypto.randomBytes(4).toString("hex")}`;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: calculate session financials
// ─────────────────────────────────────────────────────────────────────────────
function calculateFinancials(durationMinutes, ratePerMinute, commissionPercent) {
  const totalAmount      = Math.round(durationMinutes * ratePerMinute);
  const platformFee      = Math.round(totalAmount * commissionPercent / 100);
  const astrologerPayout = totalAmount - platformFee;
  return { totalAmount, platformFee, astrologerPayout };
}

// ═════════════════════════════════════════════════════════════════════════════
// USER-FACING CONTROLLERS
// ═════════════════════════════════════════════════════════════════════════════

/**
 * GET /api/astrologer/list
 * Public — list all active, verified astrologers.
 * Supports filtering by specialty, session type, and online status.
 *
 * Query params:
 *   specialty — "Tarot" | "Vedic" | "Numerology" etc.
 *   type      — "chat" | "call" | "video"
 *   online    — "true" to show only online astrologers
 *   page      — pagination (default 1)
 *   limit     — items per page (default 20)
 */
export const listAstrologers = async (req, res) => {
  try {
    const { specialty, type, online, page = 1, limit = 20 } = req.query;

    const filter = { isActive: true, isVerified: true };

    if (specialty) filter.specialties = specialty;
    if (online === "true") filter.isOnline = true;

    const skip = (Number(page) - 1) * Number(limit);

    const [astrologers, total] = await Promise.all([
      Astrologer.find(filter)
        .select("name profileImage specialties languages experience bio pricing rating totalReviews totalSessions isOnline")
        .sort({ isOnline: -1, rating: -1 }) // online first, then by rating
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      Astrologer.countDocuments(filter),
    ]);

    return res.json({
      success: true,
      astrologers,
      pagination: {
        total,
        page:       Number(page),
        limit:      Number(limit),
        totalPages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (err) {
    console.error("listAstrologers error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch astrologers" });
  }
};

/**
 * GET /api/astrologer/:id
 * Public — get full astrologer profile
 */
export const getAstrologer = async (req, res) => {
  try {
    const astrologer = await Astrologer.findById(req.params.id)
      .select("-email -phone -commissionPercent -agoraUid")
      .lean();

    if (!astrologer || !astrologer.isActive) {
      return res.status(404).json({ success: false, message: "Astrologer not found" });
    }

    return res.json({ success: true, astrologer });
  } catch (err) {
    console.error("getAstrologer error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch astrologer" });
  }
};

/**
 * POST /api/astrologer/book
 * Protected — book a session with an astrologer.
 *
 * Body:
 * {
 *   astrologerId: string
 *   sessionType:  "chat" | "call" | "video"
 *   scheduledAt:  ISO date string | null (null = instant booking)
 *   userNote:     string (optional)
 *   durationMinutes: number (for pre-paid bookings, e.g. 15/30/45/60)
 * }
 */
export const bookSession = async (req, res) => {
  try {
    const { astrologerId, sessionType, scheduledAt, userNote, durationMinutes = 30 } = req.body;
    const userId = req.user.id;

    // Validate session type
    if (!["chat", "call", "video"].includes(sessionType)) {
      return res.status(400).json({ success: false, message: "Invalid session type" });
    }

    // Validate duration
    if (![15, 30, 45, 60].includes(Number(durationMinutes))) {
      return res.status(400).json({
        success: false,
        message: "Duration must be 15, 30, 45, or 60 minutes",
      });
    }

    // Find astrologer
    const astrologer = await Astrologer.findById(astrologerId);
    if (!astrologer || !astrologer.isActive || !astrologer.isVerified) {
      return res.status(404).json({ success: false, message: "Astrologer not found" });
    }

    // Check availability for instant bookings
    if (!scheduledAt && !astrologer.isOnline) {
      return res.status(400).json({
        success: false,
        message: `${astrologer.name} is currently offline. Please schedule a session or try another astrologer.`,
      });
    }

    // Check for conflicting active bookings for this user
    const activeBooking = await Booking.findOne({
      userId,
      status: { $in: ["pending", "confirmed", "in_progress"] },
    });

    if (activeBooking) {
      return res.status(400).json({
        success: false,
        message: "You already have an active session. Please complete it before booking another.",
      });
    }

    // Get rate for session type
    const ratePerMinute = astrologer.pricing[sessionType];

    // Calculate total amount (pre-auth amount)
    const totalAmount = Math.round(Number(durationMinutes) * ratePerMinute);

    // Create the booking
    const booking = await Booking.create({
      userId,
      astrologerId,
      sessionType,
      scheduledAt:     scheduledAt ? new Date(scheduledAt) : null,
      ratePerMinute,
      userNote:        userNote || "",
      status:          "pending",
    });

    return res.status(201).json({
      success: true,
      message: "Session booked successfully",
      booking: {
        id:              booking._id,
        astrologerName:  astrologer.name,
        sessionType,
        scheduledAt:     booking.scheduledAt,
        ratePerMinute,
        estimatedAmount: totalAmount,
        durationMinutes: Number(durationMinutes),
        status:          "pending",
      },
      // Payment info for Flutter to initiate Razorpay
      payment: {
        amount:    totalAmount,
        purpose:   "astrologer_session",
        metadata:  { bookingId: booking._id.toString(), astrologerId },
      },
    });
  } catch (err) {
    console.error("bookSession error:", err);
    return res.status(500).json({ success: false, message: "Failed to book session" });
  }
};

/**
 * POST /api/astrologer/session/start/:bookingId
 * Protected — start a confirmed session and get Agora token.
 * Called when user taps "Join Call" in Flutter.
 */
export const startSession = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.id;

    const booking = await Booking.findById(bookingId)
      .populate("astrologerId", "name pricing isOnline agoraUid");

    if (!booking) {
      return res.status(404).json({ success: false, message: "Booking not found" });
    }

    if (booking.userId.toString() !== userId) {
      return res.status(403).json({ success: false, message: "Not your booking" });
    }

    if (!["pending", "confirmed"].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot start session in ${booking.status} status`,
      });
    }

    // Generate Agora channel
    const agoraChannel = generateAgoraChannel(bookingId);

    // The user always joins as the "publisher" role (they send + receive
    // audio/video). uid is derived deterministically from their own userId
    // so we don't need to persist it — the client is told the same uid here
    // and must join with it exactly, or the token will be rejected.
    const agoraUid = mongoIdToAgoraUid(userId);
    const agoraToken = generateAgoraRtcToken(agoraChannel, agoraUid, "publisher");

    // Update booking
    await Booking.findByIdAndUpdate(bookingId, {
      status:       "in_progress",
      startedAt:    new Date(),
      agoraChannel,
      agoraToken,
    });

    return res.json({
      success: true,
      session: {
        bookingId,
        agoraChannel,
        agoraToken,
        agoraUid,
        astrologerName: booking.astrologerId.name,
        sessionType:    booking.sessionType,
        ratePerMinute:  booking.ratePerMinute,
        startedAt:      new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error("startSession error:", err);
    return res.status(500).json({ success: false, message: "Failed to start session" });
  }
};

/**
 * POST /api/astrologer/session/end/:bookingId
 * Protected — end a session, calculate bill, trigger payment.
 * Called when user or astrologer ends the call.
 */
export const endSession = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userId = req.user.id;

    const booking = await Booking.findById(bookingId)
      .populate("astrologerId", "name commissionPercent");

    if (!booking) {
      return res.status(404).json({ success: false, message: "Booking not found" });
    }

    if (booking.userId.toString() !== userId) {
      return res.status(403).json({ success: false, message: "Not your booking" });
    }

    if (booking.status !== "in_progress") {
      return res.status(400).json({
        success: false,
        message: "Session is not in progress",
      });
    }

    const endedAt         = new Date();
    const startedAt       = booking.startedAt || endedAt;
    const durationMs      = endedAt - startedAt;
    const durationMinutes = Math.max(1, Math.ceil(durationMs / (1000 * 60))); // minimum 1 minute

    const { totalAmount, platformFee, astrologerPayout } = calculateFinancials(
      durationMinutes,
      booking.ratePerMinute,
      booking.astrologerId.commissionPercent
    );

    // Update booking with final details
    await Booking.findByIdAndUpdate(bookingId, {
      status:           "completed",
      endedAt,
      durationMinutes,
      totalAmount,
      platformFee,
      astrologerPayout,
    });

    // Update astrologer stats
    await Astrologer.findByIdAndUpdate(booking.astrologerId._id, {
      $inc: { totalSessions: 1 },
    });

    return res.json({
      success: true,
      message: "Session ended successfully",
      summary: {
        bookingId,
        durationMinutes,
        totalAmount,
        platformFee,
        astrologerPayout,
        astrologerName: booking.astrologerId.name,
      },
    });
  } catch (err) {
    console.error("endSession error:", err);
    return res.status(500).json({ success: false, message: "Failed to end session" });
  }
};

/**
 * POST /api/astrologer/session/cancel/:bookingId
 * Protected — cancel a pending or confirmed booking.
 */
export const cancelBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { reason }    = req.body;
    const userId        = req.user.id;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: "Booking not found" });
    }

    if (booking.userId.toString() !== userId) {
      return res.status(403).json({ success: false, message: "Not your booking" });
    }

    if (!["pending", "confirmed"].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel a ${booking.status} session`,
      });
    }

    await Booking.findByIdAndUpdate(bookingId, {
      status:       "cancelled",
      cancelReason: reason || "Cancelled by user",
    });

    return res.json({ success: true, message: "Booking cancelled successfully" });
  } catch (err) {
    console.error("cancelBooking error:", err);
    return res.status(500).json({ success: false, message: "Failed to cancel booking" });
  }
};

/**
 * POST /api/astrologer/session/:bookingId/review
 * Protected — submit a review after a completed session.
 */
export const submitReview = async (req, res) => {
  try {
    const { bookingId }    = req.params;
    const { rating, comment } = req.body;
    const userId = req.user.id;

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({ success: false, message: "Rating must be between 1 and 5" });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: "Booking not found" });
    }

    if (booking.userId.toString() !== userId) {
      return res.status(403).json({ success: false, message: "Not your booking" });
    }

    if (booking.status !== "completed") {
      return res.status(400).json({
        success: false,
        message: "Can only review completed sessions",
      });
    }

    if (booking.review?.rating) {
      return res.status(400).json({ success: false, message: "You have already reviewed this session" });
    }

    // Save review on booking
    await Booking.findByIdAndUpdate(bookingId, {
      review: { rating, comment: comment || "", createdAt: new Date() },
    });

    // Update astrologer's average rating
    const astrologer = await Astrologer.findById(booking.astrologerId);
    const newTotal   = astrologer.totalReviews + 1;
    const newRating  = ((astrologer.rating * astrologer.totalReviews) + rating) / newTotal;

    await Astrologer.findByIdAndUpdate(booking.astrologerId, {
      rating:       Math.round(newRating * 10) / 10, // rounded to 1 decimal
      totalReviews: newTotal,
    });

    return res.json({ success: true, message: "Review submitted. Thank you!" });
  } catch (err) {
    console.error("submitReview error:", err);
    return res.status(500).json({ success: false, message: "Failed to submit review" });
  }
};

/**
 * GET /api/astrologer/my-bookings
 * Protected — get current user's booking history.
 */
export const getMyBookings = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 10 } = req.query;

    const filter = { userId };
    if (status) filter.status = status;

    const skip = (Number(page) - 1) * Number(limit);

    const [bookings, total] = await Promise.all([
      Booking.find(filter)
        .populate("astrologerId", "name profileImage specialties rating")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .lean(),
      Booking.countDocuments(filter),
    ]);

    return res.json({
      success: true,
      bookings,
      pagination: {
        total,
        page:       Number(page),
        totalPages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (err) {
    console.error("getMyBookings error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch bookings" });
  }
};

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN CONTROLLERS
// ═════════════════════════════════════════════════════════════════════════════

/**
 * POST /api/admin/astrologer/create
 * Admin only — onboard a new astrologer.
 */
export const createAstrologer = async (req, res) => {
  try {
    const {
      name, email, phone, specialties, languages, experience,
      bio, about, pricing, commissionPercent,
    } = req.body;

    if (!name || !email || !phone) {
      return res.status(400).json({ success: false, message: "name, email, phone are required" });
    }

    const existing = await Astrologer.findOne({ email });
    if (existing) {
      return res.status(400).json({ success: false, message: "Astrologer with this email already exists" });
    }

    const astrologer = await Astrologer.create({
      name, email, phone,
      specialties:       specialties || [],
      languages:         languages   || ["Hindi", "English"],
      experience:        experience  || 0,
      bio:               bio         || "",
      about:             about       || "",
      pricing:           pricing     || { chat: 30, call: 50, video: 80 },
      commissionPercent: commissionPercent || 25,
      isVerified:        false,
      isActive:          true,
    });

    return res.status(201).json({
      success: true,
      message: "Astrologer created successfully. Set isVerified=true once credentials are verified.",
      astrologer,
    });
  } catch (err) {
    console.error("createAstrologer error:", err);
    return res.status(500).json({ success: false, message: "Failed to create astrologer" });
  }
};

/**
 * PATCH /api/admin/astrologer/:id/verify
 * Admin only — verify an astrologer's credentials.
 */
export const verifyAstrologer = async (req, res) => {
  try {
    const astrologer = await Astrologer.findByIdAndUpdate(
      req.params.id,
      { isVerified: true },
      { new: true }
    ).select("name email isVerified");

    if (!astrologer) {
      return res.status(404).json({ success: false, message: "Astrologer not found" });
    }

    return res.json({
      success: true,
      message: `${astrologer.name} is now verified and will appear in listings.`,
      astrologer,
    });
  } catch (err) {
    console.error("verifyAstrologer error:", err);
    return res.status(500).json({ success: false, message: "Failed to verify astrologer" });
  }
};

/**
 * PATCH /api/admin/astrologer/:id/toggle-online
 * Admin only — toggle astrologer's online status.
 * In production, astrologers will control this themselves via their app.
 */
export const toggleOnlineStatus = async (req, res) => {
  try {
    const astrologer = await Astrologer.findById(req.params.id);
    if (!astrologer) {
      return res.status(404).json({ success: false, message: "Astrologer not found" });
    }

    astrologer.isOnline = !astrologer.isOnline;
    await astrologer.save();

    return res.json({
      success: true,
      message: `${astrologer.name} is now ${astrologer.isOnline ? "online" : "offline"}`,
      isOnline: astrologer.isOnline,
    });
  } catch (err) {
    console.error("toggleOnlineStatus error:", err);
    return res.status(500).json({ success: false, message: "Failed to toggle status" });
  }
};

/**
 * GET /api/admin/astrologer/all
 * Admin only — list all astrologers with full details.
 */
export const getAllAstrologers = async (req, res) => {
  try {
    const astrologers = await Astrologer.find()
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ success: true, astrologers, total: astrologers.length });
  } catch (err) {
    console.error("getAllAstrologers error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch astrologers" });
  }
};

/**
 * GET /api/admin/astrologer/bookings
 * Admin only — all bookings across all astrologers.
 */
export const getAllBookings = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const [bookings, total] = await Promise.all([
      Booking.find(filter)
        .populate("userId", "name email phone")
        .populate("astrologerId", "name email")
        .sort({ createdAt: -1 })
        .skip((Number(page) - 1) * Number(limit))
        .limit(Number(limit))
        .lean(),
      Booking.countDocuments(filter),
    ]);

    return res.json({
      success: true,
      bookings,
      pagination: { total, page: Number(page), totalPages: Math.ceil(total / Number(limit)) },
    });
  } catch (err) {
    console.error("getAllBookings error:", err);
    return res.status(500).json({ success: false, message: "Failed to fetch bookings" });
  }
};