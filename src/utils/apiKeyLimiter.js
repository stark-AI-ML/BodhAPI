import { redisConfig, pool } from '../config/dbConfig.js';

// some convention if you comeback or anyone replicating this repo :
// my db is has key_prefix --> and here i have used  prefix_key as variable name
//  multiple time : so fallow that for var name

// learned new thing if you fallowing srp : instead of dependingon imports of redisConfig
// db or pool you can pass this as a constructor which better for Testablity : yk can think of why

// so i'm changing this : for production level code

export class PlanService {
  constructor(redis, db) {
    this.redis = redis;
    this.db = db;
  }

  async #setPlanKeyWithDB(planId) {
    console.log('set Plan key with db', planId);

    const queryPlanResult = await this.db.query(
      `SELECT * FROM plans WHERE id = $1`,
      [planId]
    );

    console.log('queryLog', queryPlanResult);

    if (queryPlanResult.rowCount === 0) {
      console.error(`Plan with id ${planId} not found`);
      throw new Error(`Plan not found`);
    }

    const plan = queryPlanResult.rows[0];
    console.log('plan from db:', plan);

    // Use the correct variable and column names
    await this.#setPlanKey(
      plan.token_per_day,
      plan.token_per_minute,
      plan.max_key, // adjust to match your schema
      planId
    );
  }

  async #setPlanKey(dailyMax, minuteMax, maxKeys, planId) {
    // console.log(minuteMax, maxKeys, planId);
    try {
      const planKey = `plan:${planId}`;
      await this.redis.hset(
        planKey,
        'dailyMax',
        dailyMax,
        'minuteMax',
        minuteMax,
        'maxKeys',
        maxKeys
      );

      const result = await this.redis.hgetall(planKey);
      console.log(result);
    } catch (err) {
      console.error(`error setting planKey key "plan${planId}":`, err);
      throw err;
    }
  }

  async #getPlanKey(planId) {
    try {
      const planKey = `plan:${planId}`;
      const planData = await this.redis.hgetall(planKey);

      if (!planData || Object.keys(planData).length === 0) {
        return null;
      }
      return {
        dailyMax: parseInt(planData.dailyMax, 10),
        minuteMax: parseInt(planData.minuteMax, 10),
        maxKeys: parseInt(planData.maxKeys, 10),
      };
    } catch (err) {
      console.error(`error getting planKey for plan:${planId}`, err);
      throw err;
    }
  }

  async getPlan(planId, prefix_key, user_id) {
    try {
      let plans = await this.#getPlanKey(planId, user_id);
      console.log('plans', plans);
      if (!plans) {
        console.log('under !plan');
        await this.#setPlanKeyWithDB(planId);

        plans = await this.#getPlanKey(planId);
        console.log('plans', plans);
      }
      return plans;
    } catch (error) {
      console.error('unable to find plans');
      throw new Error(`plans not found`);
    }
  }
}

export class QuotaService {
  constructor(redis, db) {
    this.redis = redis;
    this.db = db;
  }

  #minuteLua() {
    return `
      local key = KEYS[1]
      local now = tonumber(ARGV[1])
      local window = tonumber(ARGV[2])
      local max_tokens = tonumber(ARGV[3])
      local tokens_requested = tonumber(ARGV[4])

      redis.call("ZREMRANGEBYSCORE", key, 0, now - window)

      local current = redis.call("ZCARD", key)

      if (current + tokens_requested) > max_tokens then
        return -1
      end

      for i=1,tokens_requested do
        redis.call("ZADD", key, now, now .. "-" .. i)
      end

      redis.call("PEXPIRE", key, window)

      return current + tokens_requested
    `;
  }

  async tryConsumeMinute(prefix_key, tokens, windowMs, maxTokens) {
    const key = `quota:{${prefix_key}}:minute`;
    const now = Date.now();

    const result = await this.redis.eval(
      this.#minuteLua(),
      1,
      key,
      now,
      windowMs,
      maxTokens,
      tokens
    );

    if (result === -1) return { allowed: false };
    return { allowed: true, used: result };
  }

  // dailyIncrement

  #dailyLua() {
    return `
      local key = KEYS[1]
      local max_daily = tonumber(ARGV[1])
      local tokens_requested = tonumber(ARGV[2])

      local current = redis.call("HGET", key, "used")
      if not current then current = 0 else current = tonumber(current) end

      if (current + tokens_requested) > max_daily then
        return -1
      end

      local newVal = redis.call("HINCRBY", key, "used", tokens_requested)
      return newVal
    `;
  }

  async tryConsumeDaily(prefix_key, tokens, maxDaily) {
    const key = `quota:{${prefix_key}}:day`;

    const result = await this.redis.eval(
      this.#dailyLua(),
      1,
      key,
      maxDaily,
      tokens
    );

    if (result === -1) return { allowed: false };

    // checkpoint DB (cheap, async safe)
    this.#checkpointDB(prefix_key, tokens, result).catch(() => {});

    return { allowed: true, used: result };
  }

  // if dailyKey isn't created or expired

  async ensureDailyKey(prefix_key) {
    const key = `quota:{${prefix_key}}:day`;

    const exists = await this.redis.exists(key);
    if (exists) return;

    const res = await this.db.query(
      `SELECT daily_token_used FROM api_keys WHERE key_prefix = $1`,
      [prefix_key]
    );

    const used = res.rows[0]?.daily_token_used || 0;

    const now = Date.now();
    const msUntilMidnight = new Date().setHours(24, 0, 0, 0) - now;

    await this.redis.hset(key, 'used', used);
    await this.redis.pexpire(key, msUntilMidnight);
  }

  async #checkpointDB(prefix_key, tokensRequested, usedToday) {
    const checkpointSize = 25; // i know it shouldn't be hardcoded and based on ttl but
    // here is the thin i have enough for this it's not going to boom
    //  and i need to finish it so /fix

    const prev = usedToday - tokensRequested;

    const prevBucket = Math.floor(prev / checkpointSize);
    const currBucket = Math.floor(usedToday / checkpointSize);

    if (currBucket > prevBucket) {
      // async fire and forget
      await this.db.query(
        `UPDATE api_keys SET daily_token_used=$1 WHERE key_prefix=$2`,
        [usedToday, prefix_key]
      );
    }
  }
}

export class RateLimiter {
  constructor(planService, quotaService) {
    // obj passed with teh costructor instialised so you don't have to worry about
    // providing the redis_cofiguration and db

    this.planService = planService;
    this.quotaService = quotaService;
  }

  async check(prefix_key, planId, tokens, user_id) {
    const plan = await this.planService.getPlan(planId);
    console.log('plan check: ', plan);

    await this.quotaService.ensureDailyKey(prefix_key);

    const minute = await this.quotaService.tryConsumeMinute(
      prefix_key,
      tokens,
      60000,
      plan.minuteMax
    );

    if (!minute.allowed)
      return {
        allowed: false,
        reason: 'too many request please try again later',
        status: 429,
      };

    const daily = await this.quotaService.tryConsumeDaily(
      prefix_key,
      tokens,
      plan.dailyMax
    );

    if (!daily.allowed) return { allowed: false, reason: 'daily' };

    return { allowed: true };
  }
}

//-----------test

// const planService = new PlanService(redisConfig, pool);
// const quotaService = new QuotaService(redisConfig, pool);

// const rateLimiter = new RateLimiter(planService, quotaService);

// // bodh_live_6c05fe5ba6e9_cfd345de36e522d0be66b75b199f92c639f2;
// // bodh_live_6c05fe5ba6e9
// // fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd
// // planId : 1;

// const check = await rateLimiter.check(
//   'bodh_live_6c05fe5ba6e9',
//   1,
//   2,
//   'fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd'
// );

// console.log(check);
