import { Router } from "express";
import * as controller from "../../controllers/admin/admin.product.controller.js";
import { authenticateToken } from "../../middlewares/auth.js";
import admin from "../../middlewares/admin.middleware.js";
import uploadProduct from "../../middlewares/upload.product.js";
import { uploadLimiter } from "../../middlewares/rateLimiters.js";

const router = Router();

// Auth
router.use(authenticateToken);
router.use(admin);

// ================= PRODUCT ROUTES =================

// CREATE PRODUCT (WITH IMAGES)
router.post(
  "/",
  uploadLimiter,
  uploadProduct.array("images", 5), // 👈 IMPORTANT
  controller.createProduct
);

router.get("/", controller.getAllProducts);
router.get("/:id", controller.getProductById);

// UPDATE PRODUCT (OPTIONAL IMAGE UPDATE)
router.put(
  "/:id",
  uploadLimiter,
  uploadProduct.array("images", 5),
  controller.updateProduct
);

// Delete handling
router.patch("/:id/deactivate", controller.deactivateProduct);
router.delete("/:id", controller.deleteProductPermanent);

export default router;
