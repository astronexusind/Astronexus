import { Router } from "express";
import * as c from "../../controllers/admin/admin.cms.controller.js";
import { authenticateToken } from "../../middlewares/auth.js";
import admin from "../../middlewares/admin.middleware.js";

const router = Router();

router.use(authenticateToken, admin);

router.post("/", c.create);
router.get("/", c.getAll);
router.put("/:id", c.update);

export default router;
