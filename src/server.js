/**
 * Express Server Entry Point
 * Starts the HTTP server and handles graceful shutdown
 */

import app from "./app.js";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

// ============================================
// SERVER CONFIGURATION
// ============================================

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || "localhost";

// ============================================
// START SERVER
// ============================================

const server = app.listen(PORT, HOST, () => {
  console.log(`
╔════════════════════════════════════════════╗
║          BodhAPI Server Started             ║
╚════════════════════════════════════════════╝
  
  🚀 Server:  http://${HOST}:${PORT}
  📝 Environment: ${process.env.NODE_ENV || "development"}
  🔐 Security: Enabled
  
═══════════════════════════════════════════════
  `);
});

// ============================================
// GRACEFUL SHUTDOWN
// ============================================

/**
 * Handle graceful shutdown on SIGTERM or SIGINT
 */
const gracefulShutdown = (signal) => {
  console.log(`\n🛑 ${signal} received, shutting down gracefully...`);

  server.close(() => {
    console.log("✅ Server closed successfully");
    process.exit(0);
  });

  // Force shutdown after 10 seconds if graceful shutdown fails
  setTimeout(() => {
    console.error("❌ Forcing shutdown after timeout");
    process.exit(1);
  }, 10000);
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

/**
 * Unhandled promise rejection handler
 */
process.on("unhandledRejection", (reason, promise) => {
  console.error("❌ Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});

/**
 * Uncaught exception handler
 */
process.on("uncaughtException", (error) => {
  console.error("❌ Uncaught Exception:", error);
  process.exit(1);
});

export default server;
