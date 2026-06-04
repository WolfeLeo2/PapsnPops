-- Align open_tabs columns in PostgreSQL
ALTER TABLE open_tabs ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE open_tabs ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;
ALTER TABLE open_tabs ADD COLUMN IF NOT EXISTS sale_id UUID REFERENCES sales(id);

-- Align customers columns in PostgreSQL
ALTER TABLE customers ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS loyalty_points INTEGER DEFAULT 0;
