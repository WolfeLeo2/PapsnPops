ALTER TABLE stock_movements
ADD COLUMN stock_after INTEGER,
ADD COLUMN is_reverted BOOLEAN DEFAULT false,
ADD COLUMN reverted_by UUID REFERENCES user_profiles(id),
ADD COLUMN reverted_at TIMESTAMPTZ;
