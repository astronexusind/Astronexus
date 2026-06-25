import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Look for .env in the current directory (src/config) AND in the backend root (../..)
dotenv.config({ path: path.join(__dirname, "../../.env") });

const config = {
  env: process.env.NODE_ENV || "development",
  port: process.env.PORT || 8001,
  mongodbUri: process.env.MONGODB_URI,
  groqApiKey: process.env.GROQ_API_KEY,
  jwtSecret: (() => {
  if (!process.env.JWT_SECRET) {
    throw new Error(
      "FATAL: JWT_SECRET is not set in environment variables. " +
      "Refusing to start with an insecure default. Set JWT_SECRET in your .env file."
    );
  }
  return process.env.JWT_SECRET;
})(),
  baseUrl: process.env.BASE_URL || `http://localhost:${process.env.PORT || 8001}`,
  // Add other env vars here
};

// Required environment variables validation
const requiredEnvVars = ["MONGODB_URI", "JWT_SECRET"];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.warn(`⚠️ Warning: Environment variable ${envVar} is missing!`);
  }
}

export default config;
