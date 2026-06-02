import pool from "../../../config/dbConfig.js";

export const fetchTodayNews = async (limit = 40) => {
  const query = `
    SELECT 
      headline,
      summary,
      category,
      sentiment,
      importance_score, 
      broadcast_date

    FROM news_all
    WHERE  broadcast_date = CURRENT_DATE
    ORDER BY id DESC
    LIMIT $1;
  `;

  const values = [limit];
  const { rows } = await pool.query(query, values);

  return rows;
};

export const fetchTopNews = async (limit = 30) => {
  console.log("under top news model");
  const query = `
    SELECT 
    headline,
    summary,
    category,
    sentiment,
    importance_score, 
    broadcast_date
    FROM news_all
        WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 day'
        AND broadcast_date <= CURRENT_DATE
        AND importance_score >= 7
    ORDER BY broadcast_date DESC
    LIMIT $1;
  `;

  const values = [limit];
  const { rows } = await pool.query(query, values);
  return rows;
};

// console.log(await fetchTopNews());

// one more problem during test i find there is fixed contraints about crimeSeverity so i have to fix that too

export const fetchCrimeNews = async (crimeSeverity, limit = 30) => {
  const query = `
    SELECT
      headline,
      summary,
      category,
      sentiment,
      importance_score,
      broadcast_date
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 day'
      AND crime_severity = $1
    ORDER BY broadcast_date DESC
    LIMIT $2;
  `;

  const values = [crimeSeverity, limit];
  const { rows } = await pool.query(query, values);
  return rows;
};
// const data = await fetchCrimeNews("EXTREME", 30);

export const fetchEntitiesNews = async (
  personName = null,
  organizationName = null,
  limit = 30,
) => {
  const query = `
    SELECT 
      headline,
      summary,
      category,
      sentiment,
      importance_score, 
      broadcast_date
    FROM news_all
    WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 day'
  AND ($1 IS NULL OR (entities->'people') ? $1)
  AND ($2 IS NULL OR (entities->'organizations') ? $2)
ORDER BY broadcast_date DESC
    LIMIT $3;
  `;

  const values = [personName, organizationName, limit];
  const { rows } = await pool.query(query, values);
  return rows;
};

export const fetchSentimentsNews = async (
  sentiment = "POSITIVE",
  limit = 30,
) => {
  // i am subractin Interval here from 1 Day to 3 day but make sure it is one if you revisit this
  const query = `
    SELECT 
        headline, 
        summary, 
        category,
        sentiment, 
        importance_score, 
        broadcast_date
    FROM news_all
   WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 day'
  AND sentiment = $1
ORDER BY broadcast_date DESC
    `;

  const values = [sentiment, limit];
  const { rows } = await pool.query(query, values);
  return rows;
};

export const fetchStateNews = async (stateName = null, limit = 30) => {
  const query = `
SELECT 
  headline, 
  summary, 
  category, 
  importance_score, 
  broadcast_date
FROM news_all
WHERE broadcast_date >= CURRENT_DATE - INTERVAL '3 day'
  AND state_id = $1
ORDER BY broadcast_date DESC
LIMIT $2;
            
    `;

  const values = [stateName, limit];
  const { rows } = await pool.query(query, values);
  return rows;
};

// const data = await fetchEntitiesNews("Amit Shah", null, 30);

// console.log("hii  ", data);

// export default {
//   fetchTodayNews,
//   fetchCrimeNews,

//   fetchEntitiesNews,
//   fetchSentiments,
//   fetchStateNews,
// };
