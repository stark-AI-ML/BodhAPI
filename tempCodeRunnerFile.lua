-- KEYS[1] = key
-- ARGV[1] = now
-- ARGV[2] = window
-- ARGV[3] = max_tokens
-- ARGV[4] = tokens_requested

local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local max_tokens = tonumber(ARGV[3])
local tokens_requested = tonumber(ARGV[4])

-- remove old
redis.call("ZREMRANGEBYSCORE", key, 0, now - window)

-- current usage
local current = redis.call("ZCARD", key)

-- check limit BEFORE adding
if (current + tokens_requested) > max_tokens then
  return -1
end

-- add tokens
for i=1,tokens_requested do
  redis.call("ZADD", key, now, now .. "-" .. i)
end

redis.call("PEXPIRE", key, window)

return current + tokens_requested