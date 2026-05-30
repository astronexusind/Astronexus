import mongoose from "mongoose";

mongoose.set("strictQuery", true);

const connectDB = async () => {
  const url = process.env.MONGODB_URI;
  if (!url) {
    console.error("❌ MONGODB_URI is not defined in .env");
    process.exit(1);
  }

  try {
    const conn = await mongoose.connect(url);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    process.exit(1);
  }
};

export default connectDB;
