/**
 * Input Sanitization Middleware
 * Removes dangerous characters and prevents injection attacks
 */

const SANITIZATION_RULES = {
  MAX_STRING_LENGTH: 1000,
  MAX_ARRAY_LENGTH: 100,
  DANGEROUS_PATTERNS: {
    sqlInjection: /('|(--)|;|\/\*|\*\/|xp_|sp_)/gi,
    scriptInjection: /(<script|javascript:|onerror=|onload=)/gi,
    nosqlInjection: /(\$where|\$regex|\.\.\/)/gi,
  },
};

/**
 * Remove dangerous characters from strings
 */
const removeDangerousCharacters = (inputString) => {
  if (typeof inputString !== "string") {
    return inputString;
  }

  let sanitizedString = inputString;

  // Check length
  if (sanitizedString.length > SANITIZATION_RULES.MAX_STRING_LENGTH) {
    throw new Error(
      `Input exceeds maximum length of ${SANITIZATION_RULES.MAX_STRING_LENGTH}`,
    );
  }

  // Remove SQL injection patterns
  sanitizedString = sanitizedString.replace(
    SANITIZATION_RULES.DANGEROUS_PATTERNS.sqlInjection,
    "",
  );

  // Remove script injection patterns
  sanitizedString = sanitizedString.replace(
    SANITIZATION_RULES.DANGEROUS_PATTERNS.scriptInjection,
    "",
  );

  // Remove NoSQL injection patterns
  sanitizedString = sanitizedString.replace(
    SANITIZATION_RULES.DANGEROUS_PATTERNS.nosqlInjection,
    "",
  );

  // Normalize whitespace
  sanitizedString = sanitizedString.trim().replace(/\s+/g, " ");

  return sanitizedString;
};

/**
 * Recursively sanitize object
 */
const sanitizeObject = (inputObject, depth = 0) => {
  if (depth > 10) {
    throw new Error("Object nesting too deep");
  }

  if (Array.isArray(inputObject)) {
    if (inputObject.length > SANITIZATION_RULES.MAX_ARRAY_LENGTH) {
      throw new Error(
        `Array exceeds maximum length of ${SANITIZATION_RULES.MAX_ARRAY_LENGTH}`,
      );
    }
    return inputObject.map((item) => sanitizeObject(item, depth + 1));
  }

  if (typeof inputObject === "object" && inputObject !== null) {
    const sanitizedObject = {};
    for (const [key, value] of Object.entries(inputObject)) {
      sanitizedObject[key] = sanitizeObject(value, depth + 1);
    }
    return sanitizedObject;
  }

  if (typeof inputObject === "string") {
    return removeDangerousCharacters(inputObject);
  }

  return inputObject;
};

/**
 * Sanitization middleware
 */
export const sanitizeAllInputs = (request, response, next) => {
  try {
    // Sanitize query parameters
    if (Object.keys(request.query).length > 0) {
      request.query = sanitizeObject(request.query);
    }

    // Sanitize request body
    if (request.body && Object.keys(request.body).length > 0) {
      request.body = sanitizeObject(request.body);
    }

    // Sanitize URL params
    if (request.params && Object.keys(request.params).length > 0) {
      request.params = sanitizeObject(request.params);
    }

    next();
  } catch (sanitizationError) {
    return response.status(400).json({
      success: false,
      error: sanitizationError.message || "Invalid input detected",
    });
  }
};
