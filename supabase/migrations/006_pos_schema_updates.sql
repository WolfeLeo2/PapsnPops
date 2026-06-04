-- 006_pos_schema_updates.sql
-- Add variant fields to sale_items and tab_items
ALTER TABLE sale_items ADD COLUMN IF NOT EXISTS variant_id UUID REFERENCES product_variants(id);
ALTER TABLE sale_items ADD COLUMN IF NOT EXISTS variant_name TEXT;

ALTER TABLE tab_items ADD COLUMN IF NOT EXISTS variant_id UUID REFERENCES product_variants(id);
ALTER TABLE tab_items ADD COLUMN IF NOT EXISTS variant_name TEXT;

-- Add tab_id, cashier_id, and payment_reference to sales
ALTER TABLE sales ADD COLUMN IF NOT EXISTS tab_id UUID REFERENCES open_tabs(id);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS cashier_id UUID REFERENCES user_profiles(id);
ALTER TABLE sales ADD COLUMN IF NOT EXISTS payment_reference TEXT;
