// backend/src/routes/subscription/subscription.routes.js
import express from "express";
import { authenticateToken, authorizeAdmin } from "../../middlewares/auth.js";
import {
  getPlans,
  getStatus,
  activateSubscription,
  cancelSubscription,
  seedPlans,
  getAllSubscriptions,
} from "../../controllers/subscription/subscription.controller.js";

const router = express.Router();

// ── Public ─────────────────────────────────────────────────────────────────
// GET /api/subscription/plans — Flutter subscription screen fetches this
router.get("/plans", getPlans);

// ── Protected (user must be logged in) ─────────────────────────────────────
router.get("/status",   authenticateToken, getStatus);
router.post("/activate", authenticateToken, activateSubscription);
router.post("/cancel",   authenticateToken, cancelSubscription);

// ── Admin only ──────────────────────────────────────────────────────────────
router.post("/seed-plans",  authenticateToken, authorizeAdmin, seedPlans);
router.get("/all",          authenticateToken, authorizeAdmin, getAllSubscriptions);

export default router;