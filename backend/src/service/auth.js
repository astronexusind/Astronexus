// backend/service/auth.js
import jwt from "jsonwebtoken";
import crypto from "crypto";
import BlacklistedToken from "../models/auth/BlacklistedToken.model.js";

/**
 * Create a short-lived JWT access token.
 * Every token now carries a unique `jti` so it can be individually
 * blacklisted on logout, without needing to store the full token string.
 */
export function createToken(user) {
  const payload = {
    id: user._id,
    email: user.email,
    name: user.name,
    jti: crypto.randomUUID(),
  };
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
  });
}

/**
 * Verify access token. Returns null if the signature is invalid,
 * the token is expired, OR the token has been blacklisted (logged out).
 */
export async function verifyToken(token) {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.jti) {
      const isBlacklisted = await BlacklistedToken.exists({ jti: decoded.jti });
      if (isBlacklisted) return null;
    }

    return decoded;
  } catch (error) {
    return null;
  }
}

/**
 * Create a long-lived refresh token, also carrying a unique jti.
 */
export function createRefreshToken(user) {
  const payload = {
    id: user._id,
    jti: crypto.randomUUID(),
  };
  return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "30d",
  });
}

/**
 * Verify refresh token, also checking the blacklist.
 */
export async function verifyRefreshToken(token) {
  try {
    const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);

    if (decoded.jti) {
      const isBlacklisted = await BlacklistedToken.exists({ jti: decoded.jti });
      if (isBlacklisted) return null;
    }

    return decoded;
  } catch (error) {
    return null;
  }
}

/**
 * Blacklist a token by its jti so it can no longer be used,
 * even though its signature remains valid until natural expiry.
 *
 * @param {string} token - the raw JWT (we decode it without verifying
 *   the signature here, since an expired/logged-out token should still
 *   be blacklist-able even right at the edge of expiry)
 * @param {"access"|"refresh"|"admin"} tokenType
 */
export async function blacklistToken(token, tokenType = "access") {
  if (!token) return;

  const decoded = jwt.decode(token); // decode without verifying — we just need jti/exp
  if (!decoded || !decoded.jti) return; // nothing to blacklist (e.g. legacy token with no jti)

  const expiresAt = decoded.exp
    ? new Date(decoded.exp * 1000)
    : new Date(Date.now() + 24 * 60 * 60 * 1000); // fallback: 1 day

  try {
    await BlacklistedToken.create({
      jti: decoded.jti,
      userId: decoded.id,
      tokenType,
      expiresAt,
    });
  } catch (err) {
    // Duplicate jti (already blacklisted) is fine — ignore that specific case
    if (err.code !== 11000) throw err;
  }
}
