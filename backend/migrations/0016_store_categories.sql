CREATE TABLE IF NOT EXISTS store_categories (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL,
  name TEXT NOT NULL,
  color_val INTEGER DEFAULT 34762495,
  frame_style TEXT DEFAULT 'filled',
  sort_order INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_store_categories_store ON store_categories(store_id, sort_order);
