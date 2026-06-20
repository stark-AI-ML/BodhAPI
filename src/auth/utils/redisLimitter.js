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

-- /fix see i am limiting this to return the correct order of the result

-- if current_tokens + tokens_requested > limit then
--   return 0 -- reject
-- end

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

/* well this is for you : i have this consederation how to chekck or store keys : 
  
  * the idea is -> if i fetch for max per minute token alloted to users that will put strain on db 
    i.e bad ux like more ms required on fetch and also fetching db  is expinsive? on ram 

  * but if i put it on redis it will be fast : but will let thing stored on my ram so? 
    it will consume more ram + how much keys i can put anyway? 

    like if 10000 user: api_key in crypto :crypto.randomBytes(18).toString('hex') === 36character_arr -> string

    so 10000*36 = 3600000 / 1024 = 351kb  with redis overhead of 100byte per we will hit 1-2mb 
    
   even consediring value data which isn't persistence as zrembyrange will delete it so its fine  
   so it okay with redis i know you will think it will crash but let see and you aren't hitting 10k users
   :(((((((((((((((    :)))))))))))))))

*/

(async () => {
  const userId = 'user123';
  const windowMs = 60000; // 1 minute
  const maxRequests = 10;

  await acquireTokens(userId, 2, windowMs, maxRequests);

  for (let i = 1; i <= 7; i++) {
    const count = await acquireTokens(userId, 2, windowMs, maxRequests);
    if (count == 0) {
      console.log(`Request ${i}: BLOCKED (limit reached, count=${count})`);
    } else {
      console.log(`Request ${i}: ALLOWED (count=${count})`);
    }
  }

  redis.quit();
})();

// (async () => {
//   const key = 'rate:user123';
//   const windowMs = 60000; // 1 minute
//   const maxTokens = 5; // max 5 requests per window
//   const tokensRequested = 1;

//   for (let i = 1; i <= 10; i++) {
//     const result = await acquireTokens(
//       key,
//       tokensRequested,
//       windowMs,
//       maxTokens
//     );
//     if (result === 0) {
//       console.log(`Request ${i}: BLOCKED (limit reached)`);
//     } else {
//       console.log(`Request ${i}: ALLOWED (count=${result})`);
//     }
//     await new Promise((r) => setTimeout(r, 200)); // 200ms gap between requests
//   }

//   redis.quit();
// })();
