-- Subtract 3 hours from existing accidental-local timestamps to convert them to true UTC.

-- 1. Sales
UPDATE sales 
SET created_at = (created_at::timestamptz - INTERVAL '3 hours')::text
WHERE created_at IS NOT NULL;

UPDATE sales 
SET voided_at = (voided_at::timestamptz - INTERVAL '3 hours')::text
WHERE voided_at IS NOT NULL;

-- 2. Stock Movements
UPDATE stock_movements 
SET created_at = (created_at::timestamptz - INTERVAL '3 hours')::text
WHERE created_at IS NOT NULL;

-- 3. Stock Levels
UPDATE stock_levels
SET updated_at = (updated_at::timestamptz - INTERVAL '3 hours')::text
WHERE updated_at IS NOT NULL;

-- 4. Open Tabs
UPDATE open_tabs
SET created_at = (created_at::timestamptz - INTERVAL '3 hours')::text
WHERE created_at IS NOT NULL;

UPDATE open_tabs
SET updated_at = (updated_at::timestamptz - INTERVAL '3 hours')::text
WHERE updated_at IS NOT NULL;

UPDATE open_tabs
SET closed_at = (closed_at::timestamptz - INTERVAL '3 hours')::text
WHERE closed_at IS NOT NULL;

-- 5. Invoices
UPDATE invoices
SET created_at = (created_at::timestamptz - INTERVAL '3 hours')::text
WHERE created_at IS NOT NULL;

UPDATE invoices
SET paid_at = (paid_at::timestamptz - INTERVAL '3 hours')::text
WHERE paid_at IS NOT NULL;

-- 6. Tab Items
UPDATE tab_items
SET created_at = (created_at::timestamptz - INTERVAL '3 hours')::text
WHERE created_at IS NOT NULL;
