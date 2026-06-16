const apiKeyMiddleware = async (req, res, next) => {
  const apiKey = req.headers['x-api-key'];

  if (!apiKey) {
    return res.status(401).json({ message: 'API key required' });
  }

  const prefix = apiKey.split('_').slice(0, 3).join('_');
  // sk_live_ab12cd34

  const result = await db.query(
    `SELECT * FROM api_keys WHERE key_prefix = $1 AND revoked = false`,
    [prefix]
  );

  const key = result.rows[0];

  if (!key) {
    return res.status(401).json({ message: 'Invalid API key' });
  }

  const isValid = await compareToken(apiKey, key.key_hash);

  if (!isValid) {
    return res.status(401).json({ message: 'Invalid API key' });
  }

  req.user_id = key.user_id;
  next();
};
