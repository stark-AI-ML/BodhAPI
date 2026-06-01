/**

* =========================================================
* GENERAL VALIDATION MODULE (Optimized)
* * Fast (minimal regex usage)
* * Predictable (allow-list based)
* * Reusable across modules
* =========================================================
  */

// ============================================
// CONFIG
// ============================================

export const GENERAL_CONFIG = {
  LIMIT: {
    MIN: 1,
    MAX: 500,
    DEFAULT: 30,
  },

  STRING: {
    MAX: 2000,
  },
};

// ============================================
// CORE HELPERS
// ============================================

const normalizeString = (input) => {
  return input.trim().replace(/\s+/g, " ");
};

// ============================================
// VALIDATORS
// ============================================

/**

* Validate limit (pagination)
  */
export const validateLimit = (limit) => {
  if (limit === undefined || limit === null) {
    return { ok: true, value: GENERAL_CONFIG.LIMIT.DEFAULT };
  }

  const parsed = Number(limit);

  if (!Number.isInteger(parsed)) {
    return { ok: false, error: "Limit must be an integer" };
  }

  if (parsed < GENERAL_CONFIG.LIMIT.MIN) {
    return { ok: false, error: `Minimum limit is ${GENERAL_CONFIG.LIMIT.MIN}` };
  }

  if (parsed > GENERAL_CONFIG.LIMIT.MAX) {
    return { ok: false, error: `Maximum limit is ${GENERAL_CONFIG.LIMIT.MAX}` };
  }

  return { ok: true, value: parsed };
};

/**

* Validate string (allow-list driven)
  */
export const validateString = (
  input,
  {
    required = false,
    minLength = 1,
    maxLength = GENERAL_CONFIG.STRING.MAX,
    pattern = null,
    fieldName = "field",
  } = {},
) => {
  if (input === undefined || input === null || input === "") {
    if (required) {
      return { ok: false, error: `${fieldName} is required` };
    }
    return { ok: true, value: null };
  }

  if (typeof input !== "string") {
    return { ok: false, error: `${fieldName} must be a string` };
  }

  // Hard limit (fastest check)
  if (input.length > maxLength) {
    return {
      ok: false,
      error: `${fieldName} cannot exceed ${maxLength} characters`,
    };
  }

  const clean = normalizeString(input);

  if (clean.length < minLength) {
    return {
      ok: false,
      error: `${fieldName} must be at least ${minLength} characters`,
    };
  }

  // Allow-list validation
  if (pattern && !pattern.test(clean)) {
    return {
      ok: false,
      error: `${fieldName} contains invalid characters`,
    };
  }

  return { ok: true, value: clean };
};

/**

* Validate integer
  */
export const validateInteger = (
  input,
  { required = false, min = 0, max = 999999, fieldName = "value" } = {},
) => {
  if (input === undefined || input === null || input === "") {
    if (required) {
      return { ok: false, error: `${fieldName} is required` };
    }
    return { ok: true, value: null };
  }

  const parsed = Number(input);

  if (!Number.isInteger(parsed)) {
    return { ok: false, error: `${fieldName} must be an integer` };
  }

  if (parsed < min) {
    return { ok: false, error: `${fieldName} must be ≥ ${min}` };
  }

  if (parsed > max) {
    return { ok: false, error: `${fieldName} must be ≤ ${max}` };
  }

  return { ok: true, value: parsed };
};

/**

* Validate enum
  */
export const validateEnum = (
  input,
  allowedValues,
  { caseSensitive = false, fieldName = "value" } = {},
) => {
  if (!input) {
    return { ok: false, error: `${fieldName} is required` };
  }

  if (typeof input !== "string") {
    return { ok: false, error: `${fieldName} must be a string` };
  }

  const value = caseSensitive ? input : input.toLowerCase();
  const allowed = caseSensitive
    ? allowedValues
    : allowedValues.map((v) => v.toLowerCase());

  if (!allowed.includes(value)) {
    return {
      ok: false,
      error: `Invalid ${fieldName}. Allowed: ${allowedValues.join(", ")}`,
    };
  }

  return { ok: true, value };
};

// ============================================
// MIDDLEWARE FACTORY
// ============================================

/**

* Create validation middleware
* Example usage:
* createValidationMiddleware((req) => ({
* limit: validateLimit(req.query.limit),
* search: validateString(req.query.search, { pattern: SAFE_STRING })
* }))
  */
export const createValidationMiddleware = (schemaFn) => {
  return (req, res, next) => {
    const result = schemaFn(req);
    const errors = {};
    const values = {};

    for (const [key, validation] of Object.entries(result)) {
      if (!validation.ok) {
        errors[key] = validation.error;
      } else {
        values[key] = validation.value;
      }
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        success: false,
        errors,
      });
    }

    req.validated = values;
    next();
  };
};

export default {
  GENERAL_CONFIG,
  validateLimit,
  validateString,
  validateInteger,
  validateEnum,
  createValidationMiddleware,
};
