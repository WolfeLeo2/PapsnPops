ALTER TABLE products ADD COLUMN base_unit TEXT NOT NULL DEFAULT 'piece';
ALTER TABLE products ADD COLUMN container_size INTEGER;
ALTER TABLE products ADD COLUMN container_name TEXT;
