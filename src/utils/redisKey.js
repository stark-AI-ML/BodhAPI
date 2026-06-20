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

export async function setUserApiCache(key, userId, planId, expires_at) {
  await redisConfig.set(
    key,
    JSON.stringify({
      user_id: userId,
      planId: planId,
      expires_at: expires_at,
    }),
    'EX',
    3 * 3600
  );
}

// export async function getUserApiCache(key) {
//   try {
//     const userCache = await this.redis.hgetall(planKey);
//     if (!userCache) return null;

//     return {
//       user_id: user_id,
//       key_hash: key_hash,
//       expires_at: expires_at,
//       plan_id: parseInt(plan_id, 10),
//     };
//   } catch (error) {
//     console.error(`Error getting key "${key}":`, err);
//     throw err;
//   }
// }

export async function closeRedis() {
  await redisConfig.quit();
}
