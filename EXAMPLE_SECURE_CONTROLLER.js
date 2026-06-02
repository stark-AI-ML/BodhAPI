/**
 * EXAMPLE: Properly Secured Controller
 * ====================================
 *
 * This is an example of how to implement controllers using the new
 * security and validation system. Use this as a template.
 */

import {
  validateQueryParameters,
  FIELD_VALIDATION_RULES,
} from "../middleware/validation/inputValidationRules.js";

/**
 * Get news with pagination and search
 *
 * Security features demonstrated:
 * - Input validation
 * - Error handling
 * - Safe database queries
 * - Formatted response
 */
export const getNewsWithPaginationAndSearch = async (request, response) => {
  try {
    // Define validation rules for incoming parameters
    const paginationValidationRules = {
      pageNumber: FIELD_VALIDATION_RULES.pageNumber,
      itemsPerPage: FIELD_VALIDATION_RULES.itemsPerPage,
      searchQuery: {
        ...FIELD_VALIDATION_RULES.searchQuery,
        required: false, // Search is optional
      },
    };

    // Validate all query parameters
    const validationResult = validateQueryParameters(
      request.query,
      paginationValidationRules,
    );

    // If there are validation errors, return them
    if (validationResult.hasErrors) {
      return response.status(400).json({
        success: false,
        errors: validationResult.errors,
        message: "Invalid request parameters",
      });
    }

    // Extract validated data (now 100% safe to use)
    const {
      pageNumber = 1,
      itemsPerPage = 10,
      searchQuery = null,
    } = validationResult.validatedData;

    // Call service layer with validated data
    const newsResults = await fetchNewsFromService({
      pageNumber,
      itemsPerPage,
      searchQuery,
    });

    // Format and return response
    return response.status(200).json({
      success: true,
      data: newsResults.articles,
      pagination: {
        currentPage: pageNumber,
        itemsPerPage: itemsPerPage,
        totalItems: newsResults.totalCount,
        totalPages: Math.ceil(newsResults.totalCount / itemsPerPage),
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error("[ERROR] getNewsWithPaginationAndSearch:", error);

    return response.status(500).json({
      success: false,
      error: "Failed to retrieve news articles",
      message:
        process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};

/**
 * Get news by category
 *
 * Demonstrates:
 * - URL parameter validation
 * - Category filtering
 * - Proper error codes
 */
export const getNewsByCategory = async (request, response) => {
  try {
    // Validate category from URL params
    const categoryValidationRules = {
      category: {
        type: "string",
        pattern: /^[a-zA-Z0-9_\-]{3,30}$/,
        required: true,
        fieldName: "Category",
      },
    };

    const validationResult = validateQueryParameters(
      { category: request.params.category },
      categoryValidationRules,
    );

    if (validationResult.hasErrors) {
      return response.status(400).json({
        success: false,
        errors: validationResult.errors,
      });
    }

    const { category } = validationResult.validatedData;

    // Fetch from service
    const newsArticles = await fetchNewsByCategoryFromService(category);

    if (!newsArticles || newsArticles.length === 0) {
      return response.status(404).json({
        success: false,
        error: "No articles found in this category",
      });
    }

    return response.status(200).json({
      success: true,
      category,
      data: newsArticles,
      count: newsArticles.length,
    });
  } catch (error) {
    console.error("[ERROR] getNewsByCategory:", error);

    return response.status(500).json({
      success: false,
      error: "Failed to retrieve category news",
    });
  }
};

/**
 * Search news articles
 *
 * Demonstrates:
 * - Complex search with multiple parameters
 * - Optional parameters
 * - Safe query building
 */
export const searchNewsArticles = async (request, response) => {
  try {
    // Multiple validation rules for search
    const searchValidationRules = {
      keyword: {
        ...FIELD_VALIDATION_RULES.searchQuery,
        required: true,
      },
      startDate: {
        type: "string",
        pattern: /^\d{4}-\d{2}-\d{2}$/, // YYYY-MM-DD
        required: false,
        fieldName: "Start date",
      },
      endDate: {
        type: "string",
        pattern: /^\d{4}-\d{2}-\d{2}$/,
        required: false,
        fieldName: "End date",
      },
      sortBy: {
        type: "string",
        pattern: /^(relevance|date|popularity)$/,
        required: false,
        fieldName: "Sort field",
      },
      pageNumber: FIELD_VALIDATION_RULES.pageNumber,
      itemsPerPage: FIELD_VALIDATION_RULES.itemsPerPage,
    };

    const validationResult = validateQueryParameters(
      request.query,
      searchValidationRules,
    );

    if (validationResult.hasErrors) {
      return response.status(400).json({
        success: false,
        errors: validationResult.errors,
      });
    }

    const {
      keyword,
      startDate = null,
      endDate = null,
      sortBy = "relevance",
      pageNumber = 1,
      itemsPerPage = 10,
    } = validationResult.validatedData;

    // Build safe search query
    const searchCriteria = {
      keyword,
      dateRange: startDate && endDate ? { startDate, endDate } : null,
      sortBy,
      pagination: {
        pageNumber,
        itemsPerPage,
      },
    };

    const results = await performSecureNewsSearch(searchCriteria);

    return response.status(200).json({
      success: true,
      searchCriteria: {
        keyword,
        dateRange: searchCriteria.dateRange,
      },
      results: results.articles,
      pagination: {
        currentPage: pageNumber,
        itemsPerPage,
        totalResults: results.totalCount,
      },
    });
  } catch (error) {
    console.error("[ERROR] searchNewsArticles:", error);

    return response.status(500).json({
      success: false,
      error: "Search failed",
    });
  }
};

/**
 * Service layer example (safe database queries)
 * This would be in a separate service file
 */
async function fetchNewsFromService({ pageNumber, itemsPerPage, searchQuery }) {
  // CORRECT: Using parameterized query
  const offset = (pageNumber - 1) * itemsPerPage;

  let query = "SELECT * FROM news_articles";
  const queryParams = [];

  if (searchQuery) {
    query += " WHERE title ILIKE $1 OR content ILIKE $1";
    queryParams.push(`%${searchQuery}%`);
  }

  query += ` ORDER BY published_date DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
  queryParams.push(itemsPerPage, offset);

  // Database connection executes with parameterized values
  const results = await database.query(query, queryParams);

  return {
    articles: results.rows,
    totalCount: results.rowCount,
  };
}

/**
 * ❌ WRONG - DO NOT DO THIS:
 *
 * async function unsafeNewsQuery(searchQuery, pageNumber) {
 *   // VULNERABLE to SQL injection!
 *   const query = `SELECT * FROM news WHERE title LIKE '%${searchQuery}%' LIMIT 10 OFFSET ${pageNumber * 10}`;
 *   return database.query(query);
 * }
 */

/**
 * ✅ CORRECT - Always use parameterized queries:
 *
 * async function safeNewsQuery(searchQuery, pageNumber) {
 *   const query = `
 *     SELECT * FROM news
 *     WHERE title ILIKE $1
 *     LIMIT 10 OFFSET $2
 *   `;
 *   return database.query(query, [searchQuery, pageNumber * 10]);
 * }
 */

export { fetchNewsFromService };
