//  for container stdout and stderr

// import winston from 'winston';

// const logger = winston.createLogger({
//   level: process.env.LOG_LEVEL || 'info',
//   format: winston.format.combine(
//     winston.format.timestamp(),
//     winston.format.json()
//   ),
//   transports: [new winston.transports.Console()], // stdout/stderr only
// });

// export default logger;

import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    // Console output
    new winston.transports.Console(),

    // Save all logs to app.log
    new winston.transports.File({ filename: 'app.log' }),

    // Save only errors to errors.log
    new winston.transports.File({ filename: 'errors.log', level: 'error' }),
  ],
});

export default logger;
