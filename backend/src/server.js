import config from "./config/index.js";
import app from "./app.js";
import connectDB from "./config/database.js";
import { startUnifiedInternalServices } from "./service/unifiedServiceLauncher.js";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = config.port;

// ================= INTERNAL SERVICE LAUNCHER =================
startUnifiedInternalServices({ backendDir: path.join(__dirname, ".") });

// ================= DATABASE =================
const shouldSkipDb = String(process.env.SKIP_DB || "").toLowerCase() === "true";

const startServer = async () => {
  try {
    if (!shouldSkipDb) {
      await connectDB();
    } else {
      console.log("SKIP_DB=true -> skipping MongoDB connection");
    }

    const server = app.listen(PORT, "0.0.0.0", () => {
      console.log(`🚀 Server running on port ${PORT}`);
    });

    // Handle Graceful Shutdown
    const shutdown = () => {
      console.log("Stopping server...");
      server.close(() => {
        console.log("Server stopped.");
        process.exit(0);
      });
    };

    process.on("SIGTERM", shutdown);
    process.on("SIGINT", shutdown);

  } catch (error) {
    console.error(`Error starting server: ${error.message}`);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on("unhandledRejection", (err) => {
  console.error("UNHANDLED REJECTION! 💥 Shutting down...");
  console.error(err.name, err.message);
  process.exit(1);
});

// Handle uncaught exceptions
process.on("uncaughtException", (err) => {
  console.error("UNCAUGHT EXCEPTION! 💥 Shutting down...");
  console.error(err.name, err.message);
  process.exit(1);
});

startServer();
