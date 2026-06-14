-- Subtract 3 hours from existing accidental-local timestamps to convert them to true UTC.

-- 1. Sales
UPDATE sales 
SET created_at = created_at - INTERVAL '3 hours'
WHERE created_at IS NOT NULL;

UPDATE sales 
SET voided_at = voided_at - INTERVAL '3 hours'
WHERE voided_at IS NOT NULL;

-- 2. Stock Movements
UPDATE stock_movements 
SET created_at = created_at - INTERVAL '3 hours'
WHERE created_at IS NOT NULL;

-- 3. Stock Levels
UPDATE stock_levels
SET updated_at = updated_at - INTERVAL '3 hours'
WHERE updated_at IS NOT NULL;

-- 4. Open Tabs
UPDATE open_tabs
SET created_at = created_at - INTERVAL '3 hours'
WHERE created_at IS NOT NULL;

UPDATE open_tabs
SET updated_at = updated_at - INTERVAL '3 hours'
WHERE updated_at IS NOT NULL;

UPDATE open_tabs
SET closed_at = closed_at - INTERVAL '3 hours'
WHERE closed_at IS NOT NULL;

-- 5. Invoices
UPDATE invoices
SET created_at = created_at - INTERVAL '3 hours'
WHERE created_at IS NOT NULL;

UPDATE invoices
SET paid_at = paid_at - INTERVAL '3 hours'
WHERE paid_at IS NOT NULL;

-- 6. Tab Items
UPDATE tab_items
SET created_at = created_at - INTERVAL '3 hours'
WHERE created_at IS NOT NULL;
