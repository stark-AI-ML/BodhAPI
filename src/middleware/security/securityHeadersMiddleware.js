/**
 * Security Headers Middleware
 * Adds essential HTTP security headers to protect against common attacks
 */

/**
 * Add security headers middleware
 */
export const addSecurityHeaders = (request, response, next) => {
  // Prevent clickjacking attacks
  response.setHeader("X-Frame-Options", "DENY");

  // Prevent MIME sniffing
  response.setHeader("X-Content-Type-Options", "nosniff");

  // Enable XSS filtering in older browsers
  response.setHeader("X-XSS-Protection", "1; mode=block");

  // Prevent referrer information leakage
  response.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");

  // Content Security Policy - restrict resource loading
  response.setHeader(
    "Content-Security-Policy",
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self';",
  );

  // Strict Transport Security (enable HTTPS only)
  response.setHeader(
    "Strict-Transport-Security",
    "max-age=31536000; includeSubDomains",
  );

  // Disable client-side caching for sensitive data
  response.setHeader(
    "Cache-Control",
    "no-store, no-cache, must-revalidate, proxy-revalidate",
  );
  response.setHeader("Pragma", "no-cache");
  response.setHeader("Expires", "0");

  next();
};
