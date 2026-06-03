// Input sanitazation most important thing to learn -----

// I think sql injection pattern here is just a over kill and regex will take extra processing time for nothing like i have done paramatrized query so no issues
// but --- this whole project about building newsAPI + learning  so i will go with old faishon

const sanitizationRules = {
  MAX_STRING_LENGTH: 1000,
  MAX_ARRAY_LENGTH: 100,
  DANGEROUS_PATTERNS: {
    sqlInjection: /('|(--)|;|\/\*|\*\/|xp_|sp_)/gi,
    scriptInjection: /(<script|javascript:|onerror=|onload=)/gi,
    nosqlInjection: /(\$where|\$regex|\.\.\/)/gi,
  },
};

// remove dangerous strings from input first
const removeDangerousCharacters = (inputString) => {
  if (typeof inputString !== "string") {
    return inputString;
  }

  let sanitizedString = inputString;

  // Check length
  if (sanitizedString.length > sanitizationRules.MAX_STRING_LENGTH) {
    throw new Error(
      `Input exceeds maximum length of ${sanitizationRules.MAX_STRING_LENGTH}`,
    );
  }

  // Remove SQL injection patterns
  sanitizedString = sanitizedString.replace(
    sanitizationRules.DANGEROUS_PATTERNS.sqlInjection,
    "",
  );

  // Remove script injection patterns
  sanitizedString = sanitizedString.replace(
    sanitizationRules.DANGEROUS_PATTERNS.scriptInjection,
    "",
  );

  // Remove NoSQL injection patterns
  sanitizedString = sanitizedString.replace(
    sanitizationRules.DANGEROUS_PATTERNS.nosqlInjection,
    "",
  );

  // Normalize whitespace
  sanitizedString = sanitizedString.trim().replace(/\s+/g, " ");

  return sanitizedString;
};

/* recursive object depth check and arrayLength check --- serves no purpose to user this is for usecase to load the DB
 *  with ai generated json of news but as of now i am not directly doing it so if my ip get blocks i will do it manual so need to create an
 *  api for that
 */

const sanitizeObject = (inputObject, depth = 0) => {
  if (depth > 10) {
    throw new Error("Object nesting too deep");
  }

  if (Array.isArray(inputObject)) {
    if (inputObject.length > sanitizationRules.MAX_ARRAY_LENGTH) {
      throw new Error(
        `Array exceeds maximum length of ${sanitizationRules.MAX_ARRAY_LENGTH}`,
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
    // Sanitize query parameters (in-place — req.query is read-only in Express 5)
    if (request.query && Object.keys(request.query).length > 0) {
      const sanitizedQuery = sanitizeObject(request.query);
      for (const key of Object.keys(sanitizedQuery)) {
        request.query[key] = sanitizedQuery[key];
      }
    }

    // Sanitize request body
    if (request.body && Object.keys(request.body).length > 0) {
      const sanitizedBody = sanitizeObject(request.body);
      for (const key of Object.keys(sanitizedBody)) {
        request.body[key] = sanitizedBody[key];
      }
    }

    // Sanitize URL params (in-place — req.params is read-only in Express 5)
    if (request.params && Object.keys(request.params).length > 0) {
      const sanitizedParams = sanitizeObject(request.params);
      for (const key of Object.keys(sanitizedParams)) {
        request.params[key] = sanitizedParams[key];
      }
    }

    next();
  } catch (sanitizationError) {
    return response.status(400).json({
      success: false,
      error: sanitizationError.message || "Invalid input detected",
    });
  }
};
