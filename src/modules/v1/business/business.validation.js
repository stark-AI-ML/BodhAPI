/**
 * Business Module Validations
 * Uses universal validations from middleware for security (same pattern as general module)
 * Includes business-specific validations (finance type, industry)
 *
 * Note: Converts new `ok` format to `isValid` for backward compatibility
 */

import {
  validateLimit,
  validateString,
  validateEnum,
} from "../../../middleware/general/generalValidation.js";

// Module-specific constants
const VALID_SENTIMENTS = ["POSITIVE", "NEGATIVE", "NEUTRAL"];

/**
 * Helper: Convert new validation format (ok) to old format (isValid)
 */
const convertFormat = (validation) => {
  return {
    isValid: validation.ok,
    value: validation.value,
    error: validation.error,
  };
};


export const validateSentiment = (sentiment, defaultValue = "Positive") => {
  if (!sentiment) {
    return { isValid: true, value: defaultValue };
  }

  const result = validateEnum(sentiment, VALID_SENTIMENTS, {
    caseSensitive: false,
    fieldName: "sentiment",
  });

  if (!result.ok) {
    return convertFormat(result);
  }

  // Capitalize first letter to match DB enum (Positive, Neutral, Negative)
  const normalized =
    result.value.charAt(0).toUpperCase() + result.value.slice(1).toLowerCase();

  return { isValid: true, value: normalized };
};

/**
 * Validate state name with security checks
 */
export const validateState = (state) => {
  const result = validateString(state, {
    required: true,
    minLength: 2,
    maxLength: 100,
    fieldName: "state",
  });
  return convertFormat(result);
};

/**
 * Validate today news request
 */
export const validateTodayNews = (req) => {
  const limitValidation = validateLimit(req.query.limit);
  return convertFormat(limitValidation);
};

/**
 * Validate top news request
 */
export const validateTopNews = (req) => {
  const limitValidation = validateLimit(req.query.limit);
  return convertFormat(limitValidation);
};

/**
 * Validate tech news request
 */
export const validateTechNews = (req) => {
  const limitValidation = validateLimit(req.query.limit);
  return convertFormat(limitValidation);
};

/**
 * Validate finance news request
 */
export const validateFinanceNews = (req) => {
  const limitValidation = validateLimit(req.query.limit);
  const limitConverted = convertFormat(limitValidation);

  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    limit: limitConverted.value,
  };
};

/**
 * Validate sentiment news request
 */
export const validateSentimentNews = (req) => {
  const sentimentValidation = validateSentiment(req.query.sentiment);
  if (!sentimentValidation.isValid) {
    return sentimentValidation;
  }

  const limitValidation = validateLimit(req.query.limit);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    sentiment: sentimentValidation.value,
    limit: limitConverted.value,
  };
};

/**
 * Validate state news request
 */
export const validateStateNews = (req) => {
  const stateValidation = validateState(req.query.state);
  if (!stateValidation.isValid) {
    return stateValidation;
  }

  const limitValidation = validateLimit(req.query.limit);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    state: stateValidation.value,
    limit: limitConverted.value,
  };
};
