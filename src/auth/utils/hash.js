import bcrypt from 'bcrypt';

import crypto from 'crypto';
export const hashToken = async (token) => {
  return bcrypt.hash(token, 10);
};

export const compareToken = async (token, hash) => {
  return bcrypt.compare(token, hash);
};
// see the below is for apiKey and the above is for the refreshToken i.e jwt

export const compareAPIHash = async (token, hash) => {
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

  return tokenHash == hash;
};
