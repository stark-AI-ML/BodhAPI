// redisCache.js
import Redis from "ioredis";

const redis = new Redis({
  host: "localhost",
  port: 6379,
});

export async function setKey(key, value, ttlSeconds = null) {
  try {
    // Arrays are objects, so stringify works fine
    const stringValue = JSON.stringify(value);

    if (ttlSeconds) {
      await redis.set(key, stringValue, "EX", ttlSeconds);
    } else {
      await redis.set(key, stringValue);
    }

    console.log(`✅ Key "${key}" set successfully`);
  } catch (err) {
    console.error(`❌ Error setting key "${key}":`, err);
    throw err;
  }
}

export async function getKey(key) {
  try {
    const value = await redis.get(key);
    if (!value) return null;

    // Always try to parse JSON (array or object)
    return JSON.parse(value);
  } catch (err) {
    console.error(`❌ Error getting key "${key}":`, err);
    throw err;
  }
}

export async function closeRedis() {
  await redis.quit();
}
