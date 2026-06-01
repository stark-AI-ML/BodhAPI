import express from "express";
import { securityMiddleware } from "./middleware/general/securityValidation.js";
import { createValidationMiddleware } from "./middleware/general/generalValidation.js";
import generalRoutes from "./modules/v1/general/general.route.js";

const app = express();

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Security middleware (detect attacks, sanitize input)
app.use(securityMiddleware);

// General API routes
app.use("/api", generalRoutes);

app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "Server is running",
    timestamp: new Date().toISOString(),
  });
});

//error handle

// 404 Not Found handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
    path: req.originalUrl,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error("[ERROR]", err);

  const statusCode = err.statusCode || 500;
  const message = err.message || "Internal server error";

  res.status(statusCode).json({
    success: false,
    message,
    error: process.env.NODE_ENV === "development" ? err : undefined,
  });
});

export default app;
