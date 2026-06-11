// configuration of all limits all apis

export const GENERAL_CONFIG = {
  LIMIT: {
    MIN: 1,
    MAX: 150,
    DEFAULT: 30,
  },

  STRING: {
    MAX: 500, // maybe more if we scale but who will search for more than 500 characters words for news
  },
};

const normalizeString = (input) => {
  return input.trim().replace(/\s+/g, ' ');
};

// validators ---

//limit
export const validateLimit = (limit) => {
  if (limit === undefined || limit === null) {
    return { ok: true, value: GENERAL_CONFIG.LIMIT.DEFAULT };
  }

  const parsed = Number(limit);

  if (!Number.isInteger(parsed)) {
    return { ok: false, error: 'Limit must be an integer' };
  }

  if (parsed < GENERAL_CONFIG.LIMIT.MIN) {
    return { ok: false, error: `Minimum limit is ${GENERAL_CONFIG.LIMIT.MIN}` };
  }

  if (parsed > GENERAL_CONFIG.LIMIT.MAX) {
    return { ok: false, error: `Maximum limit is ${GENERAL_CONFIG.LIMIT.MAX}` };
  }

  return { ok: true, value: parsed };
};

// String
export const validateString = (
  input,
  {
    required = false,
    minLength = 1,
    maxLength = GENERAL_CONFIG.STRING.MAX,
    pattern = null,
    fieldName = 'field',
  } = {}
) => {
  if (input === undefined || input === null || input === '') {
    if (required) {
      return { ok: false, error: `${fieldName} is required` };
    }
    return { ok: true, value: null };
  }

  if (typeof input !== 'string') {
    return { ok: false, error: `${fieldName} must be a string` };
  }

  // max limit
  if (input.length > maxLength) {
    return {
      ok: false,
      error: `${fieldName} cannot exceed ${maxLength} characters`,
    };
  }

  const clean = normalizeString(input);
  // minimum lenghth
  if (clean.length < minLength) {
    return {
      ok: false,
      error: `${fieldName} must be at least ${minLength} characters`,
    };
  }

  // valid pattern of the the string
  if (pattern && !pattern.test(clean)) {
    return {
      ok: false,
      error: `${fieldName} contains invalid characters`,
    };
  }

  return { ok: true, value: clean };
};

export const validateEnum = (
  input,
  allowedValues,
  { caseSensitive = false, fieldName = 'value' } = {}
) => {
  if (!input) {
    return { ok: false, error: `${fieldName} is required` };
  }

  if (typeof input !== 'string') {
    return { ok: false, error: `${fieldName} must be a string` };
  }

  const value = caseSensitive ? input : input.toLowerCase();
  const allowed = caseSensitive
    ? allowedValues
    : allowedValues.map((v) => v.toLowerCase());

  if (!allowed.includes(value)) {
    return {
      ok: false,
      error: `Invalid ${fieldName}. Allowed: ${allowedValues.join(', ')}`,
    };
  }

  return { ok: true, value };
};

export default {
  GENERAL_CONFIG,
  validateLimit,
  validateString,
  validateEnum,
};
