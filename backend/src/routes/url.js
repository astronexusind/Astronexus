import express from "express";
import {
  handleGenerateNewShortURL,
  handleGetAnalytics,
  handleGetAllUrls,
  handleDeleteUrl,
} from "../controllers/url.js";
import { authLimiter } from "../middlewares/rateLimiters.js";
import { validate } from "../middlewares/validate.middleware.js";
import { shortUrlSchema } from "../validations/url.validation.js";

const router = express.Router();

router.post("/", authLimiter, validate(shortUrlSchema), handleGenerateNewShortURL);
router.get("/", handleGetAllUrls);
router.get("/analytics/:shortId", handleGetAnalytics);
router.delete("/:shortId", authLimiter, handleDeleteUrl);

export default router;
