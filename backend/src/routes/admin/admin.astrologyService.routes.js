import express from "express";
import {
  createService,
  getAllServices,
  getServiceById,
  updateService,
  deleteService,
  toggleService
} from "../../controllers/services/astrologyServiceController.js";
import { authenticateToken } from "../../middlewares/auth.js";
import adminMiddleware from "../../middlewares/admin.middleware.js";

const router = express.Router();

// All routes are admin protected
router.use(authenticateToken, adminMiddleware);

router.post("/", createService);
router.get("/", getAllServices);
router.get("/:id", getServiceById);
router.put("/:id", updateService);
router.delete("/:id", deleteService);
router.patch("/:id/toggle", toggleService);

export default router;
