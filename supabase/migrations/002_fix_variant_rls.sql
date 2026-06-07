DROP POLICY IF EXISTS "read_variants" ON "public"."product_variants";

CREATE POLICY "read_variants" ON "public"."product_variants"
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM products
    WHERE products.id = product_variants.product_id
    AND check_org_access(products.organisation_id)
  )
);
