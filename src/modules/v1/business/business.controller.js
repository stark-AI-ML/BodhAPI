import * as service from "./business.service.js";
import RedisKeyGenerator from "../../../utils/redisKeyGenerator.js";
import * as validation from "./business.validation.js";

export const getTodayNews = async (req, res) => {
  try {
    const limitValidation = validation.validateTodayNews(req);
    if (!limitValidation.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: limitValidation.error,
      });
    }

    const limit = limitValidation.value;
    const key = RedisKeyGenerator.todayKey("business", limit);
    const data = await service.getBusinessTodayNews(key, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Today's business news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching today's business news",
      error: error.message,
    });
  }
};

export const getTopNews = async (req, res) => {
  try {
    const limitValidation = validation.validateTopNews(req);
    if (!limitValidation.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: limitValidation.error,
      });
    }

    const limit = limitValidation.value;
    const key = RedisKeyGenerator.topKey("business", limit);
    const data = await service.getBusinessTopNews(key, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Top business news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching top business news",
      error: error.message,
    });
  }
};

export const getTechNews = async (req, res) => {
  try {
    const limitValidation = validation.validateTechNews(req);
    if (!limitValidation.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: limitValidation.error,
      });
    }

    const limit = limitValidation.value;
    const key = RedisKeyGenerator.generate("business", "tech", limit);
    const data = await service.getBusinessTechNews(key, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Tech business news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching tech business news",
      error: error.message,
    });
  }
};

export const getFinanceNews = async (req, res) => {
  try {
    const validation_result = validation.validateFinanceNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { limit } = validation_result;
    const key = RedisKeyGenerator.generate("business", "finance", limit);
    const data = await service.getBusinessFinanceNews(key, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Finance news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching finance news",
      error: error.message,
    });
  }
};

export const getSentimentNews = async (req, res) => {
  try {
    const validation_result = validation.validateSentimentNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { sentiment, limit } = validation_result;
    const key = RedisKeyGenerator.sentimentKey("business", sentiment, limit);
    const data = await service.getBusinessSentimentNews(key, sentiment, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Business news by sentiment fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching business news by sentiment",
      error: error.message,
    });
  }
};

export const getStateNews = async (req, res) => {
  try {
    const validation_result = validation.validateStateNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { state, limit } = validation_result;
    const key = RedisKeyGenerator.stateKey("business", state, limit);
    const data = await service.getBusinessStateNews(key, state, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Business news by state fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching business news by state",
      error: error.message,
    });
  }
};
