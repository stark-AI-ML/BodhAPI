CREATE TABLE api_keys(
  id UUID PRIMARY KEY, 
  user_id UUID REFERENCES users(id) ON DELETE CASCADE, 
  key_hash TEXT NOT NULL,
  key_prefix TEXT,
  revoked BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(), 
  last_used_at TIMESTAMP
);

-- indexes 
CREATE INDEX idx_prefix ON api_keys(key_prefix); -- for fast key lookup 
CREATE INDEX idx_user ON api_keys(user_id); --for fast user search on api_key table