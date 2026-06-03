-- 1. Create Categories Table
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Owners can manage categories" ON categories 
  FOR ALL USING (auth.jwt()->'user_metadata'->>'role' = 'owner');

-- Insert default categories
INSERT INTO categories (name, icon) VALUES 
  ('Beers', 'beer_bottle'), 
  ('Spirits', 'martini'), 
  ('Soft Drinks', 'soda_can');

-- Modify Products Table to reference Categories
ALTER TABLE products ADD COLUMN category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE products DROP COLUMN category;

-- 2. Create Adjustment Reasons Table
CREATE TABLE adjustment_reasons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE adjustment_reasons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read adjustment reasons" ON adjustment_reasons FOR SELECT USING (true);
CREATE POLICY "Owners can manage reasons" ON adjustment_reasons 
  FOR ALL USING (auth.jwt()->'user_metadata'->>'role' = 'owner');

-- Insert default reasons
INSERT INTO adjustment_reasons (name) VALUES 
  ('New Delivery'), 
  ('Breakage'), 
  ('Audit'), 
  ('Stock Correction');
