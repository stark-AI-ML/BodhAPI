import {
  validateLimit,
  validateString,
  validateEnum,
} from "../../../middleware/general/generalValidation.js";

// Module-specific constants (must match DB enums from schema.sql)
const VALID_CRIME_SEVERITIES = ["NONE", "LOW", "MODERATE", "EXTREME"];
const VALID_SENTIMENTS = ["Positive", "Negative", "Neutral"];
const VALID_EMERGENCY_TYPES = [
  "PUBLIC_HEALTH",
  "NATURAL_DISASTER",
  "WAR_CONFLICT",
  "CIVIL_UNREST",
];
const VALID_CATEGORIES = [
  "Economy",
  "Infrastructure",
  "Politics",
  "Crime",
  "Science",
  "Geopolitics",
  "Emergency",
];

const convertFormat = (validation) => {
  return {
    isValid: validation.ok,
    value: validation.value,
    error: validation.error,
  };
};

export const validateCrimeSeverity = (severity) => {
  const result = validateEnum(severity, VALID_CRIME_SEVERITIES, {
    caseSensitive: false,
    fieldName: "crime severity",
  });

  if (!result.ok) {
    return convertFormat(result);
  }

  // Uppercase to match DB enum
  return { isValid: true, value: result.value.toUpperCase() };
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

  const normalized =
    result.value.charAt(0).toUpperCase() + result.value.slice(1).toLowerCase(); // positive to Postive
  return { isValid: true, value: normalized };
};

export const validateEmergencyType = (emergencyType) => {
  const result = validateEnum(emergencyType, VALID_EMERGENCY_TYPES, {
    caseSensitive: false,
    fieldName: "emergency type",
  });

  if (!result.ok) {
    return convertFormat(result);
  }

  return { isValid: true, value: result.value.toUpperCase() };
};

export const validateCategory = (category) => {
  const result = validateEnum(category, VALID_CATEGORIES, {
    caseSensitive: false,
    fieldName: "category",
  });

  if (!result.ok) {
    return convertFormat(result);
  }

  const normalized =
    result.value.charAt(0).toUpperCase() + result.value.slice(1).toLowerCase();
  return { isValid: true, value: normalized };
};

export const validateSearchQuery = (query) => {
  const result = validateString(query, {
    required: true,
    minLength: 2,
    maxLength: 200,
    fieldName: "search query",
  });
  return convertFormat(result);
};

export const validateTag = (tag) => {
  const result = validateString(tag, {
    required: true,
    minLength: 1,
    maxLength: 100,
    fieldName: "tag",
  });
  return convertFormat(result);
};

export const validateState = (state) => {
  const result = validateString(state, {
    required: true,
    minLength: 2,
    maxLength: 100,
    fieldName: "state",
  });
  return convertFormat(result);
};

export const validateEntity = (entity) => {
  const result = validateString(entity, {
    required: false,
    minLength: 1,
    maxLength: 200,
    fieldName: "entity",
  });
  return convertFormat(result);
};

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

export const validateTodayNews = (req) => {
  const limitValidation = validateLimit(req.query.limit, 60);
  return convertFormat(limitValidation);
};

export const validateTopNews = (req) => {
  const limitValidation = validateLimit(req.query.limit, 40);
  return convertFormat(limitValidation);
};

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

export const validateEmergencyNews = (req) => {
  const emergencyValidation = validateEmergencyType(req.query.type);
  if (!emergencyValidation.isValid) {
    return emergencyValidation;
  }

  const limitValidation = validateLimit(req.query.limit, 30);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    emergencyType: emergencyValidation.value,
    limit: limitConverted.value,
  };
};

export const validateCategoryNews = (req) => {
  const categoryValidation = validateCategory(req.query.category);
  if (!categoryValidation.isValid) {
    return categoryValidation;
  }

  const limitValidation = validateLimit(req.query.limit, 30);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    category: categoryValidation.value,
    limit: limitConverted.value,
  };
};

export const validateSearchNews = (req) => {
  const searchValidation = validateSearchQuery(req.query.q);
  if (!searchValidation.isValid) {
    return searchValidation;
  }

  const limitValidation = validateLimit(req.query.limit, 30);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    query: searchValidation.value,
    limit: limitConverted.value,
  };
};

export const validateTagsNews = (req) => {
  const tagValidation = validateTag(req.query.tag);
  if (!tagValidation.isValid) {
    return tagValidation;
  }

  const limitValidation = validateLimit(req.query.limit, 30);
  const limitConverted = convertFormat(limitValidation);
  if (!limitConverted.isValid) {
    return limitConverted;
  }

  return {
    isValid: true,
    tag: tagValidation.value,
    limit: limitConverted.value,
  };
};
