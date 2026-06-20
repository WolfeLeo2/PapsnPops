-- Fix product_variants write RLS.
--
-- ROOT CAUSE of "sales made but not visible":
-- `products` allows INSERT/UPDATE/DELETE for any org member (org_access_products ->
-- check_org_access), but `product_variants` required role = 'owner'
-- (owner_manage_variants). So when a CASHIER added a product + its variant, the product
-- write succeeded (200) while the variant write was rejected by RLS (403). The PowerSync
-- connector rethrows that 403, and PowerSync retries the failed CRUD transaction in
-- order, forever, before any later transaction -> the device's entire upload queue
-- wedges -> every sale rung up afterward is stranded in local SQLite and never reaches
-- the server (invisible to the owner / other devices).
--
-- FIX: align product_variants write policies with products (organisation-scoped via the
-- parent product's organisation). After this is applied, previously-wedged clients will
-- succeed on their next retry and automatically flush their backlog of stuck sales.

DROP POLICY IF EXISTS "owner_manage_variants" ON public.product_variants;
DROP POLICY IF EXISTS "owner_update_variants" ON public.product_variants;
DROP POLICY IF EXISTS "owner_delete_variants" ON public.product_variants;

-- INSERT: any member of the parent product's organisation
CREATE POLICY "org_insert_variants" ON public.product_variants
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM products
    WHERE products.id = product_variants.product_id
      AND check_org_access(products.organisation_id)
  )
);

-- UPDATE: same org scope on both the existing row and the new row
CREATE POLICY "org_update_variants" ON public.product_variants
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM products
    WHERE products.id = product_variants.product_id
      AND check_org_access(products.organisation_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM products
    WHERE products.id = product_variants.product_id
      AND check_org_access(products.organisation_id)
  )
);

-- DELETE: same org scope
CREATE POLICY "org_delete_variants" ON public.product_variants
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM products
    WHERE products.id = product_variants.product_id
      AND check_org_access(products.organisation_id)
  )
);
