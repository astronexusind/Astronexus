// backend/src/controllers/unified/personalizedHoroscope.js
//
// NEW FILE — adds personalized horoscope fetching on top of existing
// unifiedController.js without modifying any existing code.
//
// Key difference from existing proxyHoroscope:
//   - Reads Moon sign (rashi) from user's stored BirthChart in MongoDB
//   - Falls back to Sun sign if Moon sign not available
//   - Enriches response with user's Nakshatra, Ascendant, Dasha context
//   - Caches response for 6 hours per user to avoid hammering the API
//   - Requires authentication — this is a personalized endpoint

import axios from "axios";
import BirthChart from "../../models/features/birthChartModel.js";
import User from "../../models/user/user.js";

const HTTP_TIMEOUT_MS    = Number(process.env.UNIFIED_PROXY_TIMEOUT_MS || 45000);
const HOROSCOPE_BASE_URL = () =>
  (process.env.HOROSCOPE_SERVICE_URL || "http://127.0.0.1:4000").replace(/\/+$/, "");

// ── In-memory cache (6-hour TTL, keyed per user+type+day+date) ───────────────
// For production: swap for Redis so cache survives server restarts
const horoscopeCache = new Map();
const CACHE_TTL_MS   = 6 * 60 * 60 * 1000; // 6 hours

function getCacheKey(userId, type, day) {
  const today = new Date().toISOString().slice(0, 10);
  return `${userId}:${type}:${day}:${today}`;
}

function getCached(key) {
  const entry = horoscopeCache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.timestamp > CACHE_TTL_MS) {
    horoscopeCache.delete(key);
    return null;
  }
  return entry.data;
}

function setCache(key, data) {
  // Prevent unbounded memory growth — evict oldest if over 1000 entries
  if (horoscopeCache.size > 1000) {
    const firstKey = horoscopeCache.keys().next().value;
    horoscopeCache.delete(firstKey);
  }
  horoscopeCache.set(key, { data, timestamp: Date.now() });
}

// ── Vedic rashi → western sign name mapping ───────────────────────────────────
// The horoscope API uses western sign names; birth chart stores Vedic rashis
const RASHI_TO_SIGN = {
  mesha:       "aries",
  vrishabha:   "taurus",
  mithuna:     "gemini",
  karka:       "cancer",
  simha:       "leo",
  kanya:       "virgo",
  tula:        "libra",
  vrishchika:  "scorpio",
  dhanu:       "sagittarius",
  makara:      "capricorn",
  kumbha:      "aquarius",
  meena:       "pisces",
  // Already in English — pass through
  aries:        "aries",
  taurus:       "taurus",
  gemini:       "gemini",
  cancer:       "cancer",
  leo:          "leo",
  virgo:        "virgo",
  libra:        "libra",
  scorpio:      "scorpio",
  sagittarius:  "sagittarius",
  capricorn:    "capricorn",
  aquarius:     "aquarius",
  pisces:       "pisces",
};

function normalizeSign(raw) {
  if (!raw) return null;
  return RASHI_TO_SIGN[String(raw).toLowerCase().trim()] || null;
}

// ── Extract chart context from stored FastAPI response ────────────────────────
function extractChartContext(chartData) {
  if (!chartData) return {};
  const planets   = chartData.planets  || {};
  const dashas    = chartData.dashas   || {};
  const nakshatra = chartData.nakshatra || null;
  const ascendant = chartData.ascendant?.sign || null;
  const sunSign   = planets.Sun?.sign || planets.sun?.sign || null;

  // Current mahadasha — structure varies by FastAPI version
  let currentDasha = null;
  if (Array.isArray(dashas) && dashas.length > 0) {
    currentDasha = dashas[0]?.planet || null;
  } else if (dashas?.current?.planet) {
    currentDasha = dashas.current.planet;
  }

  return { nakshatra, ascendant, currentDasha, sunSign };
}

// ── Fetch horoscope from the horoscope sub-service ────────────────────────────
async function fetchHoroscope(sign, type, day) {
  const params = type === "daily" ? { sign, type, day } : { sign, type };
  const { data } = await axios.get(`${HOROSCOPE_BASE_URL()}/api/horoscope`, {
    params,
    timeout: HTTP_TIMEOUT_MS,
    headers: { "User-Agent": "AstroNexus-Backend/1.0" },
  });
  return data;
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN HANDLER
// GET /api/unified/my-horoscope?type=daily&day=TODAY
//
// Requires authenticateToken middleware (reads req.user.id)
// ═════════════════════════════════════════════════════════════════════════════
export const getPersonalizedHoroscope = async (req, res) => {
  try {
    const userId = req.user.id;
    const type   = String(req.query.type || "daily").toLowerCase().trim();
    const day    = String(req.query.day  || "TODAY").toUpperCase().trim();

    if (!["daily", "weekly", "monthly"].includes(type)) {
      return res.status(400).json({
        success: false,
        message: "Invalid type. Use: daily, weekly, or monthly",
      });
    }

    if (type === "daily" && !["TODAY", "TOMORROW", "YESTERDAY"].includes(day)) {
      return res.status(400).json({
        success: false,
        message: "Invalid day. Use: TODAY, TOMORROW, or YESTERDAY",
      });
    }

    // ── Check cache ───────────────────────────────────────────────────────────
    const cacheKey = getCacheKey(userId, type, day);
    const cached   = getCached(cacheKey);
    if (cached) {
      return res.json({ ...cached, cached: true });
    }

    // ── Load user + most recent birth chart in parallel ───────────────────────
    const [user, birthChart] = await Promise.all([
      User.findById(userId).select("name astrologyProfile"),
      BirthChart.findOne({ userId }).sort({ createdAt: -1 }).lean(),
    ]);

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    // ── Determine Moon sign (rashi) from birth chart ──────────────────────────
    let moonSign     = null;
    let signSource   = null;
    let chartContext = {};

    if (birthChart) {
      // Primary: Moon rashi stored directly on BirthChart document
      const rawRashi =
        birthChart.rashi ||
        birthChart.chartData?.rashi ||
        birthChart.chartData?.moon?.sign ||
        birthChart.chartData?.Moon?.sign ||
        null;

      moonSign   = normalizeSign(rawRashi);
      signSource = moonSign ? "moon_sign" : null;

      // Extract additional context for enrichment
      chartContext = extractChartContext(birthChart.chartData);

      // Fallback: use Sun sign from chart data
      if (!moonSign && chartContext.sunSign) {
        moonSign   = normalizeSign(chartContext.sunSign);
        signSource = "sun_sign_fallback";
      }
    }

    // ── Guard: no birth chart generated yet ───────────────────────────────────
    if (!moonSign) {
      return res.status(400).json({
        success: false,
        message: user.astrologyProfile?.dateOfBirth
          ? "Birth chart not generated yet. Please generate your chart first."
          : "Please complete your astrology profile to get personalized horoscope.",
        action: user.astrologyProfile?.dateOfBirth
          ? "GENERATE_BIRTH_CHART"
          : "COMPLETE_PROFILE",
      });
    }

    // ── Fetch horoscope using user's Moon sign ────────────────────────────────
    const horoscopeData = await fetchHoroscope(moonSign, type, day);

    // ── Build enriched response ───────────────────────────────────────────────
    const result = {
      success:      true,
      cached:       false,
      personalized: true,
      signSource,   // tells Flutter which sign was used (moon_sign or sun_sign_fallback)

      user: {
        name:         user.name,
        moonSign,
        nakshatra:    chartContext.nakshatra    || null,
        ascendant:    chartContext.ascendant    || null,
        currentDasha: chartContext.currentDasha || null,
      },

      horoscope:   horoscopeData,
      type,
      ...(type === "daily" && { day }),
      generatedAt: new Date().toISOString(),
    };

    setCache(cacheKey, result);

    return res.json(result);

  } catch (err) {
    console.error("getPersonalizedHoroscope error:", err.message);

    if (err.code === "ECONNREFUSED") {
      return res.status(503).json({
        success: false,
        message: "Horoscope service unavailable. Please try again later.",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to fetch personalized horoscope",
    });
  }
};

/**
 * DELETE /api/unified/my-horoscope/cache
 * Clears the in-memory horoscope cache (admin/debug use)
 */
export const clearHoroscopeCache = (req, res) => {
  const size = horoscopeCache.size;
  horoscopeCache.clear();
  return res.json({ success: true, message: `Cleared ${size} cache entries` });
};