import * as service from "./general.service.js";

/**
 * Get today's news
 * Query params: limit (default: 60)
 */
export const getTodayNews = async (req, res) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit) : 60;
    const data = await service.getGeneralTodayNews("general_today_60", limit);

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

/**
 * Get top news
 * Query params: limit (default: 40)
 */
export const getTopNews = async (req, res) => {
  try {
    const limit = req.query.limit ? parseInt(req.query.limit) : 40;
    const data = await service.getGeneralTopNews("general_top_40", limit);

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

/**
 * Get crime news by severity
 * Query params: severity (required), limit (default: 30)
 */
export const getCrimeNews = async (req, res) => {
  try {
    const { severity } = req.query;

    if (!severity) {
      return res.status(400).json({
        success: false,
        message: "Crime severity parameter is required",
      });
    }

    const limit = req.query.limit ? parseInt(req.query.limit) : 30;
    const key = `general_crime_${severity}_${limit}`;

    const data = await service.getCrimeNews(key, limit);

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

/**
 * Get news by entities (person and/or organization)
 * Query params: person, organization, limit (default: 30)
 */
export const getEntitiesNews = async (req, res) => {
  try {
    const { person, organization } = req.query;

    if (!person && !organization) {
      return res.status(400).json({
        success: false,
        message:
          "At least one entity parameter (person or organization) is required",
      });
    }

    const limit = req.query.limit ? parseInt(req.query.limit) : 30;
    const key = `general_entities_${person || "any"}_${organization || "any"}_${limit}`;

    const data = await service.getEntitiesNews(key, limit);

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

/**
 * Get news by sentiment
 * Query params: sentiment (default: POSITIVE), limit (default: 30)
 */
export const getSentimentNews = async (req, res) => {
  try {
    const sentiment = req.query.sentiment || "POSITIVE";
    const limit = req.query.limit ? parseInt(req.query.limit) : 30;
    const key = `general_sentiment_${sentiment}_${limit}`;

    const data = await service.getSentimentsNews(key, limit);

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

/**
 * Get news by state
 * Query params: state (required), limit (default: 30)
 */
export const getStateNews = async (req, res) => {
  try {
    const { state } = req.query;

    if (!state) {
      return res.status(400).json({
        success: false,
        message: "State parameter is required",
      });
    }

    const limit = req.query.limit ? parseInt(req.query.limit) : 30;
    const key = `general_state_${state}_${limit}`;

    const data = await service.getStateNews(key, limit);

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
