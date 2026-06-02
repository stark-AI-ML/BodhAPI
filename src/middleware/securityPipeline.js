/**
 * Complete Security Middleware Pipeline
 * Order matters: Headers → Rate Limit → Sanitize → Validate
 */

import express from "express";
import { addSecurityHeaders } from "./security/securityHeadersMiddleware.js";
import { enforceRateLimit } from "./security/rateLimitMiddleware.js";
import { sanitizeAllInputs } from "./security/inputSanitizationMiddleware.js";

/**
 * Initialize all security middleware in correct order
 * This should be called in your app.js BEFORE route handlers
 */
export const initializeSecurityMiddleware = (expressApp) => {
  // 1. Add security headers first (applies to all responses)
  expressApp.use(addSecurityHeaders);

  // 2. Rate limiting (prevent abuse)
  expressApp.use(enforceRateLimit);

  // 3. Sanitize all inputs (remove dangerous characters)
  expressApp.use(sanitizeAllInputs);

  // 4. Body parser with size limits
  expressApp.use(
    express.json({
      limit: "10mb", // Prevent large payload attacks
    }),
  );

  expressApp.use(
    express.urlencoded({
      limit: "10mb",
      extended: true,
    }),
  );
};

// Export individual middleware for custom configurations
export { addSecurityHeaders, enforceRateLimit, sanitizeAllInputs };
