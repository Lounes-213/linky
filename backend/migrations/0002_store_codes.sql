-- Store creation codes
CREATE TABLE IF NOT EXISTS store_codes (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  is_used INTEGER DEFAULT 0,
  used_by TEXT,
  used_at TEXT,
  created_by TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_store_codes_code ON store_codes(code);
CREATE INDEX IF NOT EXISTS idx_store_codes_is_used ON store_codes(is_used);
