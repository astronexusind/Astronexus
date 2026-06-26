// backend/src/middlewares/checkFeature.js
// CHANGES from original:
//   checkFeatureEnabled now also checks if the feature is premium-gated
//   and if so, whether the requesting user has an active subscription.
//   Added requirePremium middleware for routes that are always premium-only.

import FeatureFlag from "../models/features/featureFlagModel.js";
import FeatureUsage from "../models/features/featureUsageModel.js";
import User from "../models/user/user.js";

/**
 * Middleware: Check if a feature is enabled AND if the user meets
 * the premium requirement (if the feature is premium-gated).
 *
 * Usage in routes:
 *   router.get("/daily", authenticateToken, checkFeatureEnabled("horoscope"), handler);
 *   router.post("/chat", authenticateToken, checkFeatureEnabled("mati_chat"), handler);
 */
export const checkFeatureEnabled = (featureKey) => async (req, res, next) => {
  try {
    const feature = await FeatureFlag.findOne({ key: featureKey });

    // Feature doesn't exist or is globally disabled by admin
    if (!feature || !feature.enabled) {
      return res.status(403).json({
        success: false,
        message: `${featureKey} is currently unavailable`,
      });
    }

    // Feature is premium-gated — check if user has active subscription
    if (feature.isPremium) {
      // authenticateToken must run before this middleware
      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: "Authentication required to access this feature",
        });
      }

      // Fetch fresh user data (don't trust JWT cache for subscription status)
      const user = await User.findById(req.user.id).select(
        "isPremium subscriptionExpiry subscriptionPlan"
      );

      if (!user) {
        return res.status(401).json({ success: false, message: "User not found" });
      }

      // Check both the flag AND expiry (handles case where cron hasn't run yet)
      const isActive =
        user.isPremium === true &&
        user.subscriptionExpiry !== null &&
        user.subscriptionExpiry > new Date();

      if (!isActive) {
        return res.status(403).json({
          success: false,
          message: "This feature requires an active subscription",
          code: "SUBSCRIPTION_REQUIRED",
          // Tell the Flutter app to show the subscription screen
          action: "SHOW_SUBSCRIPTION_SCREEN",
        });
      }
    }

    // Track feature usage (for analytics)
    if (req.user?.id) {
      FeatureUsage.create({
        featureKey,
        userId: req.user.id,
      }).catch(() => {}); // non-blocking, don't fail the request if this errors
    }

    req.featureKey = featureKey;
    next();

  } catch (err) {
    console.error("checkFeatureEnabled error:", err);
    return res.status(500).json({ success: false, message: "Feature check failed" });
  }
};

/**
 * Middleware: Require an active premium subscription.
 * Use this for routes that are ALWAYS premium — no feature flag needed.
 *
 * Usage:
 *   router.get("/astrologer/book", authenticateToken, requirePremium, handler);
 */
export const requirePremium = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ success: false, message: "Authentication required" });
    }

    const user = await User.findById(req.user.id).select(
      "isPremium subscriptionExpiry subscriptionPlan"
    );

    if (!user) {
      return res.status(401).json({ success: false, message: "User not found" });
    }

    const isActive =
      user.isPremium === true &&
      user.subscriptionExpiry !== null &&
      user.subscriptionExpiry > new Date();

    if (!isActive) {
      return res.status(403).json({
        success: false,
        message: "This feature requires an active premium subscription",
        code: "SUBSCRIPTION_REQUIRED",
        action: "SHOW_SUBSCRIPTION_SCREEN",
      });
    }

    // Attach subscription info for controllers to use if needed
    req.subscription = {
      plan:      user.subscriptionPlan,
      expiresAt: user.subscriptionExpiry,
    };

    next();

  } catch (err) {
    console.error("requirePremium error:", err);
    return res.status(500).json({ success: false, message: "Subscription check failed" });
  }
};