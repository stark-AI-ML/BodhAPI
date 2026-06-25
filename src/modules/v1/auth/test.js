// test server on localhost
/*
import e from 'express';
import jwt from 'jsonwebtoken';

import passport from './auth.js';

import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

import { createSession } from '../../../auth/controllers/session.controller.js';
import { authMiddleware } from '../../../auth/middleware/authmiddleware.js';
import cookieParser from 'cookie-parser';
import sessionRoute from '../../../auth/routes/session.route.js';

import usersession from '../../../auth/routes/session.route.js';

import https from 'https';

const app = e();

app.use(cookieParser());
app.post('/refresh', usersession);

import fs from 'fs';

//login
app.get(
  '/auth/google',
  passport.authenticate('google', { scope: ['email', 'profile'] })
);

//callback to our page
app.get(
  '/auth/google/callback',
  passport.authenticate('google', { session: false }),
  async (req, res) => {
    // Extract only the necessary client metadata

    const metadata = {
      ip: req.ip || req.connection.remoteAddress,
      userAgent: req.headers['user-agent'] || 'Unknown Device',
    };

    console.log('loggin from /auth/google/callback :  ', req.user);

    const { accessToken, refreshToken } = await createSession(
      req.user,
      metadata
    );

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
  }
);

app.get('/dashboard', (req, res) => {
  res.json({ message: 'working fine' });
});

app.get('/protected', authMiddleware, (req, res) => {
  res.json({ message: 'working fine with the authmiddleware' });
});

// Add an auth check route just for the test in local host

app.get('/auth/me', async (req, res) => {
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
});

// Also add a logout route since the frontend calls this when clicking Sign Out
// see this is  for test purpose as this doesn't revoke the refreshToken from database
app.post('/auth/logout', (req, res) => {
  res.clearCookie('accessToken');
  res.clearCookie('refreshToken');
  res.json({ success: true });
});

// certs
const keyPath = path.dirname('./');
const options = {
  key: fs.readFileSync(path.join(keyPath, 'server.key')),
  cert: fs.readFileSync(path.join(keyPath, 'server.cert')),
};

console.log(options);

// app.listen(5000, () => console.log('Server running on http://localhost:5000'));

// start HTTPS server
https.createServer(options, app).listen(5000, () => {
  console.log('Server running at https://localhost:5000');
});


*/