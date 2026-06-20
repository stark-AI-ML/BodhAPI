import { redisConfig, pool } from '../config/dbConfig';

// some convention if you comeback or anyone replicating this repo :
// my db is has key_prefix --> and here i have used  prefix_key as variable name
//  multiple time : so fallow that for var name
class PlanService {
  async #setPlanKeyWithDB(prefix_key) {
    const queryPlansIdResult = await pool.query(
      `SELECT plan_id FROM users WHERE id = $1`,
      [key.user_id]
    );

    const planId = queryPlansResult.rows[0].plan_id;
    const queryPlanResult = await db.query(
      `SELECT * FROM plan_id where id = $1`,
      [planId]
    );
    const plans = queryPlanResult.rows[0];

    if (plans) {
      this.#setPlanKey(
        plans.token_per_day,
        plans.token_per_minutes,
        plans.maxKeys,
        planId
      );
    } else {
      console.log('unable to find plans');
      throw new error(`plans not found`);
    }
  }

  async #setPlanKey(dailyMax, minuteMax, maxKeys, planId) {
    try {
      const planKey = `plan:${planId}`;
      await redisConfig.hset(
        `plan:${planId}`,
        'dailyMax',
        dailyMax,
        'minuteMax',
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
      const planKey = `plan:${planId}`;
      const planData = await redisConfig.hgetall(planKey);

      if (!planData || Object.keys(planData).length === 0) {
        throw new Error(`no plan data found for ${planKey}`);
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

  async getPlan(planId, prefix_key) {
    try {
      const plans = this.#getPlanKey(planId);

      if (plans) return plans;
      else {
        this.setPlanKeyWithDB(prefix_key);
      }
    } catch (error) {
      console.error('unable to find plans');
      throw new Error(`plans not found`);
    }
  }
}

import { redisConfig, pool } from '../config/dbConfig';

// some convention if you comeback or anyone replicating this repo :
// my db is has key_prefix --> and here i have used  prefix_key as variable name
//  multiple time : so fallow that for var name


class QuotaService {
  // /fix i know time based can be better to update db instead of taken
  //  based checkPoint so implemtation of these will be done later i already perfecting it too much

  #getScriptForMinuteUsage() {
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
    return luaScript;
  }

  #getScriptForDailyQuotaIncrement() {
    const luaScript = `
        -- KEYS[1] = daily key
        -- ARGV[1] = max_daily
        -- ARGV[2] = tokens_requested

        local current = redis.call("HGET", KEYS[1], "used")
        if not current then current = 0 else current = tonumber(current) end

        local requested = tonumber(ARGV[2])
        local max_daily = tonumber(ARGV[1])

        if (current + requested) > max_daily then
          return -1
        end

        local newVal = redis.call("HINCRBY", KEYS[1], "used", requested)
        return newVal`;
  }

  async #updateDB(checkpointSize = 25, tokensRequested, usedToday) {
    const lastCheckpoint = Math.floor(
      (usedToday - tokensRequested) / checkpointSize
    );

    const lastCheckpoint = Math.floor(
      (usedToday - tokensRequested) / checkpointSize
    );
    const currentCheckpoint = Math.floor(usedToday / checkpointSize);

    if (currentCheckpoint > lastCheckpoint) {
      if (usedToday % 100 === 0) {
        // /bug /fix what  i haven't pass the preFIX key
        await pool.query(
          'UPDATE api_keys SET daily_token_used=$1 WHERE key_prefix=$2',
          [usedToday, prefix_key]
        );
      }
    }
  }

  // **** /bug here i have one confusion like if i am dependent on planId these two classes planServices ansd
  // the Quota service will be interdependent? --or if i will just put in sequence and await it is fine right

  async #setDailyKeyQuota(prefix_key, planId) {
    try {
      const now = Date.now();
      const dailyLimit = `quota:${prefix_key}:day`;
      const planKey = `plan:${planId}`;

      await redisConfig.hset(dailyLimit, 'plan', planKey, 'used', 0);
      //setting this key for expiration at 12am clock reduce the load on redis i.e ram
      const msUntilMidnight = new Date().setHours(24, 0, 0, 0) - now;
      await redis.pexpire(dailyKey, msUntilMidnight);
    } catch (err) {
      console.error(`error setting key quota:${prefix_key}:day:`, err);
      throw err;
    }
  }

  // async #incrementDailyUsage(prefix_key, tokensRequested, falg = '') {
  //   const dailyMaxLimit = `quota:${prefix_key}:day`;

  //   // hincrby returns the update value so we don't have worry
  //   const updateUsedToday = await redis.hincrby(
  //     dailyMaxLimit,
  //     'used',
  //     tokensRequested
  //   );

  //   if (flag != 'db') {
  //     await this.#updateDB(30, tokensRequested, updateUsedToday);
  //   }

  //   return updateUsedToday;
  // }

  async incrementDailyUsage(prefix_key, tokensRequested, maxDaily) {
    const dailyLua = this.#getScriptForDailyQuota();

    const key = `quota:{${prefix_key}}:day`;

    const result = await redis.eval(
      this.dailyLua,
      1,
      key,
      maxDaily,
      tokensRequested
    );

    if (result === -1) return { allowed: false };

    return { allowed: true, used: result };
  }

  // never confuse on this again planId  already exsits  because planService do that so after sleep don't forget that

  async #getDailyKeyQuota(prefix_key) {
    try {
      const dailyLimitKey = `quota:${prefix_key}:day`;
      const quota = await redisConfig.hgetall(dailyLimitKey);

      if (!quota || Object.keys(quota).length === 0) {
        throw new Error(`no quota data found for ${dailyLimitKey}`);
      }

      return {
        plan: parseInt(quota.plan, 10),
        used: quota.plan,
      };
    } catch (error) {
      console.error(`error getting key quota:${prefix_key}:day:`, error);
      throw error;
    }
  }


  async #setDailyKeyQuotaWithDB(prefix_key, planId, dailyMax) {
    try {
      this.#setDailyKeyQuota(prefix_key, planId);
      // we need to update this dailyQuota limit based on Db limit  so if redis crashed or some bug:
      // fuck me is anyone going to use it

      const dailyQuotaQuery = await pool.query(
        `SELECT daily_token_used FROM api_keys WHERE key_prefix = $1`,
        [prefix_key]
      );

      const dailyQuota = dailyQuotaQuery.rows[0].daily_token_used;

      // to do update the daily quotaQuery in redis

      this.#incrementDailyUsage(prefix_key, dailyQuota, 'db');
    } catch (error) {}
  }

  async getMinuteUsage(prefix_key, tokensRequested, windowMs, maxTokens) {
    const key = `quota:{${prefix_key}}:minute`;
    const now = Date.now();

    const luaScript = this.#getLuaScript();

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

  async getDailyUsage(prefix_key, planId, dailyMax) {
    try {
      const dailyUsageQuota = this.#getDailyKeyQuota(prefix_key);
      // you will get plan and qutoa in integer updade and increment

      if (!dailyUsageQuota) {
        this.#setDailyKeyQuotaWithDB(prefix_key, planId, dailyMax);
      }
    } catch (error) {}
  }
}

class RateLimiter {
  constructor(planService, quotaService) {
    this.planService = planService;
    this.quotaService = quotaService;
  }

  async isMinuteExceeded(prefix_key, planId, tokensRequested) {
    //     dailyMax: parseInt(planData.dailyMax, 10),
    //     minuteMax: parseInt(planData.minuteMax, 10),
    //     maxKeys: parseInt(planData.maxKeys, 10),

    const plan = await this.planService.getPlan(planId);

    const result = await this.quotaService.getMinuteUsage(
      prefix_key,
      tokensRequested,
      60000,
      plan.minuteMax
    );

    return !result.allowed;
  }

  async isDailyExceeded(prefix_key, planId, tokensRequested) {
    const plan = await this.planService.getPlan(planId);

    const result = await this.quotaService.tryConsumeDailyQuota(
      prefix_key,
      tokensRequested,
      plan.dailyMax
    );

    return !result.allowed;
  }
}


class RateLimiter {
  constructor(planService, quotaService) {
    this.planService = planService;
    this.quotaService = quotaService;
  }

  async isMinuteExceeded(prefix_key, planId, tokensRequested) {
    //     dailyMax: parseInt(planData.dailyMax, 10),
    //     minuteMax: parseInt(planData.minuteMax, 10),
    //     maxKeys: parseInt(planData.maxKeys, 10),

    const plan = await this.planService.getPlan(planId);

    const result = await this.quotaService.getMinuteUsage(
      prefix_key,
      tokensRequested,
      60000,
      plan.minuteMax
    );

    return !result.allowed;
  }

  async isDailyExceeded(prefix_key, planId, tokensRequested) {
    const plan = await this.planService.getPlan(planId);

    const result = await this.quotaService.tryConsumeDailyQuota(
      prefix_key,
      tokensRequested,
      plan.dailyMax
    );

    return !result.allowed;
  }
}
