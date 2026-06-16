// routes/auth.js
import express from 'express';
import jwt from 'jsonwebtoken';
import passport from '../auth/config/googleOauthConfigAndSave.js';
import * as apiController from '../auth/controllers/apiKey.controller.js';
const router = express.Router();

import { createSession } from '../auth/controllers/session.controller.js';

// import usersession from '../auth/routes/session.route.js';
import * as controller from '../auth/controllers/auth.controller.js';

router.get(
  '/google',
  passport.authenticate('google', { scope: ['email', 'profile'] })
);

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

router.get(
  '/google/callback',
  passport.authenticate('google', { session: false }),
  controller.googleCallback
);

router.get('/me', controller.authMeVerification);

router.post('/generate-key', apiController.generateApiKey);

router.get('/logout', (req, res) => {
  res.clearCookie('accessToken');
  res.clearCookie('refreshToken');
  res.json({ success: true });
});

export default router;
