import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import Admin from "../../models/shop/admin.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { ApiError } from "../../utils/ApiError.js";

// ==========================
// 🔑 ADMIN LOGIN
// ==========================
export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const admin = await Admin.findOne({ email });
  if (!admin) {
    throw new ApiError(401, "Invalid admin credentials", ["Invalid admin credentials"]);
  }

  const isMatch = await bcrypt.compare(password, admin.password);
  if (!isMatch) {
    throw new ApiError(401, "Invalid admin credentials", ["Invalid admin credentials"]);
  }

  const token = jwt.sign(
    { id: admin._id, role: "admin" },
    process.env.JWT_SECRET,
    { expiresIn: "1d" }
  );

  res.status(200).json({
    success: true,
    message: "Login successful",
    token,
  });
});

// ==========================
// 🔧 CREATE ADMIN (WITH SETUP KEY)
// ==========================
export const createAdmin = asyncHandler(async (req, res) => {
  const { email, password, setupKey } = req.body;

  if (!setupKey || setupKey !== process.env.ADMIN_SETUP_KEY) {
    throw new ApiError(403, "Not authorized to create admin", ["Not authorized to create admin"]);
  }

  const existingAdmin = await Admin.findOne({ email });
  if (existingAdmin) {
    throw new ApiError(400, "Admin already exists", ["Admin already exists"]);
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const admin = await Admin.create({
    email,
    password: hashedPassword,
  });

  res.status(201).json({
    success: true,
    message: "Admin created successfully",
    admin: { id: admin._id, email: admin.email },
  });
});

// ==========================
// 🔁 UPDATE PASSWORD
// ==========================
export const updatePassword = asyncHandler(async (req, res) => {
  const { oldPassword, newPassword } = req.body;

  const admin = await Admin.findById(req.user.id);
  if (!admin) {
    throw new ApiError(404, "Admin not found", ["Admin not found"]);
  }

  const isMatch = await bcrypt.compare(oldPassword, admin.password);
  if (!isMatch) {
    throw new ApiError(401, "Old password is wrong", ["Old password is wrong"]);
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);
  admin.password = hashedPassword;
  await admin.save();

  res.status(200).json({
    success: true,
    message: "Password updated successfully",
  });
});

// 🔹 GET ALL ADMINS
export const getAllAdmins = asyncHandler(async (req, res) => {
  const admins = await Admin.find({}, { password: 0 }); // exclude passwords
  res.status(200).json({
    success: true,
    message: "Admins fetched successfully",
    admins
  });
});


// ==========================
// 🚪 LOGOUT
// ==========================
export const logout = asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    message: "Logout successful",
  });
});


