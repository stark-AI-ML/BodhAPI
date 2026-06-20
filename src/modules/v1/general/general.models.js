import { pool } from '../../../config/dbConfig.js';

/**
 * General News Model
 *
 * Queries leverage existing indexes:
 * - idx_news_broadcast_date_brin (BRIN on broadcast_date)
 * - idx_news_category_sentiment (category, sentiment)
 * - idx_news_state_district_date (state_id, district_id, broadcast_date)
 * - idx_news_tags_gin (GIN on tags JSONB)
 * - idx_news_entities_gin (partial GIN on entities)
 * - idx_news_headline_search (GIN tsvector on headline)
 */

// ─── Shared column list ───

const BASE_COLUMNS = `
  headline,
  summary,
  category,
  sentiment,
  importance_score,
  broadcast_date
`;

// ─── 1. Today's News ───
export const fetchTodayNews = async (limit = 40) => {
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date = CURRENT_DATE
    ORDER BY importance_score DESC, id DESC
    LIMIT $1;
  `;

  const { rows } = await pool.query(query, [limit]);
  return rows;
};

// ─── 2. Top News (3-day, high importance) ───
export const fetchTopNews = async (limit = 30) => {
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND broadcast_date <= CURRENT_DATE
      AND importance_score >= 7
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $1;
  `;

  const { rows } = await pool.query(query, [limit]);
  return rows;
};

// ─── 3. Crime News by Severity ───
export const fetchCrimeNews = async (crimeSeverity, limit = 30) => {
  const query = `
    SELECT ${BASE_COLUMNS},
      crime_severity
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND crime_severity = $1
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [crimeSeverity, limit]);
  return rows;
};

// ─── 4. Entities News (person / organization) ───
export const fetchEntitiesNews = async (
  personName = null,
  organizationName = null,
  limit = 30
) => {
  const query = `
    SELECT ${BASE_COLUMNS},
      entities
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND ($1 IS NULL OR (entities->'people') ? $1)
      AND ($2 IS NULL OR (entities->'organizations') ? $2)
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $3;
  `;

  const { rows } = await pool.query(query, [
    personName,
    organizationName,
    limit,
  ]);
  return rows;
};

// ─── 5. Sentiment News ───
export const fetchSentimentsNews = async (
  sentiment = 'Positive',
  limit = 30
) => {
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND sentiment = $1
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [sentiment, limit]);
  return rows;
};

// ─── 6. State News ───
export const fetchStateNews = async (stateName, limit = 30) => {
  const query = `
    SELECT 
      n.headline,
      n.summary,
      n.category,
      n.sentiment,
      n.importance_score,
      n.broadcast_date,
      s.name AS state_name
    FROM news_all n
    INNER JOIN states s ON n.state_id = s.id
    WHERE n.broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND LOWER(s.name) = LOWER($1)
    ORDER BY n.importance_score DESC, n.broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [stateName, limit]);
  return rows;
};

// ─── 7. Emergency News [NEW] ───
export const fetchEmergencyNews = async (emergencyType, limit = 30) => {
  const query = `
    SELECT ${BASE_COLUMNS},
      emergency_type
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND emergency_type = $1
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [emergencyType, limit]);
  return rows;
};

// ─── 8. Category News [NEW] ───
export const fetchCategoryNews = async (category, limit = 30) => {
  // use idx_news_category_sentiment composite index
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND category = $1
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [category, limit]);
  return rows;
};

// ─── 9. Search News by Headline [NEW] ───
export const fetchSearchNews = async (searchQuery, limit = 30) => {
  // use idx_news_headline_search GIN index with to_tsvector
  const query = `
    SELECT ${BASE_COLUMNS},
      ts_rank(to_tsvector('english', headline), plainto_tsquery('english', $1)) AS relevance
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '7 days'
      AND to_tsvector('english', headline) @@ plainto_tsquery('english', $1)
    ORDER BY relevance DESC, importance_score DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [searchQuery, limit]);
  return rows;
};

// ─── 10. Tags News [NEW] ───
// jsonB object stored tags so we can accept the array of tags

export const fetchTagsNews = async (tag, limit = 30) => {
  const query = `
    SELECT ${BASE_COLUMNS},
      tags
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND tags ? $1
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [tag, limit]);
  return rows;
};

