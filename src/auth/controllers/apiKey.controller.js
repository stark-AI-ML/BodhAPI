import * as apiKeyServices from '../services/apiKey.service.js';

import logger from '../../config/logger.js';

import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

export const generateApiKey = async (req, res, next) => {
  try {
    const token = req.cookies.accessToken;
    console.log('token from * apiKey  :  ', token);

    if (!token) return res.sendStatus(401);

    const payload = jwt.verify(token, process.env.ACCESS_KEY);

    const { prefix, fullKey } = await apiKeyServices.generateApiKey(
      payload.user_id,
      req.body.name
    );

    // just for test we need to send both prefix and full key frontent must show prefix only after once initialise
    res.json({ apiKey: fullKey });
  } catch (error) {
    console.error(error);
    logger.alert('unable to generate key');
  }
};

export const getApiKey = async (req, res, next) => {
  try {
    const token = req.cookies.accessToken;
    console.log('token from * apiKey  :  ', token);

    if (!token) return res.sendStatus(401);

    const payload = jwt.verify(token, process.env.ACCESS_KEY);

    const { prefix, fullKey } = await apiKeyServices.generateApiKey(
      payload.user_id,
      req.body.name
    );

    // just for test we need to send both prefix and full key frontent must show prefix only after once initialise
    res.json({ apiKey: fullKey });
  } catch (error) {}
};
