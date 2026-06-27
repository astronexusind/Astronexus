// backend/src/routes/unified/unified.routes.js
// CHANGES: Added 2 new routes for personalized horoscope
//   GET  /api/unified/my-horoscope        — authenticated, uses Moon sign from birth chart
//   DELETE /api/unified/my-horoscope/cache — admin cache management

import express from "express";
import {
  aggregateUnified,
  proxyBirthChart,
  proxyHoroscope,
  proxyMatiChat,
  unifiedHealth,
} from "../../controllers/unified/unifiedController.js";
import {
  getPersonalizedHoroscope,
  clearHoroscopeCache,
} from "../../controllers/unified/personalizedHoroscope.js";
import { authenticateToken, authorizeAdmin } from "../../middlewares/auth.js";

const router = express.Router();

// ── Existing routes (unchanged) ───────────────────────────────────────────────
router.get("/health",      unifiedHealth);
router.post("/birth-chart", proxyBirthChart);
router.get("/horoscope",   proxyHoroscope);    // generic — requires ?sign= from client
router.post("/mati-chat",  proxyMatiChat);
router.post("/aggregate",  aggregateUnified);

// ── New personalized horoscope routes ────────────────────────────────────────
// Uses the logged-in user's Moon sign from their stored birth chart
// No ?sign= needed — reads it automatically from MongoDB
router.get("/my-horoscope", authenticateToken, getPersonalizedHoroscope);
router.delete("/my-horoscope/cache", authenticateToken, authorizeAdmin, clearHoroscopeCache);

export default router;