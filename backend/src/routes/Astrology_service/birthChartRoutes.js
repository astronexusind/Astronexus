import express from "express";
import { generateBirthChart } from "../../controllers/services/birthChartImage.js";
import { checkFeatureEnabled } from "../../middlewares/checkFeature.js";
import { trackFeatureUsage } from "../../middlewares/trackUsage.js";

const router = express.Router();

// Generate Birth Chart
router.post(
  "/generate",
  checkFeatureEnabled("birth_chart"),
  trackFeatureUsage,
  generateBirthChart
);

export default router;
