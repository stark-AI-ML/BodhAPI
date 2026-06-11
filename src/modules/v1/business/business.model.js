import { pool } from '../../../config/dbConfig.js';

//shared column
const BASE_COLUMNS = `
  headline,
  summary,
  category,
  sentiment,
  importance_score,
  broadcast_date
`;

const FINANCE_COLUMNS = `
  headline,
  summary,
  category,
  sentiment,
  importance_score,
  broadcast_date,
  financial_type,
  financial_amount,
  financial_currency,
  financial_denomination,
  financial_status,
  financial_industries
`;

// 1 Today's business news

export const fetchTodayBusinessNews = async (limit = 30) => {
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date = CURRENT_DATE
      AND category IN ('Economy', 'Infrastructure')
    ORDER BY importance_score DESC, id DESC
    LIMIT $1;
  `;

  const { rows } = await pool.query(query, [limit]);
  return rows;
};

// 2 Top business News
// for testing purpose i set the interval for last 3 days but if you see it or revisit do change it chutiyea

export const fetchTopBusinessNews = async (limit = 40) => {
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND broadcast_date <= CURRENT_DATE
      AND category IN ('Economy', 'Infrastructure')
      AND importance_score >= 7
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $1;
  `;

  const { rows } = await pool.query(query, [limit]);
  return rows;
};

// 3 Tech news

export const fetchTechNews = async (limit = 30) => {
  const query = `
    SELECT ${BASE_COLUMNS}, tags, financial_industries
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND broadcast_date <= CURRENT_DATE
      AND (
        tags ?| ARRAY['tech', 'IT', 'AI', 'startup', 'software', 'technology']
        OR financial_industries @> '["Tech"]'::jsonb
        OR financial_industries @> '["IT"]'::jsonb
        OR financial_industries @> '["AI"]'::jsonb
        OR financial_industries @> '["Software"]'::jsonb
        OR financial_industries @> '["Technology"]'::jsonb
      )
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $1;
  `;

  const { rows } = await pool.query(query, [limit]);
  return rows;
};

//4 Finance news
export const fetchFinanceNews = async (limit = 30) => {
  const query = `
    SELECT ${FINANCE_COLUMNS}
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND broadcast_date <= CURRENT_DATE
      AND financial_type IS NOT NULL
      AND financial_amount IS NOT NULL
    ORDER BY financial_amount DESC, importance_score DESC
    LIMIT $1;
  `;

  const { rows } = await pool.query(query, [limit]);
  return rows;
};

// 5 Business news by sentiment
export const fetchSentimentBusinessNews = async (
  sentiment = 'Positive',
  limit = 30
) => {
  const query = `
    SELECT ${BASE_COLUMNS}
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 days'
      AND broadcast_date <= CURRENT_DATE
      AND category IN ('Economy', 'Infrastructure')
      AND sentiment = $1
    ORDER BY importance_score DESC, broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [sentiment, limit]);
  return rows;
};

// 6 Business News by State
export const fetchStateBusinessNews = async (stateName, limit = 30) => {
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
      AND n.broadcast_date <= CURRENT_DATE
      AND n.category IN ('Economy', 'Infrastructure')
      AND LOWER(s.name) = LOWER($1)
    ORDER BY n.importance_score DESC, n.broadcast_date DESC
    LIMIT $2;
  `;

  const { rows } = await pool.query(query, [stateName, limit]);
  return rows;
};
