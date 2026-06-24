import { pool } from '../../config/dbConfig.js';
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: process.env.GOOGLE_CALLBACK_URL,
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const user = {
          google_id: profile.id,
          email: profile.emails?.[0]?.value,
          picture: profile.photos?.[0]?.value,
          display_name: profile.displayName,
        };

        // if user exists
        const query = `
          SELECT id, google_id, email, name, picture_url, plan_id
          FROM users
          WHERE google_id = $1
        `;
        const data = await pool.query(query, [user.google_id]);

        console.log('log from passport', data);

        let userId;

        if (data.rows.length === 0) {
          // Insert new user
          const insertQuery = `
            INSERT INTO users (google_id, email, name, picture_url, plan_id)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id
          `;
          const result = await pool.query(insertQuery, [
            user.google_id,
            user.email,
            user.display_name,
            user.picture,
            1, //  /bug i am setting default  val 1 which is not too good but not planning to chane now
          ]);

          userId = result.rows[0].id;
        } else {
          console.log('user exsists');
          userId = data.rows[0].id;
        }

        // adding user_id to user object make sure your jwt payload have it cuz i want fast search
        // based on google_id of refresh token and have index of user_id of refresh_token and user_id relation
        // when you wakeup or see fallow that rule:

        user.user_id = userId;

        user.plan_id = 1; //fix  /feature

        return done(null, user);
      } catch (err) {
        return done(err, null);
      }
    }
  )
);

export default passport;
