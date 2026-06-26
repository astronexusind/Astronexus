// backend/src/routes/payment/webhook.routes.js
//
// IMPORTANT: The webhook route MUST use express.raw() as body parser.
// Razorpay's signature verification requires the raw request body bytes.
// If express.json() parses it first, the signature check will always fail.

import express from "express";
import { webhook } from "../../controllers/users/payment.controller.js";

const router = express.Router();

// express.raw() keeps the body as a Buffer — required for HMAC verification
router.post(
  "/webhook",
  express.raw({ type: "application/json" }),
  webhook
);

export default router;