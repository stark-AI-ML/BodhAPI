# BodhAPI — Indian News Intelligence Engine


*i patched the issues as there were too many routes so i creted this readme.md intilally with ai but fixed the issues with it so for learning purpose it is good *

> A high-performance REST API that transforms raw Indian news broadcasts into structured, machine-readable intelligence. Built with Express 5, PostgreSQL (partitioned tables + BRIN indexes), Redis caching, Google OAuth authentication, JWT sessions, and API key–gated access.

---

## Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Database Schema](#database-schema)
- [Authentication & Authorization](#authentication--authorization)
  - [Google OAuth Login](#google-oauth-login)
  - [JWT Sessions](#jwt-sessions)
  - [API Keys](#api-keys)
- [API Reference](#api-reference)
  - [Health Check](#health-check)
  - [Auth Endpoints](#auth-endpoints)
  - [Session Endpoints](#session-endpoints)
  - [API Key Management](#api-key-management)
  - [General News](#general-news)
  - [Business News](#business-news)
- [Query Parameters](#query-parameters)
- [Response Format](#response-format)
- [Caching Strategy](#caching-strategy)
- [Rate Limiting](#rate-limiting)
- [Logging](#logging)
- [Security](#security)
- [Docker Deployment](#docker-deployment)
- [Project Structure](#project-structure)

---

## Architecture

```
Client Request
     │
     ▼
┌──────────────────────────────────────────┐
│           Security Pipeline              │
│  CORS → Cookies → Headers → Rate Limit  │
│  → Sanitize → Body Parse                │
└──────────────────────────────────────────┘
     │
     ▼
┌──────────────────────────────────────────┐
│          Authentication Layer            │
│  Google OAuth │ JWT Tokens │ API Keys    │
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

**Flow:** CORS → Cookie Parse → Security Pipeline → Auth (OAuth/JWT/API Key) → Route → Controller → Validation → Service → Redis (cache check) → Model (DB query) → Redis (cache set) → Response

---

## Tech Stack

| Layer          | Technology                            |
| -------------- | ------------------------------------- |
| Runtime        | Node.js (ES Modules)                  |
| Framework      | Express 5                             |
| Database       | PostgreSQL (partitioned by month)     |
| Cache          | Redis (ioredis)                       |
| Auth           | Passport (Google OAuth 2.0)           |
| Tokens         | JSON Web Tokens (jsonwebtoken)        |
| Hashing        | bcrypt (API keys, passwords)          |
| Logging        | Winston (console + file transports)   |
| Validation     | validator.js                          |
| CORS           | cors                                  |
| Containerisation | Docker + Docker Compose             |
| Dev Server     | Nodemon                               |

---

## Getting Started

### Prerequisites

- **Node.js** ≥ 20 (Alpine recommended for Docker)
- **PostgreSQL** ≥ 14 (with partitioning support)
- **Redis** ≥ 7

### Installation

```bash
# Clone the repository
git clone [production_branch](https://github.com/stark-AI-ML/BodhAPI/tree/prod)

# so if you are setting whole thing with docker clone prod branch

git clone [main_branch](https://github.com/stark-AI-ML/BodhAPI/tree/main)

# although i don't think any one needs to copy this 

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

### Docker Quick Start

```bash
# Build and run with Docker Compose
docker compose up --build -d
```

See [Docker Deployment](#docker-deployment) for full details.

---

## Environment Variables

| Variable               | Default                   | Description                            |
| ---------------------- | ------------------------- | -------------------------------------- |
| `PORT`                 | `5000`                    | Server port                            |
| `HOST`                 | `0.0.0.0`                 | Server host                            |
| `NODE_ENV`             | `development`             | Environment mode                       |
| `GOOGLE_CLIENT_ID`     | —                         | Google OAuth 2.0 client ID             |
| `GOOGLE_CLIENT_SECRET` | —                         | Google OAuth 2.0 client secret         |
| `GOOGLE_CALLBACK_URL`  | —                         | Google OAuth callback URL              |
| `ACCESS_KEY`           | —                         | Secret for signing access tokens       |
| `REFRESH_KEY`          | —                         | Secret for signing refresh tokens      |
| `DB_HOST`              | —                         | PostgreSQL host                        |
| `DB_USER`              | —                         | PostgreSQL user                        |
| `DB_PASSWORD`          | —                         | PostgreSQL password                    |
| `DB_NAME`              | —                         | PostgreSQL database name               |
| `REDIS_URL`            | —                         | Redis connection URL                   |

> Database and Redis configs are in `src/config/dbConfig.js` and `src/utils/redisKey.js`. Use `.env` for production.

---

## Database Schema

### News Tables

The core table `news_all` is **partitioned by month** on `broadcast_date` for efficient time-range queries.

#### Lookup Tables

| Table       | Purpose                     |
| ----------- | --------------------------- |
| `states`    | Indian state names (unique) |
| `districts` | Districts linked to states  |

#### Enums

| Enum                | Values                                                                   |
| ------------------- | ------------------------------------------------------------------------ |
| `news_category`     | Economy, Infrastructure, Politics, Crime, Science, Geopolitics, Emergency |
| `impact_scope_type` | Local, District, State, National, International                          |
| `crime_severity`    | NONE, LOW, MODERATE, EXTREME                                             |
| `emergency_type`    | NONE, PUBLIC_HEALTH, NATURAL_DISASTER, WAR_CONFLICT, CIVIL_UNREST        |
| `sentiment_type`    | Positive, Neutral, Negative                                              |

#### Indexes

| Index                              | Type            | Purpose                                |
| ---------------------------------- | --------------- | -------------------------------------- |
| `idx_news_broadcast_date_brin`     | BRIN            | Fast time-range scans (append-heavy)   |
| `idx_news_category_sentiment`      | B-Tree          | Category + sentiment composite filter  |
| `idx_news_state_district_date`     | B-Tree          | Location-based filtering               |
| `idx_news_tags_gin`                | GIN             | JSONB tag queries (`?`, `?|`, `@>`)    |
| `idx_news_entities_gin`            | GIN (partial)   | Non-empty entities only (saves space)  |
| `idx_news_headline_search`         | GIN (tsvector)  | Full-text search on headlines          |

### Auth Tables

| Table            | Purpose                                                           |
| ---------------- | ----------------------------------------------------------------- |
| `users`          | User accounts (Google OAuth profile, email, plan)                 |
| `refresh_tokens` | Refresh token hashes with JWT ID, IP, user agent, expiry, revoked |
| `api_keys`       | SHA-256 hashed API keys with prefix, expiry, usage tracking       |
| `plans`          | Plan tiers with limits (max keys, rate limits)                    |

---

## Authentication & Authorization

BodhAPI uses a dual authentication model:

1. **Google OAuth 2.0** — for user-facing browser sessions
2. **API Keys** — for programmatic / machine-to-machine access

### Google OAuth Login

```
Browser → GET /auth/google → Google consent screen → GET /auth/google/callback → JWT cookies set → redirect to frontend
```

- Uses Passport.js with the `passport-google-oauth20` strategy.
- On first login, a new user record is created (upserted by `google_id`).
- On callback success, an access token and refresh token are issued as HTTP-only cookies.
- Redirects to `http://localhost:3000` (update for production).

### JWT Sessions

| Token          | Expiry  | Cookie Name     | Purpose                |
| -------------- | ------- | --------------- | ---------------------- |
| Access Token   | 1 min   | `accessToken`   | Short-lived API access |
| Refresh Token  | 30 days | `refreshToken`  | Long-lived token renewal |

- Both tokens are `httpOnly`, `sameSite: none`, and `secure`.
- Each login creates a `refresh_tokens` row in the database (bcrypt-hashed refresh JWT, user agent, IP, expiry).
- Sessions can be listed, individually revoked, or bulk-revoked.

### API Keys

- Generated in the format `bodh_live_{12-hex}_{36-hex}` (e.g., `bodh_live_a1b2c3d4e5f6_...`).
- The raw key is shown **only once** at creation; only a SHA-256 hash is stored.
- Pass via the `Authorization: Bearer <key>` header on every news API request.
- The public prefix (`bodh_live_{hex}`) is stored for lookup; the full key is verified by hash comparison.
- Validated keys are cached in Redis for fast repeated lookups.
- Each key is individually rate-limited via Redis sliding-window counters (Lua scripts).
- Keys can be deleted individually.
- API keys enforce **plan-based limits** — the number of keys a user can generate depends on their plan (queried from `plans` table).

**All news API endpoints (`/api/general/*`, `/api/business/*`) require a valid API key.**

---

## API Reference

**Base URL:** `http://localhost:5000`

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

### Auth Endpoints

These endpoints handle user authentication via Google OAuth.

| Method | Path                     | Auth     | Description                           |
| ------ | ------------------------ | -------- | ------------------------------------- |
| GET    | `/auth/google`           | None     | Initiate Google OAuth login           |
| GET    | `/auth/google/callback`  | None     | Google OAuth callback (sets cookies)  |
| GET    | `/auth/me`               | Cookie   | Get current authenticated user info   |
| GET    | `/auth/logout`           | None     | Clear cookies and log out             |

#### `GET /auth/google`

Redirects to Google consent screen. Scopes: `profile`, `email`.

#### `GET /auth/google/callback`

Handles the OAuth callback. On success:
- Creates a session (stores bcrypt-hashed refresh token in `refresh_tokens` table)
- Sets `accessToken` (1 min) and `refreshToken` (30 days) cookies
- Redirects to `http://localhost:3000`

#### `GET /auth/me`

Verifies the `accessToken` cookie and returns the current user's profile or `401` if not logged in.

#### `GET /auth/logout`

Clears `accessToken` and `refreshToken` cookies, returns:
```json
{
  "success": true
}
```

---

### Session Endpoints

Token refresh and session revocation.

| Method | Path         | Auth              | Description                          |
| ------ | ------------ | ----------------- | ------------------------------------ |
| POST   | `/refresh`   | refreshToken cookie | Rotate tokens (issues new access + refresh) |
| POST   | `/logout`    | refreshToken cookie | Revoke refresh token + clear cookies |

---

### API Key Management

Manage API keys for programmatic access.

| Method | Path                        | Auth               | Description                     |
| ------ | --------------------------- | ------------------- | ------------------------------- |
| POST   | `/auth/generate-key`        | accessToken cookie  | Generate a new API key          |
| GET    | `/api/getCurrentKeys`       | accessToken cookie  | List user's API keys            |
| DELETE | `/api/removeKey`            | accessToken cookie  | Delete an API key               |

#### `POST /auth/generate-key`

Generates a new API key (subject to plan limits). Returns the full key only once.

**Response:**
```json
{
  "success": true,
  "data": {
    "prefix": "bodh_live_a1b2c3d4e5f6",
    "fullKey": "bodh_live_a1b2c3d4e5f6_..."
  }
}
```

> ⚠️ The raw API key is returned **only once**. Store it securely.

---

### General News

All general news endpoints cover **all categories** unless filtered. Requires `Authorization: Bearer <api-key>` header.

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

Business endpoints filter for **Economy** and **Infrastructure** categories, plus specialized finance and tech queries. Requires `Authorization: Bearer <api-key>` header.

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
      "broadcast_date": "2026-06-02",
      "state": "Maharashtra",
      "district": "Mumbai",
      "impact_scope": "National",
      "tags": ["trade", "japan"],
      "entities": { "persons": ["PM Modi"], "organizations": ["MEA"] }
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

### Error Response (401 — Unauthorized)

```json
{
  "success": false,
  "message": "API key is required"
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

### Error Response (429 — Rate Limit Exceeded)

```json
{
  "success": false,
  "message": "Rate limit exceeded. Try again later."
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

## Rate Limiting

### IP-Based Rate Limiting

Applied globally via the security middleware pipeline to prevent DDoS and abuse.

### API Key Rate Limiting

Each API key has its own Redis-based sliding-window rate limiter.

| Default        | Value           |
| -------------- | --------------- |
| Max requests   | 100 per window  |
| Window         | 60 seconds      |

**Response headers on every API request:**

| Header                  | Description                  |
| ----------------------- | ---------------------------- |
| `X-RateLimit-Limit`     | Max requests per window      |
| `X-RateLimit-Remaining` | Remaining requests           |
| `X-RateLimit-Reset`     | Window reset time (epoch ms) |

**Planned rate limit tiers:**

| Tier        | Requests/min |
| ----------- | ------------ |
| Free        | 10           |
| Basic       | 50           |
| Pro         | 200          |
| Enterprise  | 1000         |

---

## Logging

BodhAPI uses **Winston** for structured logging with multiple transports:

| Transport  | File           | Level   | Details                     |
| ---------- | -------------- | ------- | --------------------------- |
| Console    | —              | All     | Stdout/stderr for dev & containers |
| File       | `app.log`      | All     | All application logs (JSON) |
| File       | `errors.log`   | Error   | Error-only logs (JSON)      |

Log format: JSON with timestamps. All unhandled errors in the global error handler are logged automatically.

---

## Security

### Middleware Pipeline (applied globally, in order)

| #  | Middleware              | Purpose                                                |
| -- | ----------------------- | ------------------------------------------------------ |
| 1  | CORS                    | Cross-origin resource sharing (credentials enabled)    |
| 2  | Cookie Parser           | Parses JWT cookies from requests                       |
| 3  | Security Headers        | Sets `X-Content-Type-Options`, `X-Frame-Options`, etc. |
| 4  | Rate Limiting           | IP-based abuse prevention                              |
| 5  | Input Sanitization      | Strips SQL injection, XSS, NoSQL injection patterns    |
| 6  | Body Parser (10MB cap)  | Prevents large payload attacks                         |

### Authentication Guards

| Route Prefix             | Guard               | Description                               |
| ------------------------ | -------------------- | ----------------------------------------- |
| `/auth/me`               | JWT cookie           | Requires valid `accessToken` cookie       |
| `/auth/generate-key`     | JWT cookie           | Requires valid `accessToken` cookie       |
| `/api/getCurrentKeys`    | JWT cookie           | Requires valid `accessToken` cookie       |
| `/api/removeKey`         | JWT cookie           | Requires valid `accessToken` cookie       |
| `/api/general/*`         | API Key + Rate Limit | Requires `Authorization: Bearer` header   |
| `/api/business/*`        | API Key              | Requires `Authorization: Bearer` header   |

### Input Sanitization Rules

- **Max string length:** 1000 characters
- **Max array length:** 100 items
- **Max object depth:** 10 levels
- **Blocked patterns:** SQL injection (`' -- ; /* */`), script injection (`<script>`, `javascript:`), NoSQL injection (`$where`, `$regex`)

### Parameterized Queries

All database queries use `$1`, `$2`, etc. parameterized placeholders — **zero string concatenation** in SQL.

---

## Docker Deployment

### Dockerfile

```dockerfile
FROM node:20-alpine
WORKDIR /
COPY package.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

### Docker Compose

The production `docker-compose.yml` runs the API service on a shared private network (designed for use behind an Nginx reverse proxy):

```yaml
services:
  bodhapi:
    build: .
    container_name: bodhapi-container
    environment:
      REDIS_URL: redis://redis:6379
      DB_HOST: db
      DB_USER: ${DB_USER}
      DB_PASS: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
    command: ["node", "server.js"]
    restart: always
    networks:
      - shared_private_net

networks:
  shared_private_net:
    external: true
```

> The external `shared_private_net` network assumes Redis and PostgreSQL are running on the same Docker network (e.g., managed by a separate infra compose file with Nginx).

### Graceful Shutdown

The server handles `SIGTERM` and `SIGINT` signals:
1. Stops accepting new HTTP connections
2. Closes Redis connection
3. Closes PostgreSQL pool
4. Exits with code 0

---

## Project Structure

```
BodhAPI/
├── server.js                              # Entry point (redirects to src/)
├── package.json
├── Dockerfile
├── docker-compose.yml
├── .env.example
│
├── db/
│   └── migrations/                        # Database migrations
│
├── src/
│   ├── app.js                             # Express app + middleware + route registration
│   ├── server.js                          # HTTP server + graceful shutdown
│   │
│   ├── config/
│   │   ├── dbConfig.js                    # PostgreSQL pool config
│   │   └── logger.js                      # Winston logger (console + file)
│   │
│   ├── auth/                              # Authentication subsystem
│   │   ├── config/
│   │   │   └── googleOauthConfigAndSave.js  # Passport Google OAuth strategy
│   │   ├── controllers/
│   │   │   ├── auth.controller.js         # OAuth callback, /me verification
│   │   │   ├── session.controller.js      # Token refresh, logout
│   │   │   └── apiKey.controller.js       # API key generate/list/delete
│   │   ├── middleware/
│   │   │   ├── authMiddleware.js          # JWT cookie verification guard
│   │   │   ├── apiKey.Middleware.js        # Bearer token API key validation
│   │   │   └── apiKey.rateLimiter.js      # Per-key Redis rate limiter
│   │   ├── routes/
│   │   │   ├── session.route.js           # Token refresh & logout routes
│   │   │   └── apiSession.route.js        # API key list/delete routes
│   │   ├── services/
│   │   │   ├── auth.service.js            # Login (token gen + DB insert), logout
│   │   │   ├── session.service.js         # Token refresh with rotation
│   │   │   └── apiKey.service.js          # API key DB operations (SHA-256)
│   │   └── utils/
│   │       ├── createToken.js             # JWT sign/verify helpers
│   │       ├── tokenTTl.config.js         # Token expiry configuration
│   │       ├── apiKeyGenerator.js         # bodh_live_{hex}_{hex} key generator
│   │       └── hash.js                    # bcrypt + SHA-256 hash/compare
│   │
│   ├── routes/
│   │   └── auth.route.js                  # Google OAuth routes (/auth/google/*)
│   │
│   ├── middleware/
│   │   ├── securityPipeline.js            # Middleware orchestrator
│   │   ├── general/
│   │   │   ├── generalValidation.js       # Shared validators (limit, string, enum)
│   │   │   └── securityValidation.js
│   │   ├── security/
│   │   │   ├── inputSanitizationMiddleware.js
│   │   │   ├── rateLimitMiddleware.js
│   │   │   └── securityHeadersMiddleware.js
│   │   └── validation/
│   │       └── inputValidationRules.js
│   │
│   ├── modules/v1/
│   │   ├── general/                       # General news module
│   │   │   ├── general.route.js           # 10 GET endpoints
│   │   │   ├── general.controller.js      # Request/response handling
│   │   │   ├── general.validation.js      # Module-specific validators
│   │   │   ├── general.service.js         # Redis cache layer
│   │   │   ├── general.models.js          # PostgreSQL queries
│   │   │   ├── general.formatter.js       # Response formatting
│   │   │   ├── schema.sql                 # Full DB schema
│   │   │   └── prompt.md                  # AI prompt for news extraction
│   │   │
│   │   ├── business/                      # Business news module
│   │   │   ├── business.routes.js         # 6 GET endpoints
│   │   │   ├── business.controller.js
│   │   │   ├── business.validation.js
│   │   │   ├── business.service.js
│   │   │   ├── business.model.js
│   │   │   └── business.formatters.js     # Response formatting
│   │   │
│   │   ├── socials/                       # Social news module (planned)
│   │   └── auth/                          # Auth module (planned)
│   │
│   └── utils/
│       ├── redisKey.js                    # Redis get/set/close
│       ├── redisKeyGenerator.js           # Cache key generation (class)
│       ├── apiKeyLimiter.js               # Redis sliding-window rate limiter
│       └── minuteRange.js                 # Time-range helper (today, 3d, 7d, 30d)
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
| **Formatter** | Transforms raw DB rows into clean API responses    |

---

## Endpoint Summary

### Auth — 4 Endpoints

| Method | Path                         | Auth   | Description                  |
| ------ | ---------------------------- | ------ | ---------------------------- |
| GET    | `/auth/google`               | None   | Initiate Google OAuth        |
| GET    | `/auth/google/callback`      | None   | OAuth callback               |
| GET    | `/auth/me`                   | Cookie | Get authenticated user info  |
| GET    | `/auth/logout`               | None   | Clear cookies                |

### Session — 2 Endpoints

| Method | Path                         | Auth             | Description                  |
| ------ | ---------------------------- | ---------------- | ---------------------------- |
| POST   | `/refresh`                   | Refresh cookie   | Rotate access + refresh tokens |
| POST   | `/logout`                    | Refresh cookie   | Revoke refresh token         |

### API Key Management — 3 Endpoints

| Method | Path                         | Auth   | Description                  |
| ------ | ---------------------------- | ------ | ---------------------------- |
| POST   | `/auth/generate-key`         | Cookie | Generate new API key         |
| GET    | `/api/getCurrentKeys`        | Cookie | List API keys                |
| DELETE | `/api/removeKey`             | Cookie | Delete an API key            |

### General News — 10 Endpoints

| Method | Path                         | Auth    | Query Params                          |
| ------ | ---------------------------- | ------- | ------------------------------------- |
| GET    | `/api/general/v1/today`      | API Key | `?limit=30`                           |
| GET    | `/api/general/v1/top`        | API Key | `?limit=40`                           |
| GET    | `/api/general/v1/crime`      | API Key | `?severity=EXTREME&limit=30`          |
| GET    | `/api/general/v1/sentiment`  | API Key | `?sentiment=Positive&limit=30`        |
| GET    | `/api/general/v1/state`      | API Key | `?state=Maharashtra&limit=30`         |
| GET    | `/api/general/v1/entities`   | API Key | `?person=Modi&organization=BJP&limit=30` |
| GET    | `/api/general/v1/emergency`  | API Key | `?type=NATURAL_DISASTER&limit=30`     |
| GET    | `/api/general/v1/category`   | API Key | `?category=Politics&limit=30`         |
| GET    | `/api/general/v1/search`     | API Key | `?q=trade deal&limit=30`              |
| GET    | `/api/general/v1/tags`       | API Key | `?tag=AI&limit=30`                    |

### Business News — 6 Endpoints

| Method | Path                         | Auth    | Query Params                          |
| ------ | ---------------------------- | ------- | ------------------------------------- |
| GET    | `/api/business/v1/today`     | API Key | `?limit=30`                           |
| GET    | `/api/business/v1/top`       | API Key | `?limit=40`                           |
| GET    | `/api/business/v1/tech`      | API Key | `?limit=30`                           |
| GET    | `/api/business/v1/finance`   | API Key | `?limit=30`                           |
| GET    | `/api/business/v1/sentiment` | API Key | `?sentiment=Positive&limit=30`        |
| GET    | `/api/business/v1/state`     | API Key | `?state=Karnataka&limit=30`           |

**Total: 25 endpoints** (4 auth + 2 session + 3 API key + 10 general + 6 business)

---

## License

ISC
