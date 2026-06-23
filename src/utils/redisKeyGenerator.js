class RedisKeyGenerator {
  //   main generator combines the name:type:limit with the : --- which creates a perfect folder strucuture on redis
  static buildKey(serviceName, queryType, identifiers = [], limit = 30) {
    // clean up identifiers (handle nulls, convert to lowercase, replace spaces with underscores)
    const cleanIdentifiers = identifiers
      .filter(Boolean) // to remove null val
      .map((id) => String(id).trim().replace(/\s+/g, '_').toLowerCase());

    const keyParts = [serviceName, queryType, ...cleanIdentifiers, limit];

    return keyParts.join(':');
  }

  static todayKey(serviceName, limit = 60) {
    return this.buildKey(serviceName, 'today', [], limit);
  }

  static topKey(serviceName, limit = 40) {
    return this.buildKey(serviceName, 'top', [], limit);
  }

  static crimeKey(serviceName, severity, limit = 30) {
    return this.buildKey(serviceName, 'crime', [severity], limit);
  }

  static sentimentKey(serviceName, sentiment = 'positive', limit = 30) {
    return this.buildKey(serviceName, 'sentiment', [sentiment], limit);
  }

  static stateKey(serviceName, state, limit = 30) {
    return this.buildKey(serviceName, 'state', [state], limit);
  }

  static entitiesKey(
    serviceName,
    person = 'any',
    organization = 'any',
    limit = 30
  ) {
    return this.buildKey(
      serviceName,
      'entities',
      [person, organization],
      limit
    );
  }

  static emergencyKey(serviceName, emergencyType, limit = 30) {
    return this.buildKey(serviceName, 'emergency', [emergencyType], limit);
  }

  static categoryKey(serviceName, category, limit = 30) {
    return this.buildKey(serviceName, 'category', [category], limit);
  }

  static searchKey(serviceName, query, limit = 30) {
    return this.buildKey(serviceName, 'search', [query], limit);
  }

  static tagsKey(serviceName, tag, limit = 30) {
    return this.buildKey(serviceName, 'tags', [tag], limit);
  }
}

export default RedisKeyGenerator;

// ---------test

// const key = RedisKeyGenerator.todayKey('general', 30);
// const tagKey = RedisKeyGenerator.tagsKey(
//   'general',
//   ['politics', 'geoPolitics', 'money'],
//   40
// );

// console.log(key, tagKey);
