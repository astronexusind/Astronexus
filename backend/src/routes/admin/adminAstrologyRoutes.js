import express from "express";
import {
  getAstrologyDashboard,
  toggleFeature
} from "../../controllers/services/adminAstroController.js";

const router = express.Router();

router.get("/astro-dashboard", getAstrologyDashboard);
router.patch("/toggle-feature", toggleFeature);

export default router;
