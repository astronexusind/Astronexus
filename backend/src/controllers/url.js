import { nanoid } from "nanoid";
import validator from "validator";
import URL from "../models/url.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";

const handleGenerateNewShortURL = asyncHandler(async (req, res) => {
  const { url, customShortId } = req.body;

  // Validation
  if (!url) {
    throw new ApiError(400, "URL is required");
  }

  if (!validator.isURL(url, { require_protocol: true })) {
    throw new ApiError(400, "Invalid URL format. Must include protocol (http:// or https://)");
  }

  // Generate or use custom short ID
  let shortID;
  if (customShortId) {
    // Validate custom short ID
    if (!/^[a-zA-Z0-9_-]+$/.test(customShortId)) {
      throw new ApiError(400, "Custom short ID can only contain letters, numbers, hyphens, and underscores");
    }

    // Check if custom ID already exists
    const existing = await URL.findOne({ shortId: customShortId });
    if (existing) {
      throw new ApiError(400, "Custom short ID already taken");
    }

    shortID = customShortId;
  } else {
    shortID = nanoid(8);
  }

  // Create short URL
  const urlDoc = await URL.create({
    shortId: shortID,
    redirectURL: url,
    visitHistory: [],
    createdBy: req.user._id,
  });

  return res.status(201).json(
    new ApiResponse(201, {
      shortId: urlDoc.shortId,
      originalUrl: urlDoc.redirectURL,
      shortUrl: `${process.env.BASE_URL}/url/${urlDoc.shortId}`,
      createdAt: urlDoc.createdAt,
    }, "Short URL created successfully")
  );
});

const handleGetAnalytics = asyncHandler(async (req, res) => {
  const { shortId } = req.params;

  const urlDoc = await URL.findOne({ shortId });

  if (!urlDoc) {
    throw new ApiError(404, "Short URL not found");
  }

  // Check if user owns this URL
  if (urlDoc.createdBy.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "Access denied. You don't own this URL");
  }

  return res.status(200).json(
    new ApiResponse(200, {
      shortId: urlDoc.shortId,
      originalUrl: urlDoc.redirectURL,
      totalClicks: urlDoc.visitHistory.length,
      createdAt: urlDoc.createdAt,
      analytics: urlDoc.visitHistory,
    })
  );
});

const handleGetAllUrls = asyncHandler(async (req, res) => {
  const urls = await URL.find({ createdBy: req.user._id }).sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, {
      count: urls.length,
      urls: urls.map((url) => ({
        shortId: url.shortId,
        originalUrl: url.redirectURL,
        shortUrl: `${process.env.BASE_URL}/url/${url.shortId}`,
        clicks: url.visitHistory.length,
        createdAt: url.createdAt,
      })),
    })
  );
});

const handleDeleteUrl = asyncHandler(async (req, res) => {
  const { shortId } = req.params;

  const urlDoc = await URL.findOne({ shortId });

  if (!urlDoc) {
    throw new ApiError(404, "Short URL not found");
  }

  // Check if user owns this URL
  if (urlDoc.createdBy.toString() !== req.user._id.toString()) {
    throw new ApiError(403, "Access denied. You don't own this URL");
  }

  await URL.deleteOne({ shortId });

  return res.status(200).json(
    new ApiResponse(200, null, "Short URL deleted successfully")
  );
});

export {
  handleGenerateNewShortURL,
  handleGetAnalytics,
  handleGetAllUrls,
  handleDeleteUrl,
};
