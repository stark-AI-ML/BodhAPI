import express from 'express';
import { initializeSecurityMiddleware } from './middleware/securityPipeline.js';

import generalRoutes from './modules/v1/general/general.route.js';

import businessRoutes from './modules/v1/business/business.routes.js';
import cors from 'cors';
const app = express();

import authRouter from './routes/auth.route.js';

import sessionRouter from './auth/routes/session.route.js';

import cookieParser from 'cookie-parser';

// Initialize comprehensive security middleware pipeline

import apiSession from './auth/routes/apiSession.route.js';
import { apiKeyMiddleware } from './auth/middleware/apiKey.Middleware.js';
import { rateLimitMiddleware } from './auth/middleware/apiKey.rateLimiter.js';

app.use(cookieParser());
initializeSecurityMiddleware(app);

// fix for prod  : as i have face this recreation of img so will put config in .env always
// and in future mayhave multiple origins to call from so processing it as array :

const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: function (origin, callback) {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
  })
);

app.set('trust proxy', true); // for user agents and a req.ip
app.use('/auth', authRouter);

app.post('/refresh', sessionRouter);
app.post('/logout', sessionRouter);

app.use('/api', apiKeyMiddleware, apiSession);

// General API routes
app.use('/api', apiKeyMiddleware, rateLimitMiddleware, generalRoutes);

// Business API routes
app.use('/api', apiKeyMiddleware, businessRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
  });
});

//error handle

// 404 Not Found handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('[ERROR]', err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    success: false,
    message,
    error: process.env.NODE_ENV === 'development' ? err : undefined,
  });
});

export default app;
