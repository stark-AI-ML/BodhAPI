// rateLimiter.js
import { redisConfig as redis } from '../../config/dbConfig.js';

// Lua script for token-based sliding window
const luaScript = `
-- KEYS[1] = redis key
-- ARGV[1] = current timestamp (ms)
-- ARGV[2] = window size (ms)
-- ARGV[3] = max tokens
-- ARGV[4] = tokens requested

local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
local tokens_requested = tonumber(ARGV[4])

-- 1. remove old tokens from timestamp 0 to current time

redis.call("ZREMRANGEBYSCORE", key, 0, now - window)

-- 2. Count tokens in window  -- see now-window(time) (is min time we want, to now(present) )

local current_tokens = redis.call("ZCOUNT", key, now - window, now)

if current_tokens + tokens_requested > limit then
  return 0 -- reject
end

-- 3. Add tokens (store with timestamp as score)
for i=1,tokens_requested do
  redis.call("ZADD", key, now, tostring(now) .. ":" .. tostring(i))
end

-- 4. Expiry safety
redis.call("PEXPIRE", key, window)

return current_tokens + tokens_requested
`;

async function acquireTokens(key, tokensRequested, windowMs, maxTokens) {
  const now = Date.now();
  const result = await redis.eval(
    luaScript,
    1,
    key,
    now,
    windowMs,
    maxTokens,
    tokensRequested
  );
  return result; // 0 = rejected, >0 = total tokens in window
}

// Example usage
(async () => {
  const allowed = await acquireTokens('rate:api:user123', 3, 60000, 10);
  if (allowed === 0) {
    console.log('Rate limit exceeded, reject request');
  } else {
    console.log(`Allowed, tokens in window: ${allowed}`);
  }
})();
