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

app.use(cookieParser());
initializeSecurityMiddleware(app);

app.use(
  cors({
    origin:
      process.env.NODE_ENV === 'production'
        ? 'https://yourdomain.com'
        : 'http://localhost:3000',
    credentials: true,
  })
);
app.use('/auth', authRouter);

app.post('/refresh', sessionRouter);
app.post('/logout', sessionRouter);

app.use('/api', apiSession);

// General API routes
app.use('/api', generalRoutes);

// Business API routes
app.use('/api', businessRoutes);

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
