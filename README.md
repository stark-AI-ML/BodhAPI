# BodhAPI — Indian News Intelligence Engine

> A high-performance REST API that transforms raw Indian news broadcasts into structured, machine-readable intelligence. Built with Express 5, PostgreSQL (partitioned tables + BRIN indexes), and Redis caching for sub-millisecond repeated reads.

---

## Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Database Schema](#database-schema)
- [API Reference](#api-reference)
  - [Health Check](#health-check)
  - [General News](#general-news)
  - [Business News](#business-news)
- [Query Parameters](#query-parameters)
- [Response Format](#response-format)
- [Caching Strategy](#caching-strategy)
- [Security](#security)
- [Project Structure](#project-structure)

---

## Architecture

```
Client Request
     │
     ▼
┌──────────────────────────────────────────┐
│           Security Pipeline              │
│  Headers → Rate Limit → Sanitize → Body │
└──────────────────────────────────────────┘
     │
     ▼
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│    Route     │ ──▶ │   Controller     │ ──▶ │   Validation   │
│  (Express)   │     │ (Request/Response)│     │ (Input checks) │
└──────────────┘     └──────────────────┘     └────────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │   Service    │
                     │ (Cache layer)│
                     └──────┬───────┘
                       ┌────┴────┐
                       ▼         ▼
                 ┌─────────┐ ┌──────┐
                 │  Redis  │ │  PG  │
                 │ (Cache) │ │ (DB) │
                 └─────────┘ └──────┘
```

**Flow:** Route → Controller → Validation → Service → Redis (cache check) → Model (DB query) → Redis (cache set) → Response

---

## Tech Stack

| Layer        | Technology                         |
| ------------ | ---------------------------------- |
| Runtime      | Node.js (ES Modules)               |
| Framework    | Express 5                          |
| Database     | PostgreSQL (partitioned by month)  |
| Cache        | Redis (ioredis)                    |
| Auth         | bcrypt (hashing, future use)       |
| Dev Server   | Nodemon                            |

---

## Getting Started

### Prerequisites

- **Node.js** ≥ 18
- **PostgreSQL** ≥ 14 (with partitioning support)
- **Redis** ≥ 7

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd BodhAPI

# Install dependencies
npm install

# Set up your .env file (see Environment Variables below)
cp .env.example .env

# Create the database and run the schema
psql -U postgres -d news -f src/modules/v1/general/schema.sql

# Start development server
npm run dev

# Or production
npm start
```

The server starts at `http://localhost:5000` by default.

---

## Environment Variables

| Variable   | Default       | Description           |
| ---------- | ------------- | --------------------- |
| `PORT`     | `5000`        | Server port           |
| `HOST`     | `localhost`   | Server host           |
| `NODE_ENV` | `development` | Environment mode      |

> Database and Redis configs are currently in `src/config/dbConfig.js` and `src/utils/redisKey.js`. Move to `.env` for production.

---

## Database Schema

The core table `news_all` is **partitioned by month** on `broadcast_date` for efficient time-range queries.

### Enums

| Enum                | Values                                                                   |
| ------------------- | ------------------------------------------------------------------------ |
| `news_category`     | Economy, Infrastructure, Politics, Crime, Science, Geopolitics, Emergency |
| `impact_scope_type` | Local, District, State, National, International                          |
| `crime_severity`    | NONE, LOW, MODERATE, EXTREME                                             |
| `emergency_type`    | NONE, PUBLIC_HEALTH, NATURAL_DISASTER, WAR_CONFLICT, CIVIL_UNREST        |
| `sentiment_type`    | Positive, Neutral, Negative                                              |

### Indexes

| Index                              | Type            | Purpose                                |
| ---------------------------------- | --------------- | -------------------------------------- |
| `idx_news_broadcast_date_brin`     | BRIN            | Fast time-range scans (append-heavy)   |
| `idx_news_category_sentiment`      | B-Tree          | Category + sentiment composite filter  |
| `idx_news_state_district_date`     | B-Tree          | Location-based filtering               |
| `idx_news_tags_gin`                | GIN             | JSONB tag queries (`?`, `?|`, `@>`)    |
| `idx_news_entities_gin`            | GIN (partial)   | Non-empty entities only (saves space)  |
| `idx_news_headline_search`         | GIN (tsvector)  | Full-text search on headlines          |
| `idx_news_financial_industries`    | GIN (path_ops)  | Industry containment (`@>` only)       |

---

## API Reference

**Base URL:** `http://localhost:5000/api`

All endpoints return JSON. All use `GET` method.

---

### Health Check

```
GET /health
```

**Response:**
```json
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2026-06-02T11:30:00.000Z"
}
```

---

### General News

All general news endpoints cover **all categories** unless filtered.

#### `GET /api/general/v1/today`

Fetch today's news, ordered by importance.

| Param   | Type   | Default | Description         |
| ------- | ------ | ------- | ------------------- |
| `limit` | number | `30`    | Max results (1–500) |

```
GET /api/general/v1/today?limit=20
```

---

#### `GET /api/general/v1/top`

Fetch high-importance news from the last 3 days (score ≥ 7).

| Param   | Type   | Default | Description         |
| ------- | ------ | ------- | ------------------- |
| `limit` | number | `30`    | Max results (1–500) |

```
GET /api/general/v1/top?limit=10
```

---

#### `GET /api/general/v1/crime`

Fetch crime news filtered by severity level.

| Param      | Type   | Required | Description                              |
| ---------- | ------ | -------- | ---------------------------------------- |
| `severity` | string | ✅       | `NONE`, `LOW`, `MODERATE`, or `EXTREME`  |
| `limit`    | number | No       | Max results (1–500), default `30`        |

```
GET /api/general/v1/crime?severity=EXTREME&limit=15
```

---

#### `GET /api/general/v1/sentiment`

Fetch news filtered by sentiment analysis.

| Param       | Type   | Default    | Description                          |
| ----------- | ------ | ---------- | ------------------------------------ |
| `sentiment` | string | `Positive` | `Positive`, `Neutral`, or `Negative` |
| `limit`     | number | `30`       | Max results (1–500)                  |

```
GET /api/general/v1/sentiment?sentiment=Negative&limit=20
```

---

#### `GET /api/general/v1/state`

Fetch news for a specific Indian state.

| Param   | Type   | Required | Description                      |
| ------- | ------ | -------- | -------------------------------- |
| `state` | string | ✅       | State name (e.g., `Maharashtra`) |
| `limit` | number | No       | Max results (1–500), default `30`|

```
GET /api/general/v1/state?state=Maharashtra&limit=25
```

---

#### `GET /api/general/v1/entities`

Fetch news mentioning specific people or organizations. At least one entity is required.

| Param          | Type   | Required         | Description        |
| -------------- | ------ | ---------------- | ------------------ |
| `person`       | string | At least one of  | Person name        |
| `organization` | string | person or org    | Organization name  |
| `limit`        | number | No               | Max results (1–500)|

```
GET /api/general/v1/entities?person=Amit%20Shah&limit=10
GET /api/general/v1/entities?organization=ISRO&limit=20
GET /api/general/v1/entities?person=Modi&organization=BJP&limit=15
```

---

#### `GET /api/general/v1/emergency`

Fetch news filtered by emergency/crisis type.

| Param   | Type   | Required | Description                                                          |
| ------- | ------ | -------- | -------------------------------------------------------------------- |
| `type`  | string | ✅       | `PUBLIC_HEALTH`, `NATURAL_DISASTER`, `WAR_CONFLICT`, `CIVIL_UNREST`  |
| `limit` | number | No       | Max results (1–500), default `30`                                    |

```
GET /api/general/v1/emergency?type=NATURAL_DISASTER&limit=20
```

---

#### `GET /api/general/v1/category`

Fetch news for any specific category.

| Param      | Type   | Required | Description                                                                     |
| ---------- | ------ | -------- | ------------------------------------------------------------------------------- |
| `category` | string | ✅       | `Economy`, `Infrastructure`, `Politics`, `Crime`, `Science`, `Geopolitics`, `Emergency` |
| `limit`    | number | No       | Max results (1–500), default `30`                                               |

```
GET /api/general/v1/category?category=Politics&limit=30
GET /api/general/v1/category?category=Science&limit=10
```

---

#### `GET /api/general/v1/search`

Full-text search across headlines. Uses PostgreSQL `tsvector` with relevance ranking.

| Param   | Type   | Required | Description                     |
| ------- | ------ | -------- | ------------------------------- |
| `q`     | string | ✅       | Search query (min 2 characters) |
| `limit` | number | No       | Max results (1–500), default `30`|

```
GET /api/general/v1/search?q=infrastructure%20development&limit=20
```

> Searches the last **7 days** and ranks results by relevance score.

---

#### `GET /api/general/v1/tags`

Fetch news tagged with a specific keyword.

| Param   | Type   | Required | Description                   |
| ------- | ------ | -------- | ----------------------------- |
| `tag`   | string | ✅       | Tag to search for (e.g., `AI`)|
| `limit` | number | No       | Max results (1–500), default `30`|

```
GET /api/general/v1/tags?tag=AI&limit=15
```

---

### Business News

Business endpoints filter for **Economy** and **Infrastructure** categories, plus specialized finance and tech queries.

#### `GET /api/business/v1/today`

Today's business news.

| Param   | Type   | Default | Description         |
| ------- | ------ | ------- | ------------------- |
| `limit` | number | `30`    | Max results (1–500) |

```
GET /api/business/v1/today?limit=20
```

---

#### `GET /api/business/v1/top`

Top business news from the last 3 days (importance ≥ 7).

| Param   | Type   | Default | Description         |
| ------- | ------ | ------- | ------------------- |
| `limit` | number | `30`    | Max results (1–500) |

```
GET /api/business/v1/top?limit=10
```

---

#### `GET /api/business/v1/tech`

Technology, AI, and startup-related news. Matches tags and financial industries.

| Param   | Type   | Default | Description         |
| ------- | ------ | ------- | ------------------- |
| `limit` | number | `30`    | Max results (1–500) |

```
GET /api/business/v1/tech?limit=25
```

> Searches for tags: `tech`, `IT`, `AI`, `startup`, `software`, `technology`

---

#### `GET /api/business/v1/finance`

News with attached financial data (FDI, Capex, Grants, etc.), sorted by amount.

| Param   | Type   | Default | Description         |
| ------- | ------ | ------- | ------------------- |
| `limit` | number | `30`    | Max results (1–500) |

```
GET /api/business/v1/finance?limit=20
```

**Additional fields returned:**
```json
{
  "financial_type": "FDI",
  "financial_amount": 50000.00,
  "financial_currency": "INR",
  "financial_denomination": "Crore",
  "financial_status": "Announced",
  "financial_industries": ["Tech", "Manufacturing"]
}
```

---

#### `GET /api/business/v1/sentiment`

Business news filtered by sentiment.

| Param       | Type   | Default    | Description                          |
| ----------- | ------ | ---------- | ------------------------------------ |
| `sentiment` | string | `Positive` | `Positive`, `Neutral`, or `Negative` |
| `limit`     | number | `30`       | Max results (1–500)                  |

```
GET /api/business/v1/sentiment?sentiment=Negative&limit=15
```

---

#### `GET /api/business/v1/state`

Business news for a specific state.

| Param   | Type   | Required | Description                      |
| ------- | ------ | -------- | -------------------------------- |
| `state` | string | ✅       | State name (e.g., `Karnataka`)   |
| `limit` | number | No       | Max results (1–500), default `30`|

```
GET /api/business/v1/state?state=Karnataka&limit=20
```

---

## Query Parameters

### Universal Rules

| Rule               | Detail                                                   |
| ------------------ | -------------------------------------------------------- |
| **`limit`**        | Integer between 1–500. Defaults vary by endpoint (30–60) |
| **String params**  | Max 200 characters, trimmed, whitespace-normalized       |
| **Enum params**    | Case-insensitive (e.g., `extreme` = `EXTREME`)           |
| **Missing params** | Returns `400` with descriptive error message             |

---

## Response Format

### Success Response

```json
{
  "success": true,
  "data": [
    {
      "headline": "India Signs $2B Trade Deal with Japan",
      "summary": "A bilateral trade agreement was signed...",
      "category": "Economy",
      "sentiment": "Positive",
      "importance_score": 8,
      "broadcast_date": "2026-06-02"
    }
  ],
  "message": "Today's news fetched successfully"
}
```

### Error Response (400 — Bad Request)

```json
{
  "success": false,
  "message": "error : use correct route (url) || contrains",
  "error": "Invalid crime severity. Allowed: NONE, LOW, MODERATE, EXTREME"
}
```

### Error Response (404 — Not Found)

```json
{
  "success": false,
  "message": "Route not found",
  "path": "/api/invalid/route"
}
```

### Error Response (500 — Server Error)

```json
{
  "success": false,
  "message": "Error fetching today's news",
  "error": "connection refused"
}
```

---

## Caching Strategy

All responses are cached in Redis with the following key pattern:

```
{module}_{queryType}_{dynamicParams}_{limit}
```

### Key Examples

| Endpoint                              | Redis Key                              |
| ------------------------------------- | -------------------------------------- |
| `/general/v1/today?limit=60`          | `general_today_60`                     |
| `/general/v1/crime?severity=EXTREME`  | `general_crime_EXTREME_30`             |
| `/general/v1/state?state=UP`          | `general_state_UP_30`                  |
| `/general/v1/entities?person=Modi`    | `general_entities_Modi_any_30`         |
| `/general/v1/search?q=budget`         | `general_search_budget_30`             |
| `/business/v1/tech?limit=20`          | `business_tech_20`                     |
| `/business/v1/sentiment?sentiment=Negative` | `business_sentiment_NEGATIVE_30` |

### TTL (Time-To-Live)

| Query Type            | TTL      | Reason                                |
| --------------------- | -------- | ------------------------------------- |
| Today / Top / Crime   | 1 hour   | Standard freshness                    |
| Sentiment / State     | 1 hour   | Standard freshness                    |
| Category / Tags       | 1 hour   | Standard freshness                    |
| Entities              | 1 hour   | Standard freshness                    |
| **Emergency**         | **30 min** | Crisis data needs faster refresh    |
| **Search**            | **30 min** | Results change frequently           |
| Tech / Finance        | 1 hour   | Standard freshness                    |

---

## Security

### Middleware Pipeline (applied globally, in order)

| #  | Middleware              | Purpose                                                |
| -- | ----------------------- | ------------------------------------------------------ |
| 1  | Security Headers        | Sets `X-Content-Type-Options`, `X-Frame-Options`, etc. |
| 2  | Rate Limiting           | Prevents abuse / DDoS                                  |
| 3  | Input Sanitization      | Strips SQL injection, XSS, NoSQL injection patterns    |
| 4  | Body Parser (10MB cap)  | Prevents large payload attacks                         |

### Input Sanitization Rules

- **Max string length:** 1000 characters
- **Max array length:** 100 items
- **Max object depth:** 10 levels
- **Blocked patterns:** SQL injection (`' -- ; /* */`), script injection (`<script>`, `javascript:`), NoSQL injection (`$where`, `$regex`)

### Parameterized Queries

All database queries use `$1`, `$2`, etc. parameterized placeholders — **zero string concatenation** in SQL.

---

## Project Structure

```
BodhAPI/
├── server.js                          # Entry point (redirects to src/)
├── package.json
├── .env.example
│
├── src/
│   ├── app.js                         # Express app + route registration
│   ├── server.js                      # HTTP server + graceful shutdown
│   │
│   ├── config/
│   │   └── dbConfig.js                # PostgreSQL pool config
│   │
│   ├── middleware/
│   │   ├── securityPipeline.js        # Middleware orchestrator
│   │   ├── general/
│   │   │   ├── generalValidation.js   # Shared validators (limit, string, enum, integer)
│   │   │   └── securityValidation.js
│   │   ├── security/
│   │   │   ├── inputSanitizationMiddleware.js
│   │   │   ├── rateLimitMiddleware.js
│   │   │   └── securityHeadersMiddleware.js
│   │   └── validation/
│   │       └── inputValidationRules.js
│   │
│   ├── modules/v1/
│   │   ├── general/                   # General news module
│   │   │   ├── general.route.js       # 10 GET endpoints
│   │   │   ├── general.controller.js  # Request/response handling
│   │   │   ├── general.validation.js  # Module-specific validators
│   │   │   ├── general.service.js     # Redis cache layer
│   │   │   ├── general.models.js      # PostgreSQL queries
│   │   │   ├── general.formatter.js   # Response formatting (placeholder)
│   │   │   ├── schema.sql             # Full DB schema
│   │   │   └── prompt.md              # AI prompt for news extraction
│   │   │
│   │   ├── business/                  # Business news module
│   │   │   ├── business.routes.js     # 6 GET endpoints
│   │   │   ├── business.controller.js
│   │   │   ├── business.validation.js
│   │   │   ├── business.service.js
│   │   │   ├── business.model.js
│   │   │   └── business.formatters.js # Response formatting (placeholder)
│   │   │
│   │   ├── socials/                   # Social news module (planned)
│   │   └── auth/                      # Auth module (planned)
│   │
│   └── utils/
│       ├── redisKey.js                # Redis get/set/close
│       └── redisKeyGenerator.js       # Cache key generation (class)
```

### Module Pattern

Each module follows a strict layered architecture:

```
route.js → controller.js → validation.js → service.js → model.js
                                                │
                                          Redis (cache)
```

| Layer        | Responsibility                                     |
| ------------ | -------------------------------------------------- |
| **Route**    | Maps HTTP paths to controller functions             |
| **Controller** | Validates input, builds cache key, calls service, formats response |
| **Validation** | Input validation using shared middleware validators  |
| **Service**  | Cache-through logic (check Redis → query DB → set Redis) |
| **Model**    | Raw PostgreSQL queries with parameterized inputs    |

---

## Endpoint Summary

### General News — 10 Endpoints

| Method | Path                         | Query Params                          |
| ------ | ---------------------------- | ------------------------------------- |
| GET    | `/api/general/v1/today`      | `?limit=30`                           |
| GET    | `/api/general/v1/top`        | `?limit=40`                           |
| GET    | `/api/general/v1/crime`      | `?severity=EXTREME&limit=30`          |
| GET    | `/api/general/v1/sentiment`  | `?sentiment=Positive&limit=30`        |
| GET    | `/api/general/v1/state`      | `?state=Maharashtra&limit=30`         |
| GET    | `/api/general/v1/entities`   | `?person=Modi&organization=BJP&limit=30` |
| GET    | `/api/general/v1/emergency`  | `?type=NATURAL_DISASTER&limit=30`     |
| GET    | `/api/general/v1/category`   | `?category=Politics&limit=30`         |
| GET    | `/api/general/v1/search`     | `?q=trade deal&limit=30`              |
| GET    | `/api/general/v1/tags`       | `?tag=AI&limit=30`                    |

### Business News — 6 Endpoints

| Method | Path                         | Query Params                          |
| ------ | ---------------------------- | ------------------------------------- |
| GET    | `/api/business/v1/today`     | `?limit=30`                           |
| GET    | `/api/business/v1/top`       | `?limit=40`                           |
| GET    | `/api/business/v1/tech`      | `?limit=30`                           |
| GET    | `/api/business/v1/finance`   | `?limit=30`                           |
| GET    | `/api/business/v1/sentiment` | `?sentiment=Positive&limit=30`        |
| GET    | `/api/business/v1/state`     | `?state=Karnataka&limit=30`           |

---

## License

ISC
