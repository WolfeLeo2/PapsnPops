CREATE OR REPLACE FUNCTION decrement_stock_on_sale()
RETURNS TRIGGER AS $$
DECLARE
  factor INTEGER;
BEGIN
  -- Get the conversion factor for the variant
  SELECT conversion_factor INTO factor 
  FROM product_variants 
  WHERE id = NEW.variant_id;
  
  -- Fallback if no variant or factor is found
  IF factor IS NULL THEN
    factor := 1;
  END IF;

  UPDATE stock_levels
  SET quantity = quantity - (NEW.quantity * factor), updated_at = now()
  WHERE product_id = NEW.product_id
    AND branch_id = (SELECT branch_id FROM sales WHERE id = NEW.sale_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
