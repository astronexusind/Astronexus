import express from "express";
import path from "path";
import cookieParser from "cookie-parser";
import cors from "cors";
import morgan from "morgan";
import { fileURLToPath } from "url";
import { ApiError } from "./utils/ApiError.js";
import { globalLimiter } from "./middlewares/rateLimiters.js";

// Load routes
import apiRoutes, { staticRoute, userRoute, optionalAuth, URL } from "./api/index.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// ================= SECURITY & RATE LIMITING =================
// Apply a global rate limit so every service path is covered.
app.use(globalLimiter);

// ================= SETTINGS =================
app.set("trust proxy", 1);
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "./views"));

// ================= GLOBAL MIDDLEWARE =================
app.use(cors({ origin: true, credentials: true }));
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// ================= STATIC FOLDERS =================
app.use("/charts", express.static(path.join(__dirname, "./controllers/charts")));

// ================= API ROUTES =================
app.use("/api", apiRoutes);

// ================= USER ROUTES =================
app.use("/user", userRoute);

// ================= SHORT URL REDIRECT =================
app.get("/url/:shortId", async (req, res) => {
  try {
    const entry = await URL.findOneAndUpdate(
      { shortId: req.params.shortId },
      { $push: { visitHistory: { timestamp: new Date() } } },
      { new: true }
    );

    if (!entry) {
      return res.status(404).json({ error: "URL not found" });
    }

    return res.redirect(entry.redirectURL);
  } catch (err) {
    console.error("Redirect error:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ================= STATIC PAGES =================
app.use("/", optionalAuth, staticRoute);

// Health Check
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    time: new Date()
  });
});

// ================= ERROR HANDLING =================
// 404 Handler
app.use((req, res, next) => {
  const error = new ApiError(404, "Route not found");
  next(error);
});

const normalizeErrorMessage = (err) => {
  if (Array.isArray(err.errors) && err.errors.length > 0) {
    return err.errors;
  }

  if (typeof err.message === "string" && err.message.trim()) {
    return [err.message];
  }

  return ["Internal Server Error"];
};

// Global Error Handler
app.use((err, req, res, next) => {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errors: normalizeErrorMessage(err),
      stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
    });
  }

  if (err?.name === "MulterError" || err?.code?.startsWith?.("LIMIT_")) {
    const message = err.code === "LIMIT_FILE_SIZE"
      ? "Uploaded file is too large"
      : err.message || "Invalid uploaded file";

    return res.status(400).json({
      success: false,
      message,
      errors: [message],
      stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
    });
  }

  if (err?.name === "ValidationError") {
    const errors = Object.values(err.errors || {}).map((item) => item.message);

    return res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: errors.length > 0 ? errors : ["Validation failed"],
      stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
    });
  }

  if (err?.name === "CastError") {
    return res.status(400).json({
      success: false,
      message: `Invalid ${err.path}`,
      errors: [`Invalid ${err.path}`],
      stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
    });
  }

  // Fallback for non-ApiError errors
  console.error("Unhandled error:", err);
  return res.status(500).json({
    success: false,
    message: err.message || "Internal Server Error",
    stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
  });
});

export default app;
