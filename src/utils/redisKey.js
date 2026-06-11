import { pool, redisConfig } from '../config/dbConfig.js';

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
