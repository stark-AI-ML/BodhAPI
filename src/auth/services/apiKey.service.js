import createKey from '../utils/apiKeyGenerator.js';

import crypto from 'crypto';
import logger from '../../config/logger.js';
import { pool } from '../../config/dbConfig.js';

async function isPlanKeyExceeded(user_id, client, keyAlloted) {
  const plan = await client.query(`SELECT plan_id FROM users WHERE id = $1`, [
    user_id,
  ]);
  const plan_id = plan.rows[0].plan_id;

  const plansResult = await client.query(`SELECT * FROM plans WHERE id = $1`, [
    plan_id,
  ]);
  const maxKeyAlloted = plansResult.rows[0].max_key;

  return keyAlloted > maxKeyAlloted;
}

export const generateApiKey = async (user_id, keyName) => {
  //     -- SELECT users.plan_id
  // -- FROM api_keys
  // -- JOIN users ON api_keys.user_id = users.id
  // -- WHERE api_keys.key_prefix = $1;
  // since i know the db best practise i will fallow it

  const client = await pool.connect();

  try {
    const now = new Date();

    await client.query('BEGIN');

    const api_keyQuery = `SELECT * FROM api_keys where user_id = $1 AND expires_at > $2`;
    const result = await client.query(api_keyQuery, [user_id, now]);
    const keyAlloted = result.rowCount || 0;

    let prefix;
    let fullKey;

    if (await isPlanKeyExceeded(user_id, client, keyAlloted)) {
      const err = new Error('number of api_keys exceeded');
      err.statusCode = 403;
      throw err;
    } else {
      const getKey = await createKey();

      prefix = getKey.prefix;
      fullKey = getKey.fullKey;

      console.log(fullKey, prefix);

      const keyHash = crypto.createHash('sha256').update(fullKey).digest('hex');

      // /feature to add

      // /fix moving for production so not 30 min anymore but for now i will give max 60d expiry

      const newAPI_expiresAt = new Date(
        now.getTime() + 60 * 24 * 60 * 60 * 1000
      );
      await client.query(
        `INSERT INTO api_keys(user_id, key_hash, key_prefix, revoked, expires_at, api_name)
     VALUES($1, $2, $3, $4, $5, $6)`,
        [user_id, keyHash, prefix, false, newAPI_expiresAt, keyName]
      );

      await client.query('COMMIT');
      // /bug /fixed -- just let it be  cuz as i have added this max_key element and earlier
      // and i had expires_at so there is expired key too  so all expired key but max_key is greater than 5
      // i fixed it with query

      // second fix ---- bruteforce /bug its just my quick thinking corn job will be better

      pool
        .query('DELETE FROM api_keys WHERE expires_at < $1 AND user_id = $2', [
          now,
          user_id,
        ])
        .catch((error) => logger.info('promise in bg failed', error));
    }
    return { prefix, fullKey };
  } catch (err) {
    if (err.statusCode === 403) {
      err.message;
      err.status = 403;
    } else {
      err.status === 500;
    }
    console.log('Caught error:', err);
    console.log('Message:', err.message);
    console.log('StatusCode:', err.statusCode);
  }
};

// -----------test

// const key = generateApiKey('2cfef765-be93-4f01-b96f-88f2b2b2ec39');
// console.log('key : ', await key);

// const data = await pool.query(`select plan_id from users where id = $1`, [
//   '2cfef765-be93-4f01-b96f-88f2b2b2ec39',
// ]);
// const rel = data.rows[0].plan_id;

// const planDATA = await pool.query(`select * from plans where id = $1`, [rel]);

// console.log(planDATA.rows[0]);

export const getApiKeys = async (user_id) => {
  try {
    const query = `SELECT * FROM api_keys  WHERE user_id = $1`;

    const result = await pool.query(query, [user_id]);

    const data = result.rows.map((item) => {
      return {
        name: item.api_name,
        key: item.key_prefix,
        expiresAt: item.expires_at,
        lastUsed: item.last_used_at,
        revoked: item.revoked,
      };
    });

    console.log('unser get api key', data);
    return data;
  } catch (error) {
    console.warn('error occured at service layer getApi', error);
  }
};

export const deleteApiKey = async (user_id, prefixKey) => {
  try {
    // well in your db design you have some rfinment you crated idx for user_id , key_prefix
    // seperately on api_key i think you should merge it

    const query = `DELETE FROM api_keys WHERE user_id = $1 AND key_prefix = $2`;

    const result = await pool.query(query, [user_id, prefixKey]);

    if (result.rowCount > 0) {
      return { statusCode: 200, msg: 'Deletion successful' };
    } else {
      // No matching row found
      throw { statusCode: 404, msg: 'API key not found' };
    }
  } catch (error) {
    console.warn(error);
    if (!error.statusCode) {
      throw {
        statusCode: 500,
        msg: 'Internal server error',
        detail: error.message,
      };
    }
    throw error;
  }
};

// const data = await getApiKeys('fa61f3e0-14ea-4ce1-bfd8-9701f5960dcd');

// console.log(data);
