import { createSession } from './session.controller.js';

import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

import usersession from '../../auth/routes/session.route.js';

// /fix -- i you need to change the uri of redirect from oAuth as localhost now to when you will be in production

// router.get(
//   '/google/callback',
//   passport.authenticate('google', { session: false }),
//   (req, res) => {
//     const token = jwt.sign(
//       {
//         user_id: req.user_id,
//         google_id: req.user.google_id,
//         email: req.user.email,
//         picture: req.user.picture,
//         display_name: req.user.display_name,
//       },
//       process.env.JWT_SECRET,
//       { expiresIn: '30d' }
//     );

//     res.cookie('jwt', token, { httpOnly: true, secure: true });
//     res.json({ message: 'Login successful', user: req.user });
//   }
// );

export const googleCallback = async (req, res) => {
  const metadata = {
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.headers['user-agent'] || 'Unknown Device',
  };

  console.log('loggin from /auth/google/callback :  ', req.user);

  const { accessToken, refreshToken } = await createSession(req.user, metadata);

  console.log(
    'logging the acessToken and refreshToken : ',
    accessToken,
    '   :   ',
    refreshToken
  );

  res.cookie('accessToken', accessToken, {
    httpOnly: true,
    secure: true,
    sameSite: 'none',
    maxAge: 15 * 60 * 1000, // 15 mins
  });

  res.cookie('refreshToken', refreshToken, {
    httpOnly: true,
    secure: true,
    sameSite: 'none',
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
  });

  res.redirect('http://localhost:3000');
};

export const authMeVerification = async (req, res) => {
  try {
    console.log('/auth/me called');
    const token = req.cookies.accessToken;

    if (!token) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    // 2. Verify the JWT
    const decoded = jwt.verify(token, process.env.ACCESS_KEY);

    // 3. Fetch the latest user data from your DB (optional, or just use decoded)
    // const user = await pool.query('SELECT * FROM users WHERE id = $1', [decoded.id]);

    // 4. Send the user back to the frontend
    res.json({
      id: decoded.google_id,
      display_name: decoded.display_name,
      email: decoded.email,
      picture: decoded.picture, // Google profile image URL
    });
  } catch (error) {
    // If token is expired or invalid
    res.status(401).json({ error: 'Invalid session' });
  }
};
