import { redisConfig } from '../../config/dbConfig';

async function acquireTokens(
  key,
  tokensRequested,
  windowMs,
  maxTokens,
  dailyMax
) {
  const now = Date.now();

  // 1. Per-minute limiter (Lua script)
  const minuteResult = await redis.eval(
    luaScript,
    1,
    key,
    now,
    windowMs,
    maxTokens,
    tokensRequested
  );

  if (minuteResult === 0) {
    return { allowed: false, reason: 'minute-limit' };
  }

  // 2. Daily quota counter

  const dailyKey = `quota:${key}:day`;
  const usedToday = await redis.incrby(dailyKey, tokensRequested);

  // Set expiry to midnight if first time
  if (usedToday === tokensRequested) {
    const msUntilMidnight = new Date().setHours(24, 0, 0, 0) - now;
    await redis.pexpire(dailyKey, msUntilMidnight);
  }

  if (usedToday > dailyMax) {
    return { allowed: false, reason: 'daily-limit', usedToday };
  }

  // 3. Allowed
  return { allowed: true, count: minuteResult, usedToday };
}
