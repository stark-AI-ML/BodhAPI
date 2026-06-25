import { pool as db } from '../../config/dbConfig.js';
import { compareAPIHash } from '../utils/hash.js';
import {
  // getUserApiCache,
  getKey,
  setUserApiCache,
} from '../../utils/redisKey.js';

export const apiKeyMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Missing Authorization' });
    }

    const apiKey = authHeader.split(' ')[1];
    const parts = apiKey.split('_');

    if (parts.length < 3) {
      return res.status(401).json({ message: 'Invalid API key format' });
    }

    const prefix = parts.slice(0, 3).join('_');
    const cacheKey = `apikey:{${prefix}}`;
    let cached = await getKey(cacheKey);

    if (cached) {
      console.log(cached);
      // console.log(data);
      // const data = JSON.parse(cached);
      // ///httt i was returining parse data and parsing again :(((

      const data = cached;

      req.user_id = data.user_id;
      req.planId = data.planId;
      req.apiKeyPrefix = prefix;

      return next();
    }

    // /fix fixes error i had changed the schema but didn't updated the  revoked ->
    // const result = await db.query(
    //   `SELECT user_id, key_hash, expires_at
    //    FROM api_keys
    //    WHERE key_prefix = $1 AND revoked = false`,
    //   [prefix]
    // );
    const result = await db.query(
      `SELECT user_id, key_hash, expires_at
      FROM api_keys
      WHERE key_prefix = $1
     AND revoked_at IS NULL
     AND expires_at > NOW()`,
      [prefix]
    );

    const key = result.rows[0];

    if (!key) {
      return res
        .status(401)
        .json({ message: 'Invalid API key or expired relogin' });
    }

    // if (key.expires_at && new Date() > key.expires_at) {
    //   return res.status(401).json({ message: 'API key expired' });
    // }

    const isValid = await compareAPIHash(apiKey, key.key_hash);

    if (!isValid) {
      return res.status(401).json({ message: 'Invalid API key' });
    }

    const planRes = await db.query(`SELECT plan_id FROM users WHERE id = $1`, [
      key.user_id,
    ]);

    const planId = planRes.rows[0].plan_id;

    await setUserApiCache(cacheKey, key.user_id, planId, key.expires_at);

    req.user_id = key.user_id;
    req.planId = planId;
    req.apiKeyPrefix = prefix;

    next();
  } catch (error) {
    console.error('Auth error:', error);
    res.status(500).json({ message: 'Authorization error' });
  }
};
