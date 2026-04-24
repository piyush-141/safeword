-- ============================================================
-- SafeWord Database Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- Enable UUID extension (already enabled by default in Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Table: credentials ──────────────────────────────────────────────────────
CREATE TABLE credentials (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  title       TEXT        NOT NULL CHECK (char_length(title) BETWEEN 1 AND 255),
  username    TEXT,
  password    TEXT        NOT NULL,  -- AES-256-CBC encrypted ciphertext (base64)
  more_info   TEXT,

  iv          TEXT        NOT NULL,  -- AES initialization vector (base64, unique per credential)
  salt        TEXT        NOT NULL,  -- PBKDF2 salt (per-user, stored for convenience)

  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── Row Level Security ───────────────────────────────────────────────────────
ALTER TABLE credentials ENABLE ROW LEVEL SECURITY;

-- Users can ONLY read their own credentials
CREATE POLICY "Users can only access their own credentials"
ON credentials
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- ─── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_credentials_user_id  ON credentials(user_id);
CREATE INDEX idx_credentials_title    ON credentials(user_id, title);
CREATE INDEX idx_credentials_updated  ON credentials(user_id, updated_at DESC);

-- ─── Auto-update updated_at ───────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON credentials
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ─── Verify setup ─────────────────────────────────────────────────────────────
-- Run these to confirm everything is in order:
-- SELECT * FROM credentials LIMIT 5;
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'credentials';
