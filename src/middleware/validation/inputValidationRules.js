/**
 * Input Validation Middleware
 * Validates data format, type, and content against defined rules
 */

const FIELD_VALIDATION_RULES = {
  // Pagination
  pageNumber: {
    type: 'integer',
    min: 1,
    max: 10000,
    fieldName: 'Page number',
  },
  itemsPerPage: {
    type: 'integer',
    min: 1,
    max: 500,
    default: 10,
    fieldName: 'Items per page',
  },

  // Email
  emailAddress: {
    type: 'string',
    pattern: /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/,
    maxLength: 254,
    fieldName: 'Email address',
  },

  // Text search
  searchQuery: {
    type: 'string',
    pattern: /^[a-zA-Z0-9\s._\-'&]*$/,
    maxLength: 200,
    minLength: 1,
    fieldName: 'Search query',
  },

  // Database ID
  numericId: {
    type: 'integer',
    min: 1,
    max: 9999999,
    fieldName: 'ID',
  },

  // Username/handle
  userName: {
    type: 'string',
    pattern: /^[a-zA-Z0-9_\-]{3,30}$/,
    fieldName: 'Username',
  },

  // Generic text
  textContent: {
    type: 'string',
    maxLength: 5000,
    minLength: 1,
    fieldName: 'Text content',
  },
};

// Validate single field value

const validateFieldValue = (fieldValue, validationRule) => {
  const {
    type,
    required = false,
    min,
    max,
    pattern,
    maxLength,
    minLength,
    default: defaultValue,
    fieldName,
  } = validationRule;

  // Handle missing value
  if (fieldValue === undefined || fieldValue === null || fieldValue === '') {
    if (required) {
      return {
        isValid: false,
        errorMessage: `${fieldName} is required`,
      };
    }
    return {
      isValid: true,
      validatedValue: defaultValue || null,
    };
  }

  // Type validation
  if (type === 'integer') {
    const parsedNumber = parseInt(fieldValue, 10);
    if (isNaN(parsedNumber)) {
      return {
        isValid: false,
        errorMessage: `${fieldName} must be a number`,
      };
    }

    if (min !== undefined && parsedNumber < min) {
      return {
        isValid: false,
        errorMessage: `${fieldName} must be at least ${min}`,
      };
    }

    if (max !== undefined && parsedNumber > max) {
      return {
        isValid: false,
        errorMessage: `${fieldName} must be at most ${max}`,
      };
    }

    return {
      isValid: true,
      validatedValue: parsedNumber,
    };
  }

  if (type === 'string') {
    if (typeof fieldValue !== 'string') {
      return {
        isValid: false,
        errorMessage: `${fieldName} must be text`,
      };
    }

    const cleanedValue = fieldValue.trim().replace(/\s+/g, ' ');

    if (minLength !== undefined && cleanedValue.length < minLength) {
      return {
        isValid: false,
        errorMessage: `${fieldName} must be at least ${minLength} characters`,
      };
    }

    if (maxLength !== undefined && cleanedValue.length > maxLength) {
      return {
        isValid: false,
        errorMessage: `${fieldName} must not exceed ${maxLength} characters`,
      };
    }

    if (pattern && !pattern.test(cleanedValue)) {
      return {
        isValid: false,
        errorMessage: `${fieldName} contains invalid characters or format`,
      };
    }

    return {
      isValid: true,
      validatedValue: cleanedValue,
    };
  }

  return {
    isValid: true,
    validatedValue: fieldValue,
  };
};

/**
 * Validate query parameters against rules
 */
export const validateQueryParameters = (queryObject, rulesMapping) => {
  const validatedData = {};
  const validationErrors = [];

  for (const [fieldKey, fieldValue] of Object.entries(queryObject)) {
    const validationRule = rulesMapping[fieldKey];

    if (!validationRule) {
      // Skip unknown fields
      continue;
    }

    const validationResult = validateFieldValue(fieldValue, validationRule);

    if (!validationResult.isValid) {
      validationErrors.push(validationResult.errorMessage);
    } else {
      validatedData[fieldKey] = validationResult.validatedValue;
    }
  }

  return {
    hasErrors: validationErrors.length > 0,
    errors: validationErrors,
    validatedData,
  };
};

/**
 * Export validation rules for reuse
 */

export { FIELD_VALIDATION_RULES };
