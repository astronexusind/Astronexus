import express from "express";
import { getRandomCards } from "../../controllers/services/tarotController.js";
import { checkFeatureEnabled } from "../../middlewares/checkFeature.js";
import { trackFeatureUsage } from "../../middlewares/trackUsage.js";
import { authenticateToken } from "../../middlewares/auth.js";

const router = express.Router();

// GET /api/tarot/random?n=3
router.get(
  "/random",
  authenticateToken,               // 👈 user must be logged in (optional if you want public)
  checkFeatureEnabled("tarot"),     // 👈 feature flag
  trackFeatureUsage,               // 👈 usage tracking
  getRandomCards
);

export default router;
