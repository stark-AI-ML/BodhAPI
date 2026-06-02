-- =========================================================
-- 1. ENUM TYPES
-- =========================================================
CREATE TYPE news_category AS ENUM (
    'Economy',
    'Infrastructure',
    'Politics',
    'Crime',
    'Science',
    'Geopolitics',
    'Emergency'
);
CREATE TYPE impact_scope_type AS ENUM (
    'Local',
    'District',
    'State',
    'National',
    'International'
);
CREATE TYPE crime_severity AS ENUM (
    'NONE',
    'LOW',
    'MODERATE',
    'EXTREME'
);
CREATE TYPE emergency_type AS ENUM (
    'NONE',
    'PUBLIC_HEALTH',
    'NATURAL_DISASTER',
    'WAR_CONFLICT',
    'CIVIL_UNREST'
);
CREATE TYPE sentiment_type AS ENUM (
    'Positive',
    'Neutral',
    'Negative'
);
-- =========================================================
-- 2. LOOKUP TABLES
-- =========================================================
CREATE TABLE states (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE districts (
    id BIGSERIAL PRIMARY KEY,
    state_id BIGINT NOT NULL
        REFERENCES states(id)
        ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    UNIQUE(state_id, name)
);
-- =========================================================
-- 3. MAIN NEWS TABLE
-- =========================================================
CREATE TABLE news_all (
    -- BIGSERIAL is faster and smaller than UUID
    id BIGSERIAL,
    headline TEXT NOT NULL,
    summary TEXT,
    category news_category NOT NULL,
    impact_scope impact_scope_type NOT NULL,
    importance_score SMALLINT NOT NULL DEFAULT 1
        CHECK (importance_score BETWEEN 1 AND 10),
    sentiment sentiment_type DEFAULT 'Neutral',
    crime_severity crime_severity NOT NULL DEFAULT 'NONE',
    emergency_type emergency_type NOT NULL DEFAULT 'NONE',
    is_national BOOLEAN NOT NULL DEFAULT false,
    state_id BIGINT
        REFERENCES states(id),
    district_id BIGINT
        REFERENCES districts(id),
    -- JSONB metadata
    tags JSONB NOT NULL DEFAULT '[]',
    entities JSONB NOT NULL DEFAULT '{}',
    source_context JSONB NOT NULL DEFAULT '{}',
    -- Financial metadata
    financial_type VARCHAR(50),
    financial_amount NUMERIC(18,2),
    financial_currency VARCHAR(10),
    financial_denomination VARCHAR(20),
    financial_status VARCHAR(50),
    financial_industries JSONB NOT NULL DEFAULT '[]',
    -- Time
    broadcast_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    -- Partitioned tables require partition key in PK
    PRIMARY KEY (id, broadcast_date)
)


PARTITION BY RANGE (broadcast_date);
-- =========================================================
-- 4. EXAMPLE MONTHLY PARTITION
-- =========================================================
CREATE TABLE news_all_2026_04
PARTITION OF news_all
FOR VALUES FROM ('2026-04-01')
TO ('2026-05-01');
-- =========================================================
-- 5. INDEXES
-- =========================================================
-- ---------------------------------------------------------
-- BRIN index for huge time-series efficiency
-- Much smaller than BTREE for append-heavy workloads
-- ---------------------------------------------------------
CREATE INDEX idx_news_broadcast_date_brin
ON news_all
USING BRIN (broadcast_date);
-- ---------------------------------------------------------
-- Category + sentiment filtering
-- ---------------------------------------------------------
CREATE INDEX idx_news_category_sentiment
ON news_all (category, sentiment);
-- ---------------------------------------------------------
-- Location-based filtering
-- ---------------------------------------------------------
CREATE INDEX idx_news_state_district_date
ON news_all (
    state_id,
    district_id,
    broadcast_date
);
-- ---------------------------------------------------------
-- GIN index for tags
-- ---------------------------------------------------------
CREATE INDEX idx_news_tags_gin
ON news_all
USING GIN (tags);
-- ---------------------------------------------------------
-- Partial GIN index for entities
-- Saves substantial storage if many rows are empty
-- ---------------------------------------------------------
CREATE INDEX idx_news_entities_gin
ON news_all
USING GIN (entities)
WHERE entities <> '{}';
-- ---------------------------------------------------------
-- Search optimization for headlines
-- Optional but highly recommended
-- ---------------------------------------------------------
CREATE INDEX idx_news_headline_search
ON news_all
USING GIN (
    to_tsvector('english', headline)
);
