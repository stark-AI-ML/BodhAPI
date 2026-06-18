export async function acquireTokens(
  apiKey,
  tokensRequested,
  windowMs,
  maxTokens
) {
  const now = Date.now();

  // 1. Per-minute limiter
  const minuteResult = await redis.eval(
    luaScript,
    1,
    `rate:${apiKey}:minute`,
    now,
    windowMs,
    maxTokens,
    tokensRequested
  );
  if (minuteResult === 0) {
    return { allowed: false, reason: 'minute-limit' };
  }

  // 2. Daily quota counter
  const dailyKey = `quota:${apiKey}:day`;

  let planId = await redis.hget(dailyKey, 'plan');

  if (!planId) {
    // First time: fetch from DB
    const { rows } = await db.query(
      'SELECT plan_id FROM users WHERE api_key=$1',
      [apiKey]
    );
    planId = rows[0].plan_id;
    await redis.hset(dailyKey, 'plan', planId, 'used', 0);

    const msUntilMidnight = new Date().setHours(24, 0, 0, 0) - now;

    await redis.pexpire(dailyKey, msUntilMidnight);
  }

  // 3. Increment usage
  const usedToday = await redis.hincrby(dailyKey, 'used', tokensRequested);

  // 4. Lookup plan daily_max
  let dailyMax = await redis.hget(`plan:${planId}`, 'daily_max');
  if (!dailyMax) {
    // Cache plan limit if missing
    const { rows } = await db.query('SELECT daily_max FROM plans WHERE id=$1', [
      planId,
    ]);
    dailyMax = rows[0].daily_max;
    await redis.hset(`plan:${planId}`, 'daily_max', dailyMax);
  }
  dailyMax = parseInt(dailyMax, 10);

  // 5. Enforce quota
  if (usedToday > dailyMax) {
    return { allowed: false, reason: 'daily-limit', usedToday, dailyMax };
  }

  // 6. Checkpoint sync
  if (usedToday % 100 === 0) {
    await db.query('UPDATE users SET tokens_used_today=$1 WHERE api_key=$2', [
      usedToday,
      apiKey,
    ]);
  }

  // 7. Allowed
  return { allowed: true, count: minuteResult, usedToday, dailyMax };
}
