-- KEYS[1] = redis key
-- ARGV[1] = current timestamp (ms)
-- ARGV[2] = window size (ms)
-- ARGV[3] = max requests

local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])

-- 1. Remove old requests
redis.call("ZREMRANGEBYSCORE", key, 0, now - window)

-- 2. Get current count
local count = redis.call("ZCARD", key)

if count >= limit then
  return count
end

-- 3. Add current request
redis.call("ZADD", key, now, now)

-- 4. Set expiry (optional safety)
redis.call("PEXPIRE", key, window)

return count + 1