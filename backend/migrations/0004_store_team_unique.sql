-- A person can have exactly one role per store.
CREATE UNIQUE INDEX IF NOT EXISTS idx_store_employees_store_user ON store_employees(store_id, user_id);
