CREATE TABLE IF NOT EXISTS portfolio_images (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  image_url TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (project_id) REFERENCES portfolio_projects(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_portfolio_images_project ON portfolio_images(project_id, sort_order);
