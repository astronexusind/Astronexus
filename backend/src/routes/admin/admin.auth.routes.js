import express from "express";
import {
  login,
  updatePassword,
  logout,
  getAllAdmins,
  createAdmin
} from "../../controllers/admin/admin.auth.controller.js";

import { authenticateToken } from "../../middlewares/auth.js";
import { authLimiter } from "../../middlewares/rateLimiters.js";
import { validate } from "../../middlewares/validate.middleware.js";
import { adminCreateSchema, adminLoginSchema, adminUpdatePasswordSchema } from "../../validations/admin.validation.js";

const router = express.Router();

router.post("/create", authLimiter, validate(adminCreateSchema), createAdmin); // only works with setup key
router.post("/login", authLimiter, validate(adminLoginSchema), login);
router.get("/all", authenticateToken, getAllAdmins);

router.put("/update-password", authenticateToken, authLimiter, validate(adminUpdatePasswordSchema), updatePassword);
router.post("/logout", authenticateToken, logout);

export default router;
