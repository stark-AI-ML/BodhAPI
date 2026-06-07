import * as service from "./general.service.js";
import RedisKeyGenerator from "../../../utils/redisKeyGenerator.js";
import * as validation from "./general.validation.js";

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
    const key = RedisKeyGenerator.todayKey("general", limit);
    const data = await service.getGeneralTodayNews(key, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Today's news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching today's news",
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
    const key = RedisKeyGenerator.topKey("general", limit);
    const data = await service.getGeneralTopNews(key, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Top news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching top news",
      error: error.message,
    });
  }
};

export const getCrimeNews = async (req, res) => {
  try {
    const validation_result = validation.validateCrimeNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { severity, limit } = validation_result;
    const key = RedisKeyGenerator.crimeKey("general", severity, limit);
    const data = await service.getCrimeNews(key, severity, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Crime news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching crime news",
      error: error.message,
    });
  }
};

export const getEntitiesNews = async (req, res) => {
  try {
    const validation_result = validation.validateEntitiesNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { person, organization, limit } = validation_result;
    const key = RedisKeyGenerator.entitiesKey(
      "general",
      person,
      organization,
      limit,
    );
    const data = await service.getEntitiesNews(
      key,
      person,
      organization,
      limit,
    );

    res.status(200).json({
      success: true,
      data,
      message: "News by entities fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching news by entities",
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
    const key = RedisKeyGenerator.sentimentKey("general", sentiment, limit);
    const data = await service.getSentimentsNews(key, sentiment, limit);

    res.status(200).json({
      success: true,
      data,
      message: "News by sentiment fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching news by sentiment",
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
    const key = RedisKeyGenerator.stateKey("general", state, limit);
    const data = await service.getStateNews(key, state, limit);

    res.status(200).json({
      success: true,
      data,
      message: "News by state fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching news by state",
      error: error.message,
    });
  }
};

export const getEmergencyNews = async (req, res) => {
  try {
    const validation_result = validation.validateEmergencyNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { emergencyType, limit } = validation_result;
    const key = RedisKeyGenerator.generate("general", "emergency", limit, {
      emergencyType,
    });
    const data = await service.getEmergencyNews(key, emergencyType, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Emergency news fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching emergency news",
      error: error.message,
    });
  }
};

export const getCategoryNews = async (req, res) => {
  try {
    const validation_result = validation.validateCategoryNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { category, limit } = validation_result;
    const key = RedisKeyGenerator.generate("general", "category", limit, {
      category,
    });
    const data = await service.getCategoryNews(key, category, limit);

    res.status(200).json({
      success: true,
      data,
      message: "News by category fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching news by category",
      error: error.message,
    });
  }
};

export const getSearchNews = async (req, res) => {
  try {
    const validation_result = validation.validateSearchNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { query, limit } = validation_result;
    const key = RedisKeyGenerator.generate("general", "search", limit, {
      query: query.replace(/\s+/g, "_"),
    });
    const data = await service.getSearchNews(key, query, limit);

    res.status(200).json({
      success: true,
      data,
      message: "Search results fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error searching news",
      error: error.message,
    });
  }
};

export const getTagsNews = async (req, res) => {
  try {
    const validation_result = validation.validateTagsNews(req);
    if (!validation_result.isValid) {
      return res.status(400).json({
        success: false,
        message: "error : use correct route (url) || contrains",
        error: validation_result.error,
      });
    }

    const { tag, limit } = validation_result;
    const key = RedisKeyGenerator.generate("general", "tags", limit, {
      tag: tag.replace(/\s+/g, "_"),
    });
    const data = await service.getTagsNews(key, tag, limit);

    res.status(200).json({
      success: true,
      data,
      message: "News by tag fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Error fetching news by tag",
      error: error.message,
    });
  }
};
