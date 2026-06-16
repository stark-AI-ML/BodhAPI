import jwt from 'jsonwebtoken';

export const authMiddleware = (req, res, next) => {
  const token = req.cookies.accessToken;
  const cookie = req.cookie;

  const ip = req.ip;

  console.log('cookie : ', cookie);
  console.log('token', token);

  console.log('ip', ip);

  if (!token) {
    return res.status(401).json({ message: 'No token' });
  }

  try {
    const payload = jwt.verify(token, process.env.ACCESS_KEY);

    req.user = payload;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
};
