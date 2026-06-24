/**
 * Express Server Entry Point
 * Starts the HTTP server and handles graceful shutdown
 */

import app from './src/app.js';
import dotenv from 'dotenv';
import https from 'https';
import fs from 'fs';

// Load environment variables
dotenv.config();

// see if you are using it in local env and want to test https or face issues with sameSite = none
// use this self signed certificate

// certs
// const keyPath = path.dirname('./');
// const options = {
//   key: fs.readFileSync('./server.key'),
//   cert: fs.readFileSync('./server.cert'),
// };

// console.log(options);

// start HTTPS server
// const server = https.createServer(options, app).listen(5000, () => {
//   console.log('Server running at  https://${HOST}:${PORT}');
// });

// const server = https.createServer(app).listen(PORT, HOST, () => {
//   console.log(`Server running at  https://${HOST}:${PORT}`);
// });

//for localhost ---

// const server = app.listen(PORT, () =>
//   console.log('Server running on http://localhost:5000')
// );

// for prod ----

const PORT = process.env.PORT || 5000;
// const HOST = process.env.HOST || 'localhost';
// docker fix:
const HOST = process.env.HOST || '0.0.0.0';

const server = app.listen(PORT, HOST, () =>
  console.log('Server running on http://localhost:5000')
);

// Handle graceful shutdown on SIGTERM or SIGINT

const gracefulShutdown = (signal) => {
  console.log(`\n ${signal} received, shutting down gracefully...`);

  server.close(() => {
    console.log('Server closed successfully');
    process.exit(0);
  });

  // Force shutdown after 10 seconds if graceful shutdown fails
  setTimeout(() => {
    console.error(' Forcing shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

/*
 * Unhandled promise rejection handler
 */
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

/**
 * Uncaught exception handler
 */
process.on('uncaughtException', (error) => {
  console.error(' Uncaught Exception:', error);
  process.exit(1);
});

export default server;
