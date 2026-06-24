import { redisConfig as redis } from '../config/dbConfig.js';

const luaScript = `
-- KEYS[1] = key
-- ARGV[1] = now
-- ARGV[2] = window
-- ARGV[3] = max_tokens
-- ARGV[4] = tokens_requested

local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local max_tokens = tonumber(ARGV[3])
local tokens_requested = tonumber(ARGV[4])

-- remove old
redis.call("ZREMRANGEBYSCORE", key, 0, now - window)

-- current usage
local current = redis.call("ZCARD", key)

-- check limit BEFORE adding
if (current + tokens_requested) > max_tokens then
  return -1
end

-- add tokens
for i=1,tokens_requested do
  redis.call("ZADD", key, now, now .. "-" .. i)
end

redis.call("PEXPIRE", key, window)

return current + tokens_requested
`;

async function getMinuteUsage(
  prefix_key,
  tokensRequested,
  windowMs,
  maxTokens
) {
  const key = `quota:{${prefix_key}}:minute`;
  const now = Date.now();

  //   const luaScript = this.#getLuaScript();

  const result = await redis.eval(
    luaScript,
    1,
    key,
    now,
    windowMs,
    maxTokens,
    tokensRequested
  );

  if (result === -1) return { allowed: false };

  return { allowed: true, used: result };
}

(async () => {
  const userId = 'user123';
  const windowMs = 60000; // 1 minute
  const maxRequests = 20; // fix
  // fix -->  token per request i just put 5 as of now
  //  ---inital thaught was to  calculate based on compute, for now pushing it to prod

  const res = await getMinuteUsage(userId, 5, windowMs, maxRequests);

  console.log(res);
  //   for (let i = 1; i <= 7; i++) {
  //     const count = await acquireTokens(userId, 2, windowMs, maxRequests);
  //     if (count == 0) {
  //       console.log(`Request ${i}: BLOCKED (limit reached, count=${count})`);
  //     } else {
  //       console.log(`Request ${i}: ALLOWED (count=${count})`);
  //     }
  //   }

  redis.quit();
})();

export class RateLimitforApiKeys{
  #plan_id
  #prefix

  constructor(prefix_key, planId){
    #plan_id = planId;
    #prefix = prefix_key;
  }

  async #setPlanKey(dailyMax, minuteMax, maxKeys, planId) {
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

async #getPlanKey(planId) {
  try {
    const key = await redisConfig.hget(`plan:${planId}`);
    return JSON.parse(value);
  } catch (err) {
    console.error(`error gettign the key : plan${planId}`);
    throw err;
  }
}

async #setDailyKeyQuota(prefix_key, planId) {
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

async #getDailyKeyQuota(prefix_key) {
  try {
    const dailyLimitKey = `quota:${prefix_key}:day`;
    const dailyLimit = redisConfig.hget(dailyLimitKey, 'plan');
    return dailyLimit;
  } catch (error) {
    console.error(`error getting key quota:${prefix_key}:day:`, err);
    throw err;
  }
}

async #updateDailyKeyQuotaUsedToday(prefix_key, tokenRequested) {
  const dailyMaxLimit = `quota:${prefix_key}:day`;

  // hincrby returns the update value so we don't have worry

  const updateUsedToday = await redis.hincrby(
    dailyMaxLimit,
    'used',
    tokensRequested
  );

  return updateUsedToday;
}

}
