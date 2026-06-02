import pool from "../../../config/dbConfig.js";

export const fetchTodayBusinessNews = async (limit = 30) => {
  const query = `SELECT 
        headline, 
        summary, 
        category, 
        sentiment, 
        importance_score, 
        broadcast_date

    FROM news_all 
    WHERE broadcast_date = CURRENT_DATE 
    AND news_category = "Economy"
    ORDER BY broadcast_date DESC
    LIMIT $1

    `;
  const values = [limit];
  const { rows } = await pool.query(query, values);
  return rows;
};

export const fetchTopBusinessNews = async (limit = 30) => {
  const query = `SELECT 
        headline, 
        summary, 
        category, 
        sentiment, 
        importance_score, 
        broadcast_date

    FROM news_all 
    WHERE broadcast_date = CURRENT_DATE - INTERVAL '1 day'
    AND news_category = "Economy"
    ORDER BY broadcast_date DESC
    LIMIT $1

    `;
  const values = [limit];
  const { rows } = await pool.query(query, values);
  return rows;
};

export const fetchTopTechNews = async (limit = 30) => {
  const query = `SELECT 
        headline, 
        summary, 
        category, 
        sentiment, 
        importance_score, 
        broadcast_date

    FROM news_all 
    WHERE broadcast_date = CURRENT_DATE - INTERVAL '1 day'
    AND  tags @> '["tech","IT,"AI" ]'
    OR  financial_industries @> '["Tech","IT","AI"]'
    ORDER BY broadcast_date DESC
    LIMIT $1
    
    `;

  const values = [limit];
  const { rows } = await pool.query(query, values);
  return rows;
};
