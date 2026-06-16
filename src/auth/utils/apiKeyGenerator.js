import crypto from 'crypto';

const createKey = async () => {
  const publicPart = crypto.randomBytes(6).toString('hex');
  const secretPart = crypto.randomBytes(18).toString('hex');

  const prefix = `bodh_live_${publicPart}`;
  const fullKey = `${prefix}_${secretPart}`;

  return { prefix, fullKey };
};

export default createKey;
