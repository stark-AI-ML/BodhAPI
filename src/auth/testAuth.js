// import e from 'express';
// import jwt from 'jsonwebtoken';
// import passport from './auth.js'; // import the configured passport

// const app = e();

// //login
// app.get(
//   '/auth/google',
//   passport.authenticate('google', { scope: ['email', 'profile'] })
// );

// //callback to our page
// app.get(
//   '/google/callback',
//   passport.authenticate('google', { session: false }),
//   (req, res) => {
//     const token = jwt.sign(
//       { google_id: req.user.google_id, email: req.user.email },
//       process.env.JWT_SECRET,
//       { expiresIn: '1h' }
//     );

//     res.cookie('jwt', token, { httpOnly: true, secure: true });
//     res.json({ message: 'Login successful', user: req.user });
//   }
// );

// app.listen(3000, () => console.log('Server running on http://localhost:3000'));
