// most unoptimised think i have done

class RedisKeyGenerator {
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
          keyParts.push(params.state.replace(/\s+/g, "_"));
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

      case "emergency":
        if (params.emergencyType) {
          keyParts.push(params.emergencyType.toUpperCase());
        }
        break;

      case "category":
        if (params.category) {
          keyParts.push(params.category.replace(/\s+/g, "_"));
        }
        break;

      case "search":
        if (params.query) {
          keyParts.push(params.query.replace(/\s+/g, "_"));
        }
        break;

      case "tags":
        if (params.tag) {
          keyParts.push(params.tag.replace(/\s+/g, "_"));
        }
        break;

      case "tech":
      case "finance":
      case "today":
      case "top":
      default:
        break;
    }
    keyParts.push(limit);

    return keyParts.join("_");
  }

  // key for today news
  static todayKey(serviceName, limit = 60) {
    return this.generate(serviceName, "today", limit);
  }

  // key for top news

  static topKey(serviceName, limit = 40) {
    return this.generate(serviceName, "top", limit);
  }

  //for crime news

  static crimeKey(serviceName, severity, limit = 30) {
    return this.generate(serviceName, "crime", limit, { severity });
  }

  // sentiment news
  static sentimentKey(serviceName, sentiment = "POSITIVE", limit = 30) {
    return this.generate(serviceName, "sentiment", limit, { sentiment });
  }

  // key for state news
  static stateKey(serviceName, state, limit = 30) {
    return this.generate(serviceName, "state", limit, { state });
  }

  // enitites News
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

  //emergency news
  static emergencyKey(serviceName, emergencyType, limit = 30) {
    return this.generate(serviceName, "emergency", limit, { emergencyType });
  }

  // category news

  static categoryKey(serviceName, category, limit = 30) {
    return this.generate(serviceName, "category", limit, { category });
  }

  // search news
  static searchKey(serviceName, query, limit = 30) {
    return this.generate(serviceName, "search", limit, { query });
  }

  // tags news
  static tagsKey(serviceName, tag, limit = 30) {
    return this.generate(serviceName, "tags", limit, { tag });
  }
}

export default RedisKeyGenerator;
