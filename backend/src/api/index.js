import { Router } from "express";
import { authenticateToken, optionalAuth } from "../middlewares/auth.js";
import URL from "../models/url.js";

// Import all route modules
import tarotRoutes from '../routes/Astrology_service/tarotRoutes.js';
import predictionsRoute from "../routes/predictions.js";
import birthChartRoute from "../routes/Astrology_service/birthChartRoutes.js";
import urlRoute from "../routes/url.js";
import staticRoute from "../routes/staticRouter.js";
import userRoute from "../routes/users/user.js";
import compatibilityRoute from "../routes/Astrology_service/compatablity.js";
import horoscopeRoute from "../routes/Astrology_service/horoscope.js";

import adminAuthRoutes from "../routes/admin/admin.auth.routes.js";
import adminProductRoutes from "../routes/admin/admin.product.routes.js";
import adminOrderRoutes from "../routes/admin/admin.order.routes.js";
import adminCMSRoutes from "../routes/admin/admin.cms.routes.js";
import adminDashboardRoutes from "../routes/admin/admin.dashboard.routes.js";
import adminCategoryRoutes from "../routes/admin/categories.js";
import adminUserRoutes from "../routes/admin/admin.user.routes.js";
import feedbackRoutes from "../routes/feedback/feedback.js";
import chatbotRoutes from "../routes/chatbot/chatbot.routes.js";
import adminAstroRoutes from "../routes/admin/adminAstrologyRoutes.js";
import adminAstrologyServiceRoutes from "../routes/admin/admin.astrologyService.routes.js";
import invoiceRoutes from "../routes/invoice/invoiceRoutes.js";
import discountRoutes from "../routes/admin/discountRoutes.js";
import unifiedRoutes from "../routes/unified/unified.routes.js";
import shippingRoutes from "../routes/shipping/shipping.js";
import couponRoutes from "../routes/admin/coupons.js";
import notificationRoutes from "../routes/notification/notificationRoutes.js";

const router = Router();

// ================= PUBLIC APIs =================
router.use("/predictions", predictionsRoute);
router.use("/birthchart", birthChartRoute);
router.use("/chatbot", chatbotRoutes);
router.use("/unified", unifiedRoutes);
router.use("/invoice", invoiceRoutes);
router.use("/v1/compatibility", compatibilityRoute);
router.use("/horoscope", horoscopeRoute);
router.use("/feedback", feedbackRoutes);
router.use("/tarot", tarotRoutes);
router.use("/shipping", shippingRoutes);
router.use("/notifications", notificationRoutes);

// ================= ADMIN APIs =================
const adminRouter = Router();
adminRouter.use("/auth", adminAuthRoutes);
adminRouter.use("/products", adminProductRoutes);
adminRouter.use("/users", adminUserRoutes);
adminRouter.use("/orders", adminOrderRoutes);
adminRouter.use("/cms", adminCMSRoutes);
adminRouter.use("/dashboard", adminDashboardRoutes);
adminRouter.use("/categories", adminCategoryRoutes);
adminRouter.use("/astrology", adminAstroRoutes);
adminRouter.use("/astrology-services", adminAstrologyServiceRoutes);

router.use("/admin", adminRouter);

// ================= OTHER APIs =================
router.use("/discount", discountRoutes);
router.use("/coupon", couponRoutes);
router.use("/url", authenticateToken, urlRoute);

// ================= USER APIs =================
// Mount user outside /api if needed or inside. 
// Original was app.use("/user", userRoute)
// I will keep it consistent with original mounting points in app.js if they vary.

export default router;
export { staticRoute, userRoute, optionalAuth, URL };
