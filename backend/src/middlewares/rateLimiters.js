import { rateLimit } from "express-rate-limit";
import { ApiError } from "../utils/ApiError.js";

const defaultLimiterOptions = {
  standardHeaders: "draft-7",
  legacyHeaders: false,
};

const buildLimiter = ({ windowMs, max, message, skipSuccessfulRequests = false }) =>
  rateLimit({
    windowMs,
    max,
    skipSuccessfulRequests,
    ...defaultLimiterOptions,
    handler: (req, res, next) => {
      next(new ApiError(429, message, [message]));
    },
  });

export const globalLimiter = buildLimiter({
  windowMs: 15 * 60 * 1000,
  max: 250,
  message: "Too many requests. Please try again in 15 minutes.",
});

export const authLimiter = buildLimiter({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: "Too many authentication attempts. Please try again later.",
  skipSuccessfulRequests: true,
});

export const uploadLimiter = buildLimiter({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: "Too many upload requests. Please slow down and try again later.",
});
