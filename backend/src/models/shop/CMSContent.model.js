import mongoose from "mongoose";

const CMSContentSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ["banner", "horoscope", "blog", "announcement"],
    required: true
  },

  title: String,

  content: String,

  image: String,

  isActive: {
    type: Boolean,
    default: true
  }
}, { timestamps: true });

export default mongoose.model("CMSContent", CMSContentSchema);
