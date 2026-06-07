-- ── INVOICE PAYMENTS ─────────────────────────────────────────
CREATE TABLE invoice_payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id        UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  branch_id         UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  amount            INTEGER NOT NULL,
  payment_method    TEXT NOT NULL,
  payment_reference TEXT,
  cashier_id        UUID NOT NULL REFERENCES user_profiles(id),
  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE invoice_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "branch_access_invoice_payments" ON invoice_payments FOR ALL USING (check_branch_access(branch_id));

-- ── TRIGGER: UPDATE INVOICE STATUS ───────────────────────────
CREATE OR REPLACE FUNCTION update_invoice_status_on_payment()
RETURNS TRIGGER AS $$
DECLARE
  total_paid INTEGER;
  invoice_total INTEGER;
BEGIN
  -- Get the total paid so far for this invoice
  SELECT COALESCE(SUM(amount), 0) INTO total_paid
  FROM invoice_payments
  WHERE invoice_id = NEW.invoice_id;

  -- Get the total amount of the invoice from the linked sale
  SELECT s.total INTO invoice_total
  FROM invoices i
  JOIN sales s ON i.sale_id = s.id
  WHERE i.id = NEW.invoice_id;

  -- If fully paid, update status
  IF total_paid >= invoice_total THEN
    UPDATE invoices
    SET status = 'paid', paid_at = now()
    WHERE id = NEW.invoice_id AND status != 'paid';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_invoice_payment
AFTER INSERT OR UPDATE ON invoice_payments
FOR EACH ROW EXECUTE FUNCTION update_invoice_status_on_payment();

-- ── PG_NET NOTIFICATION WEBHOOKS ─────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.notify_owner_webhook()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://ugxjqmqiatbsapjmajnw.supabase.co/functions/v1/notify-owner',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVneGpxbXFpYXRic2Fwam1ham53Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNDM3NDAsImV4cCI6MjA5NTgxOTc0MH0.6NXdrg-Pp3ZKyDVrubdgGWBiQLw4yYCpibE7QeBT3m8"}'::jsonb,
    body := json_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW),
      'old_record', row_to_json(OLD)
    )::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER webhook_notify_sales
AFTER INSERT OR UPDATE ON public.sales
FOR EACH ROW EXECUTE FUNCTION public.notify_owner_webhook();

CREATE TRIGGER webhook_notify_open_tabs
AFTER INSERT OR UPDATE ON public.open_tabs
FOR EACH ROW EXECUTE FUNCTION public.notify_owner_webhook();

CREATE TRIGGER webhook_notify_stock_levels
AFTER INSERT OR UPDATE ON public.stock_levels
FOR EACH ROW EXECUTE FUNCTION public.notify_owner_webhook();
