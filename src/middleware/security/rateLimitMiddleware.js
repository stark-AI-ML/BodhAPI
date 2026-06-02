/**
 * Rate Limiting Middleware
 * Prevents DDoS and brute force attacks
 */

const REQUEST_LIMITS = {
  WINDOW_TIME_MS: 15 * 60 * 1000, // 15 minutes
  MAX_REQUESTS: 10,
  CLEANUP_INTERVAL_MS: 60 * 1000, // Clean old entries every minute
};

// Store request counts per IP
const requestTracker = new Map();

/**
 * Cleanup expired entries periodically
 */
setInterval(() => {
  const now = Date.now();
  for (const [ip, data] of requestTracker.entries()) {
    if (now - data.firstRequestTime > REQUEST_LIMITS.WINDOW_TIME_MS) {
      requestTracker.delete(ip);
    }
  }
}, REQUEST_LIMITS.CLEANUP_INTERVAL_MS);

/**
 * Rate limiting middleware
 */
export const enforceRateLimit = (request, response, next) => {
  const clientIPAddress = request.ip || request.connection.remoteAddress;

  if (!requestTracker.has(clientIPAddress)) {
    requestTracker.set(clientIPAddress, {
      requestCount: 1,
      firstRequestTime: Date.now(),
    });
    return next();
  }

  const clientData = requestTracker.get(clientIPAddress);
  const timeSinceFirstRequest = Date.now() - clientData.firstRequestTime;

  // Reset window if expired
  if (timeSinceFirstRequest > REQUEST_LIMITS.WINDOW_TIME_MS) {
    clientData.requestCount = 1;
    clientData.firstRequestTime = Date.now();
    return next();
  }

  // Check limit
  if (clientData.requestCount >= REQUEST_LIMITS.MAX_REQUESTS) {
    return response.status(429).json({
      success: false,
      error: "Too many requests. Please try again later.",
      retryAfter: Math.ceil(
        (REQUEST_LIMITS.WINDOW_TIME_MS - timeSinceFirstRequest) / 1000,
      ),
    });
  }

  clientData.requestCount += 1;
  next();
};
