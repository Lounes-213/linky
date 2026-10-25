CREATE TABLE IF NOT EXISTS profile_sections (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  section_key TEXT NOT NULL,
  is_visible INTEGER DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE(user_id, section_key)
);

INSERT INTO profile_sections (id, user_id, section_key, is_visible, sort_order)
SELECT hex(randomblob(16)), id, 'links', 1, 0 FROM users WHERE NOT EXISTS (SELECT 1 FROM profile_sections WHERE user_id = users.id AND section_key = 'links')
UNION ALL
SELECT hex(randomblob(16)), id, 'stores', 1, 1 FROM users WHERE NOT EXISTS (SELECT 1 FROM profile_sections WHERE user_id = users.id AND section_key = 'stores')
UNION ALL
SELECT hex(randomblob(16)), id, 'portfolio', 1, 2 FROM users WHERE NOT EXISTS (SELECT 1 FROM profile_sections WHERE user_id = users.id AND section_key = 'portfolio')
UNION ALL
SELECT hex(randomblob(16)), id, 'products', 1, 3 FROM users WHERE NOT EXISTS (SELECT 1 FROM profile_sections WHERE user_id = users.id AND section_key = 'products');
