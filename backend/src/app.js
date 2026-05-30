import express from "express";
import path from "path";
import cookieParser from "cookie-parser";
import cors from "cors";
import morgan from "morgan";
import { fileURLToPath } from "url";
import { rateLimit } from "express-rate-limit";
import { ApiError } from "./utils/ApiError.js";

// Load routes
import apiRoutes, { staticRoute, userRoute, optionalAuth, URL } from "./api/index.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// ================= SECURITY & RATE LIMITING =================
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
  standardHeaders: "draft-7", // draft-6: `RateLimit-*` headers; draft-7: combined `RateLimit` header
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    status: 429,
    message: "Too many requests from this IP, please try again after 15 minutes",
  },
});

// Apply the rate limiting middleware to all requests
app.use("/api", limiter);

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

// Global Error Handler
app.use((err, req, res, next) => {
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errors: err.errors,
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
