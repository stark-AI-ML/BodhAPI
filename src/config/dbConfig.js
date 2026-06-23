import { Pool } from 'pg';

import Redis from 'ioredis';
import dotenv from 'dotenv';

import fs from 'fs';

dotenv.config();

//------------------------------
// for refrence if something breaks: please delete this before pushing to gihub when you will push by the way :)

// export const pool = new Pool({
//   user: 'postgres',
//   host: 'localhost',
//   database: 'news',

//   password: '#Postgress_3000',
//   port: 5432,
// });

// export const redisConfig = new Redis({
//   host: 'localhost',
//   port: 6379,
// });

// -----------------------------------
// for local with .env

// console.log(
//   data.user,
//   '\n',
//   data.host,
//   '\n',
//   data.database + ' ',
//   data.port,
//   data.user
// );

export const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,

  // password: process.env.DB_PASSWORD,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  ssl: false,

  //ssl
  // ssl: {
  //   key: fs.readFileSync('../../server.key'),
  //   cert: fs.readFileSync('../../server.cert'),
  //   // ca: fs.readFileSync('/app/ca.crt'),     // if you have a CA chain
  //   // rejectUnauthorized: true, // set false if self‑signed
  //   rejectUnauthorized: false,
  // },
});

// /important -------commented out thsi redisconfig just to save battery from runnig docker

export const redisConfig = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS,
});

// -------------------------------------------
// for docker

// export const pool = new Pool({
//   user: process.env.DB_USER,
//   host: 'postgres', // service name from docker-compose
//   database: 'news',
//   password: '#Postgress_3000',
//   port: 5432, // internal Postgres port
// });

// export const redisConfig = new Redis({
//   host: 'redis', // service name from docker-compose
//   port: 6379, // internal Redis port
//   family: 4,
// });
