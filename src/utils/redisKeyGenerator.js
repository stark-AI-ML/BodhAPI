/**
 * Redis Key Generator for News Service
 *
 * Pattern: serviceName_queryType_[dynamicParams]_limit
 * Examples:
 * - general_today_60
 * - general_top_40
 * - general_crime_EXTREME_30
 * - general_sentiment_POSITIVE_30
 * - general_state_Maharashtra_30
 * - general_entities_AmitShah_any_30
 */

class RedisKeyGenerator {
  /**
   * Generate a Redis key based on service name, query type, and parameters
   * @param {string} serviceName - Service name (general, business, socials)
   * @param {string} queryType - Query type (today, top, crime, sentiment, entities, state)
   * @param {number} limit - Result limit
   * @param {object} params - Additional parameters specific to query type
   * @returns {string} Generated Redis key
   */
  static generate(serviceName, queryType, limit = 30, params = {}) {
    const keyParts = [serviceName, queryType];

    // Add dynamic parameters based on query type
    switch (queryType) {
      case "crime":
        if (params.severity) {
          keyParts.push(params.severity.toUpperCase());
        }
        break;

      case "sentiment":
        const sentiment = params.sentiment || "POSITIVE";
        keyParts.push(sentiment.toUpperCase());
        break;

      case "state":
        if (params.state) {
          keyParts.push(params.state.replace(/\s+/g, "_")); // Replace spaces with underscores
        }
        break;

      case "entities":
        const person = params.person
          ? params.person.replace(/\s+/g, "_")
          : "any";
        const organization = params.organization
          ? params.organization.replace(/\s+/g, "_")
          : "any";
        keyParts.push(person);
        keyParts.push(organization);
        break;

      case "today":
      case "top":
      default:
        // No additional params needed for today and top
        break;
    }

    // Add limit as the last part
    keyParts.push(limit);

    return keyParts.join("_");
  }

  /**
   * Generate key for today's news
   */
  static todayKey(serviceName, limit = 60) {
    return this.generate(serviceName, "today", limit);
  }

  /**
   * Generate key for top news
   */
  static topKey(serviceName, limit = 40) {
    return this.generate(serviceName, "top", limit);
  }

  /**
   * Generate key for crime news
   */
  static crimeKey(serviceName, severity, limit = 30) {
    return this.generate(serviceName, "crime", limit, { severity });
  }

  /**
   * Generate key for sentiment news
   */
  static sentimentKey(serviceName, sentiment = "POSITIVE", limit = 30) {
    return this.generate(serviceName, "sentiment", limit, { sentiment });
  }

  /**
   * Generate key for state news
   */
  static stateKey(serviceName, state, limit = 30) {
    return this.generate(serviceName, "state", limit, { state });
  }

  /**
   * Generate key for entities news
   */
  static entitiesKey(
    serviceName,
    person = null,
    organization = null,
    limit = 30,
  ) {
    return this.generate(serviceName, "entities", limit, {
      person,
      organization,
    });
  }
}

export default RedisKeyGenerator;
