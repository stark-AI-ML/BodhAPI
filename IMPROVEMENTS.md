# BodhAPI — Quick Fixes Before Applying

> Priority-ordered. Do the top ones first, skip what you don't have time for.
> Estimated total: 2-3 hours if you focus.

---

## 🔴 Critical (Do These — Interviewers Will Check)

### 1. Move DB credentials to `.env`

`src/config/dbConfig.js` has your password hardcoded. This is the #1 thing that makes a project look amateur.

```js
// BEFORE (current)
const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "news",
  password: "#Postgress_3000",  // ❌ hardcoded
  port: 5432,
});

// AFTER
import dotenv from "dotenv";
dotenv.config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT || "5432"),
});
```

Update `.env.example` too:
```
DB_USER=postgres
DB_HOST=localhost
DB_NAME=news
DB_PASSWORD=your_password_here
DB_PORT=5432
REDIS_HOST=localhost
REDIS_PORT=6379
```

Same for Redis in `src/utils/redisKey.js` — use `process.env.REDIS_HOST` and `process.env.REDIS_PORT`.

**Time: 10 min**

---

### 2. Fix Rate Limit (10 req / 15 min is broken)

Your news API allows only 10 requests per 15 minutes. That's unusable — even one user browsing the app would get blocked in seconds.

```js
// BEFORE
const REQUEST_LIMITS = {
  WINDOW_TIME_MS: 15 * 60 * 1000,
  MAX_REQUESTS: 10,  // ❌ way too low
};

// AFTER — reasonable for a public API
const REQUEST_LIMITS = {
  WINDOW_TIME_MS: 15 * 60 * 1000,
  MAX_REQUESTS: 100,  // 100 per 15 min = ~7/min, reasonable
  CLEANUP_INTERVAL_MS: 60 * 1000,
};
```

**Time: 2 min**

---

### 3. Close Redis + PG on Shutdown

Your `server.js` graceful shutdown closes the HTTP server but **leaks** database and Redis connections.

```js
// In src/server.js — update gracefulShutdown:
import { closeRedis } from "./utils/redisKey.js";
import pool from "./config/dbConfig.js";

const gracefulShutdown = async (signal) => {
  console.log(`\n🛑 ${signal} received, shutting down gracefully...`);

  server.close(async () => {
    try {
      await closeRedis();
      await pool.end();
      console.log("✅ All connections closed");
    } catch (err) {
      console.error("❌ Error closing connections:", err);
    }
    process.exit(0);
  });

  setTimeout(() => {
    console.error("❌ Forcing shutdown after timeout");
    process.exit(1);
  }, 10000);
};
```

**Time: 5 min**

---

## 🟡 Quick Wins (Makes Code Look Professional)

### 4. Extract Cache-Through into a Helper

Every single service function is copy-paste. One helper kills ~150 lines of repetition:

Create `src/utils/cacheThrough.js`:
```js
import { setKey, getKey } from "./redisKey.js";

/**
 * Generic cache-through: check Redis → miss → fetch from DB → cache → return
 */
export const cacheThrough = async (key, ttl, fetchFn) => {
  const cached = await getKey(key);
  if (cached) return cached;

  const fresh = await fetchFn();

  try {
    await setKey(key, fresh, ttl);
  } catch (err) {
    // Cache write failure is non-fatal — log and continue
    console.error(`Cache write failed for key "${key}":`, err.message);
  }

  return fresh;
};
```

Then every service function becomes a one-liner:
```js
// BEFORE — 15 lines each
export const getGeneralTodayNews = async (key, limit, ttl = 3600) => {
  const cachedNews = await getKey(key);
  if (!cachedNews) {
    const news = await fetchTodayNews(limit);
    try { await setKey(key, news, ttl); } catch (error) {}
    return news;
  } else {
    return cachedNews;
  }
};

// AFTER — 3 lines
export const getGeneralTodayNews = async (key, limit, ttl = 3600) => {
  return cacheThrough(key, ttl, () => fetchTodayNews(limit));
};
```

**Time: 30 min** (apply to all service files)

---

### 5. Git History Hygiene

Make sure your `.gitignore` has:
```
.env
node_modules/
log.txt
```

If `.env` or `log.txt` is already committed, remove from tracking:
```bash
git rm --cached .env log.txt
git commit -m "chore: remove sensitive files from tracking"
```

**Time: 5 min**

---

## 🟢 Nice to Have (If You Have Time)

### 6. Add One Integration Test

Even one working test file shows you know testing exists. Create `test/health.test.js`:

```js
// Simple fetch-based test — no framework needed
const BASE = "http://localhost:5000";

async function test(name, fn) {
  try {
    await fn();
    console.log(`✅ ${name}`);
  } catch (err) {
    console.error(`❌ ${name}: ${err.message}`);
    process.exit(1);
  }
}

await test("Health check returns 200", async () => {
  const res = await fetch(`${BASE}/health`);
  if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
  const body = await res.json();
  if (!body.success) throw new Error("Expected success: true");
});

await test("Invalid route returns 404", async () => {
  const res = await fetch(`${BASE}/api/nonexistent`);
  if (res.status !== 404) throw new Error(`Expected 404, got ${res.status}`);
});

await test("Crime without severity returns 400", async () => {
  const res = await fetch(`${BASE}/api/general/v1/crime`);
  if (res.status !== 400) throw new Error(`Expected 400, got ${res.status}`);
});

console.log("\n🎉 All tests passed");
```

Add to `package.json`: `"test": "node test/health.test.js"`

**Time: 15 min**

---

### 7. Add `financial_industries` GIN Index

Your schema is missing the index that `business.model.js` expects:

```sql
-- Add to schema.sql
CREATE INDEX idx_news_financial_industries
ON news_all
USING GIN (financial_industries jsonb_path_ops);
```

This index is referenced in comments but never created. The `@>` queries in `fetchTechNews` would do sequential scans without it.

**Time: 2 min**

---

## Checklist

- [ ] Move DB/Redis creds to `.env`
- [ ] Fix rate limit to 100 per 15 min
- [ ] Close PG + Redis on shutdown
- [ ] Extract `cacheThrough` helper
- [ ] Clean `.gitignore`
- [ ] Add basic test file
- [ ] Add missing `financial_industries` GIN index
