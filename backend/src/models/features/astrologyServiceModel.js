import mongoose from "mongoose";

const astrologyServiceSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    key: { type: String, required: true, unique: true },
    description: { type: String },
    enabled: { type: Boolean, default: true },
    isPremium: { type: Boolean, default: false }
  },
  { timestamps: true }
);

export default mongoose.model("AstrologyService", astrologyServiceSchema);