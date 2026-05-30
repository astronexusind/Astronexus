import express from "express";
import {
  handleGenerateNewShortURL,
  handleGetAnalytics,
  handleGetAllUrls,
  handleDeleteUrl,
} from "../controllers/url.js";

const router = express.Router();

router.post("/", handleGenerateNewShortURL);
router.get("/", handleGetAllUrls);
router.get("/analytics/:shortId", handleGetAnalytics);
router.delete("/:shortId", handleDeleteUrl);

export default router;
