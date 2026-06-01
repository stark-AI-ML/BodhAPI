import {
  fetchCrimeNews,
  fetchEntitiesNews,
  fetchSentimentsNews,
  fetchTodayNews,
  fetchTopNews,
} from "./general.models.js";

import { setKey, getKey } from "../../../utils/redisKey.js";

// export const fetchTodayNews = async (id) => {
//   // business logic (can add caching, transformation, etc.)

//   const user = await userModel.findUserById(id);
///

//   return user;
// };

// Key consistency for redis  --> general_serviceName_limits

/* I think i am not solving the time to live efficiently so if i make it opensource 
  or if fuking me revisit try to improve this you chutiya*/

export const getGeneralTopNews = async (
  key = "general_top_40",
  limit = 40,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchTopNews(limit);
    await setKey(key, news, ttl);
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
    await setKey(key, news, ttl);
    return news;
  } else {
    return cachedNews;
  }
};

export const getCrimeNews = async (
  key = "general_crime_30",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchCrimeNews(limit);
    await setKey(key, news, ttl);
    return news;
  } else {
    return cachedNews;
  }
};

// here key get complex so it must be passed through the controller layer  try to create a function just to
// just to create a key ---> general_peoplNameANDorgName_30

export const getEntitiesNews = async (key, limit = 30, ttl = 3600) => {
  const cachedNews = await getKey(key);

  if (!cachedNews) {
    const news = await fetchEntitiesNews(limit);
    await setKey(key, news, ttl);
    return news;
  } else {
    return cachedNews;
  }
};

export const getSentimentsNews = async (
  key = "general_positve_30",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);
  if (!cachedNews) {
    const news = await fetchSentimentsNews(limit);
    await setKey(key, news, ttl);
    return news;
  } else {
    return cachedNews;
  }
};

export const getStateNews = async (
  key = "general_positve_30",
  limit = 30,
  ttl = 3600,
) => {
  const cachedNews = await getKey(key);
  if (!cachedNews) {
    const news = await fetchEntitiesNews(limit);
    await setKey(key, news, ttl);
    return news;
  } else {
    return cachedNews;
  }
};
