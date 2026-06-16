import {
  generateAccessToken,
  generateRefreshToken,
  generateAccessTokenWithUser_ID,
} from '../utils/jwt.js';

import { hashToken, compareToken } from '../utils/hash.js';
import jwt from 'jsonwebtoken';
import { pool } from '../../config/dbConfig.js';

import { v4 as uuidv4 } from 'uuid';

import dotenv from 'dotenv';

dotenv.config();

// /fix there can be some key improvements see i'm not going for auth.model layer : cuz as of now
//  i am not fixing the role thing just plan thing is fixed and so not too much of query i think
// its fine with this now........

export const login = async (user, ip, userAgent) => {
  console.log('log from the login', user);

  const accessToken = generateAccessToken({
    user_id: user.user_id,
    google_id: user.google_id,
    email: user.email,
    picture: user.picture,
    display_name: user.display_name,
    plan: user.plan_id,

    // /bug on other end where you defined role by thinking of rolw
    //  fix that this is the rminder if you see
    // also for any these type of issue write /bug smjha chuityea
  });

  const jwt_id = uuidv4();

  const refreshToken = generateRefreshToken({
    id: user.user_id,
    jwt_id,
  });

  const tokenHash = await hashToken(refreshToken);

  await pool.query(
    `INSERT INTO refresh_tokens(user_id, token_hash, jwt_id, ip, user_agent, expires_at)
     VALUES($1,$2,$3,$4,$5, NOW() + interval '30 days')`,
    [user.user_id, tokenHash, jwt_id, ip, userAgent]
  );

  return { accessToken, refreshToken };
};

//--------------------------------------------------------------------------------------------------------

const revokeAllUserSessions = async (userId) => {
  await pool.query(
    `UPDATE refresh_tokens SET revoked = true WHERE user_id = $1`,
    [userId]
  );
};

export const refresh = async (token, ip, userAgent) => {
  console.log('under refresh token service layer ');
  // 1. Verify JWT signature & expiry first
  let payload;
  try {
    console.log('loging token  : ', token);

    const refreshSeceret = process.env.REFRESH_KEY;

    console.log('\n **********Using secret:', refreshSeceret);

    payload = jwt.verify(token, refreshSeceret);

    //   (err, payload) => {
    //   if (err) {
    //     console.error('JWT error:', err);
    //   } else {
    //     console.log('Payload OK:', payload);
    //   }
    // });
  } catch (error) {
    console.log('verification failed', error);
    throw new Error('Invalid or expired refresh token');
  }

  const userId = payload.id;
  const jwt_id = payload.jwt_id;

  console.log('  ID  :  ', userId, jwt_id);

  const client = await pool.connect();

  try {
    // Start Transaction
    await client.query('BEGIN');

    // 3. Find token by jwt_id
    const result = await client.query(
      `SELECT * FROM refresh_tokens WHERE jwt_id = $1`,
      [jwt_id]
    );

    const storedToken = result.rows[0];

    // if token is not in database
    if (!storedToken) {
      throw new Error('Invalid refresh token');
    }

    // Network issue period.

    if (storedToken.revoked_at) {
      const revokedTime = new Date(storedToken.revoked_at).getTime();
      const now = Date.now();
      const timeSinceRevoked = now - revokedTime;

      if (timeSinceRevoked <= 60000) {
        // User's internet likely dropped. Allow rotation to proceed.
        console.warn(
          `[Network Retry] Grace period utilized for user ${userId}`
        );
      } else {
        // REPLAY ATTACK
        // Token was revoked more than 60s ago. A hacker is trying to use it.
        await revokeAllUserSessions(userId);
        throw new Error('Token reuse detected. All sessions revoked.');
      }
    }

    // 6. Compare hashed token
    const isMatch = await compareToken(token, storedToken.token_hash);
    if (!isMatch) {
      await revokeAllUserSessions(userId);
      throw new Error('Token mismatch');
    }

    // 7. Device/IP check
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

    // await pool.query(
    //   `INSERT INTO refresh_tokens(user_id, token_hash, jwt_id, ip, user_agent, expires_at)
    //  VALUES($1,$2,$3,$4,$5, NOW() + interval '30 days')`,
    //   [user.user_id, tokenHash, jwt_id, ip, userAgent]
    // );

    await client.query(
      `INSERT INTO refresh_tokens(user_id, token_hash, jwt_id, ip, user_agent, expires_at)
       VALUES($1, $2, $3, $4, $5, NOW() + interval '7 days')`,
      [userId, newHash, newjwt_id, ip, userAgent]
    );
    console.log('after query');

    //COMMIT TRANSACTION ---- if we made it here without errors, permanently save all pool changes
    await client.query('COMMIT');

    console.log(
      'new refresh token is generated and saved to db in service layer'
    );

    return {
      newAccessToken,
      newRefreshToken,
    };
  } catch (error) {
    console.log('error in DB query service layer refresh : ', error);
    await client.query('ROLLBACK');
    throw error;
    client.release();
  }
};

export const logout = async (refreshToken) => {
  if (!refreshToken) return;

  let payload;

  try {
    payload = jwt.verify(refreshToken, process.env.REFRESH_KEY);
  } catch {
    // token invalid -->  nothing to revoke
    return;
  }

  const { jwt_id } = payload;

  if (!jwt_id) return;

  // revoke that session
  await pool.query(
    `UPDATE refresh_tokens 
     SET revoked = true 
     WHERE jwt_id = $1`,
    [jwt_id]
  );
};

export const logoutAll = async (userId) => {
  await pool.query(
    `UPDATE refresh_tokens 
     SET revoked = true 
     WHERE user_id = $1`,
    [userId]
  );
};
