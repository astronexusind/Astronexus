import express from "express";
import { ashtakootScore } from "../../controllers/services/compatabiltycontroller.js";
import { checkFeatureEnabled } from "../../middlewares/checkFeature.js";
import { trackFeatureUsage } from "../../middlewares/trackUsage.js";

const router = express.Router();

// Generate Ashtakoot Compatibility Score
router.post(
  "/match-making/ashtakoot-score",
  checkFeatureEnabled("compatibility"),   // 👈 feature key
  trackFeatureUsage,                      // 👈 usage tracking
  ashtakootScore
);

export default router;
