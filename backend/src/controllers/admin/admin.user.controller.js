import User from "../../models/user/user.js";
import bcrypt from "bcryptjs";
import validator from "validator";
import BirthChart from "../../models/features/birthChartModel.js";
import { asyncHandler } from "../../utils/asyncHandler.js";
import { ApiError } from "../../utils/ApiError.js";
import { ApiResponse } from "../../utils/ApiResponse.js";

const normalizeChartId = (value) => {
  if (!value) return null;
  if (typeof value === "string") return value.trim() || null;
  if (typeof value === "object") {
    if (typeof value._id === "string") return value._id.trim() || null;
    if (typeof value.id === "string") return value.id.trim() || null;
  }
  return null;
};

/**
 * GET /api/admin/users
 */
export const getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select("-password");
    res.json(users);
  } catch (err) {
    console.error("GET USERS ERROR:", err);
    res.status(500).json({ error: err.message });
  }
};

export const createUserByAdmin = async (req, res) => {
  try {
    const { name, email, phone, password, role = "user" } = req.body;

    if (!name || !email || !phone || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    const exists = await User.findOne({ email });
    if (exists) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      email,
      phone,
      password: hashedPassword,
      role,
    });

    res.status(201).json({
      success: true,
      message: "User created successfully",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const createAstrologyUserByAdmin = asyncHandler(async (req, res) => {
  const {
    name,
    phone,
    password,
    confirmPassword,
    email,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    tempChartId,
    chartId,
    birthChartId,
  } = req.body;

  const resolvedChartId = normalizeChartId(tempChartId)
    || normalizeChartId(chartId)
    || normalizeChartId(birthChartId)
    || normalizeChartId(req.body?.birthChart)
    || normalizeChartId(req.body?.chart);

  if (!name || !phone || !password || !confirmPassword || !dateOfBirth || !timeOfBirth || !placeOfBirth) {
    throw new ApiError(400, "Missing required fields", ["name, phone, password, confirmPassword, dateOfBirth, timeOfBirth and placeOfBirth are required"]);
  }

  if (!validator.isMobilePhone(phone, "any")) {
    throw new ApiError(400, "Invalid phone number", ["Invalid phone number"]);
  }

  if (email && !validator.isEmail(email)) {
    throw new ApiError(400, "Invalid email format", ["Invalid email format"]);
  }

  if (password.length < 6) {
    throw new ApiError(400, "Password must be at least 6 characters", ["Password must be at least 6 characters"]);
  }

  if (password !== confirmPassword) {
    throw new ApiError(400, "Passwords do not match", ["Passwords do not match"]);
  }

  const existingUser = await User.findOne({
    $or: [
      { phone },
      ...(email ? [{ email }] : []),
    ],
  });

  if (existingUser) {
    throw new ApiError(400, "User already exists", ["User already exists"]);
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await User.create({
    name,
    phone,
    email,
    password: hashedPassword,
    role: "user",
    astrologyProfile: {
      dateOfBirth,
      timeOfBirth,
      placeOfBirth,
    },
  });

  let linkedBirthChart = null;
  if (resolvedChartId && validator.isMongoId(resolvedChartId)) {
    linkedBirthChart = await BirthChart.findById(resolvedChartId);

    if (linkedBirthChart) {
      linkedBirthChart.userId = user._id;
      linkedBirthChart.isTemporary = false;
      await linkedBirthChart.save();
    }
  }

  res.status(201).json(
    new ApiResponse(201, {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        sessionId: user.sessionId,
        astrologyProfile: user.astrologyProfile,
      },
      birthChart: linkedBirthChart
        ? {
            id: linkedBirthChart._id,
            chartImage: linkedBirthChart.chartImage,
            chartData: linkedBirthChart.chartData,
            rashi: linkedBirthChart.rashi,
            isTemporary: linkedBirthChart.isTemporary,
          }
        : null,
    }, "Astrology user created successfully")
  );
});


export const toggleUserBlock = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user || user.role === "admin") {
      return res.status(403).json({ message: "Action not allowed" });
    }

    user.isBlocked = !user.isBlocked;
    await user.save();

    res.json({ success: true, isBlocked: user.isBlocked });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

export const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user || user.role === "admin") {
      return res.status(403).json({ message: "Action not allowed" });
    }

    await User.findByIdAndDelete(req.params.id);

    res.json({ success: true, message: "User deleted successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
