-- migrate:up
ALTER TABLE refresh_token
ALTER COLUMN revoked_at DROP DEFAULT,
ALTER COLUMN revoked_at DROP NOT NULL;

-- migrate:down
ALTER TABLE refresh_token
ALTER COLUMN revoked_at SET DEFAULT now(),
ALTER COLUMN revoked_at SET NOT NULL;
