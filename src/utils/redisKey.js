import { redisConfig } from '../config/dbConfig.js';

console.log(redisConfig);

export async function setKey(key, value, ttlSeconds = null) {
  try {
    const stringValue = JSON.stringify(value);

    if (ttlSeconds) {
      await redisConfig.set(key, stringValue, 'EX', ttlSeconds);
    } else {
      await redisConfig.set(key, stringValue);
    }

    console.log(`Key "${key}" set successfully`);
  } catch (err) {
    console.error(`Error setting key "${key}":`, err);
    throw err;
  }
}

export async function getKey(key) {
  try {
    const value = await redisConfig.get(key);
    if (!value) return null;

    return JSON.parse(value);
  } catch (err) {
    console.error(`Error getting key "${key}":`, err);
    throw err;
  }
}

export async function closeRedis() {
  await redisConfig.quit();
}

export async function setPlanKey(dailyMax, minuteMax, maxKeys, planId) {
  try {
    const planKey = `plan:${planId}`;

    await redisConfig.hset(
      `plan:${planId}`,
      'dailyMax',
      dailyMax,
      'miuteMax',
      minuteMax,
      'maxKeys',
      maxKeys
    );
  } catch (err) {
    console.error(`error setting planKey key "plan${planId}":`, err);
    throw err;
  }
}

export async function getPlanKey(planId) {
  try {
    const key = await redisConfig.hget(`plan:${planId}`);
    return JSON.parse(value);
  } catch (err) {
    console.error(`error gettign the key : plan${planId}`);
    throw err;
  }
}

// quota for every key that make a request with apiKey for first
// time it will set then it's all about getting unitl 12 am

export async function setDailyKeyQuota(prefix_key, planId) {
  try {
    const now = Date.now();
    const dailyLimit = `quota:${prefix_key}:day`;

    await redisConfig.hset(dailyLimit, 'plan', planId, 'used', 0);
    //setting this key for expiration at 00 clock
    const msUntilMidnight = new Date().setHours(24, 0, 0, 0) - now;
    await redis.pexpire(dailyKey, msUntilMidnight);
  } catch (err) {
    console.error(`error setting key quota:${prefix_key}:day:`, err);
    throw err;
  }
}

export async function getDailyKeyQuota(prefix_key) {
  try {
    const dailyLimitKey = `quota:${prefix_key}:day`;
    const dailyLimit = redisConfig.hget(dailyLimitKey, 'plan');
    return dailyLimit;
  } catch (error) {
    console.error(`error getting key quota:${prefix_key}:day:`, err);
    throw err;
  }
}

export async function updateDailyKeyQuotaUsedToday(prefix_key, tokenRequested) {
  const dailyMaxLimit = `quota:${prefix_key}:day`;

  // hincrby returns the update value so we don't have worry
  const updateUsedToday = await redis.hincrby(
    dailyMaxLimit,
    'used',
    tokensRequested
  );

  return updateUsedToday;
}

// export async function
