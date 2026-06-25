import {
  generateAccessToken,
  generateRefreshToken,
  generateAccessTokenWithUser_ID,
} from '../utils/createToken.js';

import { hashToken, compareToken } from '../utils/hash.js';
import jwt from 'jsonwebtoken';
import { pool } from '../../config/dbConfig.js';

import { v4 as uuidv4 } from 'uuid';

import dotenv from 'dotenv';
import logger from '../../config/logger.js';

dotenv.config();

const revokeAllUserSessions = async (userId) => {
  await pool.query(
    `UPDATE refresh_tokens SET revoked = true WHERE user_id = $1`,
    [userId]
  );
};

export const refresh = async (token, ip, userAgent) => {
  console.log('under refresh token service layer ');

  let payload;
  try {
    const refreshSeceret = process.env.REFRESH_KEY;

    payload = jwt.verify(token, refreshSeceret);
  } catch (error) {
    console.log('verification failed', error);
    throw new Error('Invalid or expired refresh token');
  }

  const userId = payload.id;
  const jwt_id = payload.jwt_id;

  const client = await pool.connect();

  try {
    //------------------- Start Transaction

    await client.query('BEGIN');

    const result = await client.query(
      `SELECT * FROM refresh_tokens WHERE jwt_id = $1`,
      [jwt_id]
    );

    console.log('userid :  ', userId, '\n ', jwt_id, '\n token_prev : ', token);

    const storedToken = result.rows[0];

    // if token is not in database
    if (!storedToken) {
      throw new Error('Invalid refresh token');
    }

    // Network issue period.

    // if (storedToken.revoked_at) {
    //   const revokedTime = new Date(storedToken.revoked_at).getTime();
    //   const now = Date.now();
    //   const timeSinceRevoked = now - revokedTime;

    //   if (timeSinceRevoked <= 60000) {
    //     // User's internet likely dropped. Allow rotation to proceed.
    //     console.warn(
    //       `[Network Retry] Grace period utilized for user ${userId}`
    //     );
    //   } else {
    //     console.warn('revoking all the user');
    //     // logger.log('revoking all the users ');
    //     // REPLAY ATTACK
    //     // Token was revoked more than 60s ago. A hacker is trying to use it.
    //     await revokeAllUserSessions(userId);
    //     throw new Error('Token reuse detected. All sessions revoked.');
    //   }
    // }

    // 6. Compare hashed token

    const isMatch = await compareToken(token, storedToken.token_hash);

    console.log('if is match is true ', isMatch);

    if (!isMatch) {
      console.log('revoking all user but why');
      // logger.log(' problme under isMatch revoking all the users ');

      await revokeAllUserSessions(userId);
      throw new Error('Token mismatch');
    }

    if (storedToken.ip !== ip || storedToken.user_agent !== userAgent) {
      console.warn(
        `[Suspicious Activity] IP or Device changed for user ${userId}`
      );
    } else {
      throw new error(`error due to suscupicious activity `);
    }

    // token rotation
    console.log(' logging storedToken :  ', storedToken);

    await client.query(
      `UPDATE refresh_tokens SET revoked_at = NOW() WHERE id = $1`,
      [storedToken.id]
    );

    //generating new tokens
    const newjwt_id = uuidv4();

    console.log('before newsACESS');
    const newAccessToken = await generateAccessTokenWithUser_ID(userId);

    const newRefreshToken = jwt.sign(
      { id: userId, jwt_id: newjwt_id },
      process.env.REFRESH_KEY,
      { expiresIn: '7d' }
    );

    console.log('After new_Acess');

    const newHash = await hashToken(newRefreshToken);

    console.log('before query');

    await client.query(
      `INSERT INTO refresh_tokens(user_id, token_hash, jwt_id, ip, user_agent, expires_at)
       VALUES($1, $2, $3, $4, $5, NOW() + interval '7 days')`,
      [userId, newHash, newjwt_id, ip, userAgent]
    );
    console.log('after query');

    //------------------------------end transactions
    await client.query('COMMIT');

    console.log(
      'new refresh token is generated and saved to db in service layer'
    );

    return {
      newAccessToken,
      newRefreshToken,
    };
  } catch (error) {
    console.warn('error in DB query service layer refresh : ', error);
    await client.query('ROLLBACK');
    throw error;
    client.release();
  } finally {
    // caused me bug  /learn
    client.release();
  }
};
