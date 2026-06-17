import jwt from 'jsonwebtoken';

import { pool } from '../../config/dbConfig.js';
import { getTTL } from './tokenTTl.config.js';

export const generateAccessToken = (payload) => {
  return jwt.sign(payload, process.env.ACCESS_KEY, {
    expiresIn: getTTL('accessToken', 'integer'),
  });
};

// see for login paylod is given by user i.e here google_Oauth but for the
// acess token to refresh there is no payload so you must fetch it with user_id the reason we put
// the user_id in refresh token in first place

export const generateAccessTokenWithUser_ID = async (user_id) => {
  console.log('user id from acessToeknwith user_id', user_id);

  const query = `
    SELECT id, google_id, email, picture_url, name, plan_id
    FROM users
     WHERE id = $1;
  `;

  /////////////its breaking heresssss

  const result = await pool.query(query, [user_id]);

  console.log('acess_with  :       (( ', result.rows[0]);

  if (result.rows.length === 0) {
    console.log('breaked here in acesswith userid');
    throw new Error('User not found');
  }

  const user = result.rows[0];

  const payload = {
    user_id: user.id,
    google_id: user.google_id,
    email: user.email,
    picture: user.picture_url,
    display_name: user.name,
    plan_id: user.plan_id ?? 1, // /bug yk why default was 1 and still isby both db and you
  };

  return generateAccessToken(payload);
};

//------------- /test

// generateAccessTokenWithUser_ID('2cfef765-be93-4f01-b96f-88f2b2b2ec39');

export const generateRefreshToken = (payload) => {
  return jwt.sign(payload, process.env.REFRESH_KEY, {
    expiresIn: getTTL('accessToken', 'integer'),
  });
};
