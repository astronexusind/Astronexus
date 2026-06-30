// backend/src/routes/astrologer/astrologer.routes.js
import express from "express";
import { authenticateToken, authorizeAdmin } from "../../middlewares/auth.js";
import { requirePremium } from "../../middlewares/checkFeature.js";
import {
  listAstrologers,
  getAstrologer,
  bookSession,
  startSession,
  endSession,
  cancelBooking,
  submitReview,
  getMyBookings,
  createAstrologer,
  verifyAstrologer,
  toggleOnlineStatus,
  getAllAstrologers,
  getAllBookings,
} from "../../controllers/astrologer/astrologer.controller.js";

const router = express.Router();

// ── Public ────────────────────────────────────────────────────────────────────
router.get("/list",        listAstrologers);

// ── Protected user routes (specific routes BEFORE /:id wildcard) ──────────────
router.get("/my-bookings",                 authenticateToken, getMyBookings);
router.post("/book",                       authenticateToken, requirePremium, bookSession);
router.post("/session/start/:bookingId",   authenticateToken, requirePremium, startSession);
router.post("/session/end/:bookingId",     authenticateToken, endSession);
router.post("/session/cancel/:bookingId",  authenticateToken, cancelBooking);
router.post("/session/:bookingId/review",  authenticateToken, submitReview);

// ── Wildcard MUST come after all specific routes ───────────────────────────────
router.get("/:id",   getAstrologer);

// ── Admin routes ──────────────────────────────────────────────────────────────
router.post("/admin/create",                authenticateToken, authorizeAdmin, createAstrologer);
router.patch("/admin/:id/verify",           authenticateToken, authorizeAdmin, verifyAstrologer);
router.patch("/admin/:id/toggle-online",    authenticateToken, authorizeAdmin, toggleOnlineStatus);
router.get("/admin/all",                    authenticateToken, authorizeAdmin, getAllAstrologers);
router.get("/admin/bookings",               authenticateToken, authorizeAdmin, getAllBookings);
// ── Admin routes ──────────────────────────────────────────────────────────────
router.post("/admin/create",                authenticateToken, authorizeAdmin, createAstrologer);
router.patch("/admin/:id/verify",           authenticateToken, authorizeAdmin, verifyAstrologer);
router.patch("/admin/:id/toggle-online",    authenticateToken, authorizeAdmin, toggleOnlineStatus);
router.get("/admin/all",                    authenticateToken, authorizeAdmin, getAllAstrologers);
router.get("/admin/bookings",               authenticateToken, authorizeAdmin, getAllBookings);

export default router;
