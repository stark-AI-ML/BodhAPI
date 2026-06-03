import {
  fetchTodayBusinessNews,
  fetchTopBusinessNews,
  fetchTechNews,
  fetchFinanceNews,
  fetchSentimentBusinessNews,
  fetchStateBusinessNews,
} from "./business.model.js";

import { setKey, getKey } from "../../../utils/redisKey.js";

// Key consistency for redis  --> business_serviceName_limits

export const getBusinessTodayNews = async (
  key = "business_today_30",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTodayBusinessNews(limit);

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

export const getBusinessTopNews = async (
  key = "business_top_40",
  limit = 40,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTopBusinessNews(limit);

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

export const getBusinessTechNews = async (
  key = "business_tech_30",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTechNews(limit);

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

export const getBusinessFinanceNews = async (
  key = "business_finance_30",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchFinanceNews(limit);

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

export const getBusinessSentimentNews = async (
  key = "business_sentiment_30",
  sentiment = "Positive",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchSentimentBusinessNews(sentiment, limit);

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

export const getBusinessStateNews = async (
  key = "business_state_30",
  state,
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchStateBusinessNews(state, limit);

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
