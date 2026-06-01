/**
 * General Module Validations
 * Uses universal validations from middleware for security
 * Includes module-specific validations (severity, sentiment, state, entities)
 *
 * Note: Converts new `ok` format to `isValid` for backward compatibility
 */

import {
  validateLimit,
  validateString,
  validateEnum,
} from "../../../middleware/general/generalValidation.js";

// Module-specific constants
const VALID_CRIME_SEVERITIES = ["LOW", "MEDIUM", "HIGH", "EXTREME"];
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

/**
 * Validate crime severity
 * @param {string} severity - Severity level to validate
 * @returns {object} { isValid: boolean, value: string, error: string }
 */
export const validateCrimeSeverity = (severity) => {
  const result = validateEnum(severity, VALID_CRIME_SEVERITIES, {
    caseSensitive: false,
    fieldName: "crime severity",
  });
  return convertFormat(result);
};

/**
 * Validate sentiment
 * @param {string} sentiment - Sentiment to validate
 * @param {string} defaultValue - Default value if not provided
 * @returns {object} { isValid: boolean, value: string, error: string }
 */
export const validateSentiment = (sentiment, defaultValue = "POSITIVE") => {
  if (!sentiment) {
    return { isValid: true, value: defaultValue };
  }

  const result = validateEnum(sentiment, VALID_SENTIMENTS, {
    caseSensitive: false,
    fieldName: "sentiment",
  });
  return convertFormat(result);
};

/**
 * Validate state name with security checks
 * @param {string} state - State name to validate
 * @returns {object} { isValid: boolean, value: string, error: string }
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
 * Validate entity name (person or organization) with security checks
 * @param {string} entity - Entity name to validate
 * @returns {object} { isValid: boolean, value: string, error: string }
 */
export const validateEntity = (entity) => {
  const result = validateString(entity, {
    required: false,
    minLength: 1,
    maxLength: 200,
    fieldName: "entity",
  });
  return convertFormat(result);
};

/**
 * Validate entities (at least one must be provided)
 * @param {string} person - Person name
 * @param {string} organization - Organization name
 * @returns {object} { isValid: boolean, person: string, organization: string, error: string }
 */
export const validateEntities = (person, organization) => {
  if (!person && !organization) {
    return {
      isValid: false,
      error: "At least one entity (person or organization) is required",
    };
  }

  const personValidation = validateEntity(person);
  if (!personValidation.isValid) {
    return personValidation;
  }

  const orgValidation = validateEntity(organization);
  if (!orgValidation.isValid) {
    return orgValidation;
  }

  return {
    isValid: true,
    person: personValidation.value,
    organization: orgValidation.value,
  };
};

/**
 * Validate today news request
 */
export const validateTodayNews = (req) => {
  const limitValidation = validateLimit(req.query.limit, 60);
  return convertFormat(limitValidation);
};

/**
 * Validate top news request
 */
export const validateTopNews = (req) => {
  const limitValidation = validateLimit(req.query.limit, 40);
  return convertFormat(limitValidation);
};

/**
 * Validate crime news request
 */
export const validateCrimeNews = (req) => {
  const severityValidation = validateCrimeSeverity(req.query.severity);
  if (!severityValidation.isValid) {
    return severityValidation;
  }

  const limitValidation = validateLimit(req.query.limit, 30);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    severity: severityValidation.value,
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

  const limitValidation = validateLimit(req.query.limit, 30);
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

  const limitValidation = validateLimit(req.query.limit, 30);
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

/**
 * Validate entities news request
 */
export const validateEntitiesNews = (req) => {
  const entitiesValidation = validateEntities(
    req.query.person,
    req.query.organization,
  );
  if (!entitiesValidation.isValid) {
    return entitiesValidation;
  }

  const limitValidation = validateLimit(req.query.limit, 30);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    person: entitiesValidation.person,
    organization: entitiesValidation.organization,
    limit: limitConverted.value,
  };
};
