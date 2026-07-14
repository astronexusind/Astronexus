import express from "express";
import { ashtakootScore } from "../../controllers/services/compatabiltycontroller.js";
import { checkFeatureEnabled } from "../../middlewares/checkFeature.js";
import { trackFeatureUsage } from "../../middlewares/trackUsage.js";
// 👇 1. Import your auth middleware (Make sure this path matches your project structure!)
import { authenticateToken } from "../../middlewares/auth.js"; 

const router = express.Router();

// Generate Ashtakoot Compatibility Score
router.post(
  "/match-making/ashtakoot-score",
  authenticateToken,                      // 👇 2. Add it here FIRST
  checkFeatureEnabled("compatibility"),   
  trackFeatureUsage,                      
  ashtakootScore
);

export default router;