import {
  RateLimiter,
  QuotaService,
  PlanService,
} from '../../utils/apiKeyLimiter.js';

import { redisConfig, pool } from '../../config/dbConfig.js';

const planService = new PlanService(redisConfig, pool);
const quotaService = new QuotaService(redisConfig, pool);

const rateLimiter = new RateLimiter(planService, quotaService);

export const rateLimitMiddleware = async (req, res, next) => {
  try {
    const prefix_key = req.apiKeyPrefix;
    const planId = req.planId;
    const user_id = req.user_id;

    // /fix need to create token calculator class or fx based on compute complexity

    const tokens = 3;

    const result = await rateLimiter.check(prefix_key, planId, tokens, user_id);

    if (!result.allowed) {
      return res.status(429).json({
        error: `limit exceeded (${result.reason})`,
      });
    }

    next();
  } catch (err) {
    console.error('Rate limiter failed', err);

    // fail-open (important)
    next();
  }
};
