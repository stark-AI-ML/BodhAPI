import bcrypt from 'bcrypt';

export const hashToken = async (token) => {
  return bcrypt.hash(token, 10);
};

export const compareToken = async (token, hash) => {
  return bcrypt.compare(token, hash);
};
