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
