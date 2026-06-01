/**
 * Fast + Predictable Security Middleware
 * Strategy: LIMIT → VALIDATE → ATTACH CLEAN DATA
 */

const LIMITS = {
  MAX_STRING: 2000,
};

// Field-based validation rules (customize per API)
const FIELD_RULES = {
  page: /^[0-9]+$/,
  limit: /^[0-9]+$/,
  email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  search: /^[a-zA-Z0-9\s._-]*$/,
  id: /^[0-9]+$/,
};

/**
 * Validate a single value using allow-list
 */
const validateField = (key, value) => {
  if (typeof value !== "string") return value;

  // 1. Hard length check (fastest)
  if (value.length > LIMITS.MAX_STRING) {
    throw new Error("Input too long");
  }

  // 2. Normalize
  const clean = value.trim().replace(/\s+/g, " ");

  // 3. Apply rule if exists
  const rule = FIELD_RULES[key];
  if (rule && !rule.test(clean)) {
    throw new Error(`Invalid format for ${key}`);
  }

  return clean;
};

/**
 * Sanitize + validate query
 */
const sanitizeQuery = (query) => {
  const result = {};

  for (const [key, value] of Object.entries(query)) {
    if (Array.isArray(value)) {
      result[key] = value.map((v) => validateField(key, v));
    } else {
      result[key] = validateField(key, value);
    }
  }

  return result;
};

/**
 * Middleware
 */
export const securityMiddleware = (req, res, next) => {
  try {
    const cleanQuery = sanitizeQuery(req.query);

    // attach safe version
    req.cleanQuery = cleanQuery;

    next();
  } catch (err) {
    return res.status(400).json({
      success: false,
      error: err.message || "Invalid input",
    });
  }
};
