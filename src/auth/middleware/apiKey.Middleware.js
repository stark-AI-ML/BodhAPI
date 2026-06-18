import { pool as db } from '../../config/dbConfig.js';
import { compareAPIHash } from '../utils/hash.js';
import { getDailyKeyQuota, getKey, setPlanKey } from '../../utils/redisKey.js';
import { acquireTokens } from '../utils/rateLimiter_tokenBased.js';

export const apiKeyMiddleware = async (req, res, next) => {
  // authorization header

  console.log('under apiKey middleware');
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res
      .status(401)
      .json({ message: 'Missing or invalid Authorization header' });
  }

  const apiKey = authHeader.split(' ')[1];
  const parts = apiKey.split('_');

  console.log(apiKey);
  if (parts.length < 3) {
    return res.status(401).json({ message: 'Wrong API key' });
  }

  const prefix = parts.slice(0, 3).join('_');

  console.log(prefix);

  try {
    // redis implementation

    const isUserKeyCached = await getDailyKeyQuota(prefix);

    let userDailyQuota = 30;
    // /bug i don't want to hardcode this but will fix patch later
    // and for now it will updated in almost all cases but if something breaks

    if (!isUserKeyCached) {
      const result = await db.query(
        `SELECT user_id, key_hash, expires_at FROM api_keys WHERE key_prefix = $1 AND revoked = false`,
        [prefix]
      );

      const key = result.rows[0];

      console.log('db key ', key);

      if (!key) {
        return res.status(401).json({ message: 'Invalid API key' });
      }

      if (key.expires_at && new Date() > key.expires_at) {
        return res.status(401).json({ message: 'API key expired' });
      }

      const isValid = await compareAPIHash(apiKey, key.key_hash);
      console.log(isValid);
      if (!isValid) {
        return res.status(401).json({ message: 'Invalid API key__' });
      }

      // if it passes all this checkList i want to assign this
      //  key a planId on redis so can user fetch it faster
      const queryPlansIdResult = await db.query(
        `SELECT plan_id FROM users WHERE id = $1`,
        [key.user_id]
      );
    }
    const planId = queryPlansResult.rows[0].plan_id;

    const queryPlanResult = await db.query(
      `SELECT * FROM plan_id where id = $1`,
      [planId]
    );
    const plans = queryPlanResult.rows[0];

    if (plans) {
      setPlanKey(
        plans.token_per_day,
        plans.token_per_minutes,
        plans.maxKeys,
        planId
      );
    } else {
      console.log('unable to find plans');
      throw new error(`plans not found`);
    }

    req.user_id = key.user_id;

    next();
  } catch (error) {
    res
      .status(500)
      .json({ message: 'Authorization error', error: error.message });
  }
};
