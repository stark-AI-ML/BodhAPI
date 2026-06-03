import {
  fetchCrimeNews,
  fetchEntitiesNews,
  fetchSentimentsNews,
  fetchTodayNews,
  fetchTopNews,
  fetchStateNews,
  fetchEmergencyNews,
  fetchCategoryNews,
  fetchSearchNews,
  fetchTagsNews,
} from "./general.models.js";

import { setKey, getKey } from "../../../utils/redisKey.js";

// Key consistency for redis  --> general_serviceName_limits

export const getGeneralTopNews = async (
  key = "general_top_40",
  limit = 40,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTopNews(limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

export const getGeneralTodayNews = async (
  key = "general_today_60",
  limit = 60,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTodayNews(limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

// BUG FIX: now passes severity to fetchCrimeNews (was only passing limit before)
export const getCrimeNews = async (
  key = "general_crime_30",
  severity,
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchCrimeNews(severity, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

export const getEntitiesNews = async (
  key,
  person = null,
  organization = null,
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchEntitiesNews(person, organization, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

// BUG FIX: now passes sentiment to fetchSentimentsNews (was only passing limit before)
export const getSentimentsNews = async (
  key = "general_positive_30",
  sentiment = "Positive",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchSentimentsNews(sentiment, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

// BUG FIX: was calling fetchEntitiesNews instead of fetchStateNews
export const getStateNews = async (
  key = "general_state_30",
  state,
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchStateNews(state, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

// ─── NEW ROUTES ───

export const getEmergencyNews = async (
  key,
  emergencyType,
  limit = 30,
  ttl = 1800, // 30 min TTL — emergencies should refresh faster
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchEmergencyNews(emergencyType, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

export const getCategoryNews = async (
  key,
  category,
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchCategoryNews(category, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

export const getSearchNews = async (
  key,
  searchQuery,
  limit = 30,
  ttl = 1800, // shorter TTL for search — results change frequently
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchSearchNews(searchQuery, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};

export const getTagsNews = async (
  key,
  tag,
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTagsNews(tag, limit);

    try {
      await setKey(key, news, ttl);
    } catch (error) {
      // TODO: log file + slack notification for cache failures
    }

    return news;
  } else {
    return cachedNews;
  }
};
