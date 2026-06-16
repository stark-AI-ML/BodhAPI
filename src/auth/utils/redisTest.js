import { redisConfig as redis } from '../../config/dbConfig.js';

const luaScript = `
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
local tokens_requested = tonumber(ARGV[4])

redis.call("ZREMRANGEBYSCORE", key, 0, now - window)
local current_tokens = redis.call("ZCOUNT", key, now - window, now)

if current_tokens + tokens_requested > limit then
  return 0
end

for i=1,tokens_requested do
  redis.call("ZADD", key, now, tostring(now) .. ":" .. tostring(i))
end

redis.call("PEXPIRE", key, window)
return current_tokens + tokens_requested
`;

async function acquireTokens(key, tokensRequested, windowMs, maxTokens) {
  const now = Date.now();
  return redis.eval(
    luaScript,
    1,
    key,
    now,
    windowMs,
    maxTokens,
    tokensRequested
  );
}

(async () => {
  const key = 'rate:test:user123';
  const windowMs = 5000; // 5 seconds
  const maxTokens = 5;

  console.log('=== Test Run ===');

  // Request 3 tokens
  let res1 = await acquireTokens(key, 5, windowMs, maxTokens);
  console.log('Request 3 tokens ->', res1);

  // Request 2 tokens (should succeed, total = 5)
  let res2 = await acquireTokens(key, 2, windowMs, maxTokens);
  console.log('Request 2 tokens ->', res2);
  await new Promise((r) => setTimeout(r, 10000));

  // Request 1 token (should fail, limit exceeded)
  let res3 = await acquireTokens(key, 1, windowMs, maxTokens);
  console.log('Request 1 token ->', res3);

  // Wait 6 seconds (window expires)
  await new Promise((r) => setTimeout(r, 6000));

  // Request 2 tokens again (should succeed, old tokens expired)
  let res4 = await acquireTokens(key, 2, windowMs, maxTokens);
  console.log('Request 2 tokens after window ->', res4);

  process.exit(0);
})();
