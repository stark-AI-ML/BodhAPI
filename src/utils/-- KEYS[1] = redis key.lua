-- KEYS[1] = redis key
-- ARGV[1] = current timestamp (ms)
-- ARGV[2] = window size (ms)
-- ARGV[3] = max tokens
-- ARGV[4] = tokens requested

local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local tokens_requested = tonumber(ARGV[4])

-- 1. remove old tokens from timestamp 0 to current time

redis.call("ZREMRANGEBYSCORE", key, 0, now - window)

-- 2. Count tokens in window  -- see now-window(time) (is min time we want, to now(present) )

local current_tokens = redis.call("ZCOUNT", key, now - window, now)

-- 3. Add tokens (store with timestamp as score)
for i=1,tokens_requested do
  redis.call("ZADD", key, now, tostring(now) .. ":" .. tostring(i))
end

-- 4. Expiry safety
redis.call("PEXPIRE", key, window)

return current_tokens + tokens_requested