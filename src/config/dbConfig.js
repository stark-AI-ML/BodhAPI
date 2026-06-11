import { Pool } from 'pg';

import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();
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

// for local with .env

// const data = {
//   user: process.env.DB_USER,
//   host: process.env.HOST,
//   database: process.env.DB_NAME,

//   password: process.env.DB_PASSWORD,
//   // password: '#Postgress_3000',
//   port: process.env.DB_PORT,
// };

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
  host: process.env.HOST,
  database: process.env.DB_NAME,

  // password: process.env.DB_PASSWORD,
  password: '#Postgress_3000',
  port: process.env.DB_PORT,
});

export const redisConfig = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS,
});

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
