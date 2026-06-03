-- Migration 004: Product Variants
-- Creates the product_variants table to support multiple variants (sizes/units) per product.
-- Migrates existing products' prices to a default "Bottle" variant.
-- Note: The products table in this environment only had selling_price and cost_price
-- (no wholesale_price/barcode/sku), so the INSERT uses NULL for those fields.

-- Create product_variants table
CREATE TABLE product_variants (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id        UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  unit_label        TEXT NOT NULL DEFAULT 'unit',
  conversion_factor INTEGER NOT NULL DEFAULT 1,
  selling_price     INTEGER NOT NULL,
  cost_price        INTEGER NOT NULL,
  wholesale_price   INTEGER,
  barcode           TEXT,
  sku               TEXT,
  is_active         BOOLEAN DEFAULT true,
  is_default        BOOLEAN DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- Migrate existing products to default variants
-- Note: products table only has selling_price and cost_price (no wholesale_price/barcode/sku)
INSERT INTO product_variants (product_id, name, unit_label, conversion_factor, selling_price, cost_price, wholesale_price, barcode, sku, is_default)
SELECT 
  id,
  'Bottle',
  COALESCE(unit, 'btl'),
  1,
  selling_price,
  cost_price,
  NULL,
  NULL,
  NULL,
  true
FROM products;

-- Remove price/unit fields from products table (they live on variants now)
ALTER TABLE products DROP COLUMN IF EXISTS selling_price;
ALTER TABLE products DROP COLUMN IF EXISTS cost_price;
ALTER TABLE products DROP COLUMN IF EXISTS wholesale_price;
ALTER TABLE products DROP COLUMN IF EXISTS barcode;
ALTER TABLE products DROP COLUMN IF EXISTS sku;
ALTER TABLE products DROP COLUMN IF EXISTS unit;
-- Rename low_stock_threshold to reorder_level
ALTER TABLE products RENAME COLUMN low_stock_threshold TO reorder_level;

-- RLS on product_variants
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read_variants" ON product_variants FOR SELECT USING (true);
CREATE POLICY "owner_manage_variants" ON product_variants
  FOR INSERT WITH CHECK (auth.jwt()->'user_metadata'->>'role' = 'owner');
CREATE POLICY "owner_update_variants" ON product_variants
  FOR UPDATE USING (auth.jwt()->'user_metadata'->>'role' = 'owner');
CREATE POLICY "owner_delete_variants" ON product_variants
  FOR DELETE USING (auth.jwt()->'user_metadata'->>'role' = 'owner');
