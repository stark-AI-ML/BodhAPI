import * as apiKeyServices from '../services/apiKey.service.js';

import logger from '../../config/logger.js';

import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

export const generateApiKey = async (req, res, next) => {
  try {
    const token = req.cookies.accessToken;
    console.log('token from * apiKey  :  ', token);

    if (!token) {
      return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }

    // if expired error will be thrown
    const payload = jwt.verify(token, process.env.ACCESS_KEY);

    const { prefix, fullKey } = await apiKeyServices.generateApiKey(
      payload.user_id,
      req.body.name
    );

    // just for test we need to send both prefix and full key frontent must show prefix only after once initialise
    return res.json({ apiKey: fullKey });
  } catch (error) {
    console.error('Error generating API key:', error);

    // Handle specific JWT Errors
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Unauthorized: Token has expired' });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }

    // Fallback for database or other internal server errors
    return res.status(500).json({ error: 'Internal server error' });
  }
};

export const getCurrentKeys = async (req, res, next) => {
  try {
    const token = req.cookies.accessToken;

    if (!token) return res.sendStatus(401);

    const payload = jwt.verify(token, process.env.ACCESS_KEY);

    const keys = await apiKeyServices.getApiKeys(payload.user_id);

    res.json(keys);
  } catch (error) {
    if (error.message == 'number of api_keys exceeded') {
      return res.status(403).json({ error: 'number of api_keys exceeded' });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Unauthorized: Token has expired' });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }

    if (error)
      // Fallback for database or other internal server errors
      return res.status(500).json({ error: 'Internal server error' });
    console.log(error);
    console.error(error);
    logger.info('unable to get keys ', error);
  }
};

export const deleteApiKey = async (req, res, next) => {
  try {
    const token = req.cookies.accessToken;

    if (!token) return res.sendStatus(401);

    const payload = jwt.verify(token, process.env.ACCESS_KEY);

    const deleteKey = await apiKeyServices.deleteApiKey(
      payload.user_id,
      req.key
    );

    res.json(deleteKey);
  } catch (error) {
    if (error.message == 'number of api_keys exceeded') {
      return res.status(403).json({ error: 'number of api_keys exceeded' });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Unauthorized: Token has expired' });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }

    if (error)
      // Fallback for database or other internal server errors
      return res.status(500).json({ error: 'Internal server error' });
    console.error(error);
    logger.info('unable to get keys ', error);
  }
};
