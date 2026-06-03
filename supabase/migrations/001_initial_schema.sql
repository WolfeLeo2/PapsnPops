-- ── ORGANISATIONS ─────────────────────────────────────────
CREATE TABLE organisations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT now()
);

-- ── BRANCHES ──────────────────────────────────────────────
CREATE TABLE branches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  name            TEXT NOT NULL,
  address         TEXT,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ── USER PROFILES ─────────────────────────────────────────
CREATE TABLE user_profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  full_name       TEXT NOT NULL,
  role            TEXT NOT NULL CHECK (role IN ('owner', 'cashier')),
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ── USER BRANCH ACCESS ────────────────────────────────────
CREATE TABLE user_branch_access (
  user_id    UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  branch_id  UUID REFERENCES branches(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, branch_id)
);

-- ── STAFF ─────────────────────────────────────────────────
CREATE TABLE staff (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id  UUID NOT NULL REFERENCES branches(id),
  name       TEXT NOT NULL,
  role_label TEXT,
  is_active  BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── PRODUCTS ──────────────────────────────────────────────
CREATE TABLE products (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id     UUID NOT NULL REFERENCES organisations(id),
  name                TEXT NOT NULL,
  category            TEXT NOT NULL CHECK (category IN ('beer','spirits','wine','rtd','snacks','other')),
  selling_price       INTEGER NOT NULL,
  cost_price          INTEGER NOT NULL,
  unit                TEXT NOT NULL,
  low_stock_threshold INTEGER DEFAULT 10,
  is_active           BOOLEAN DEFAULT true,
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
);

-- ── STOCK LEVELS ──────────────────────────────────────────
CREATE TABLE stock_levels (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id),
  branch_id  UUID NOT NULL REFERENCES branches(id),
  quantity   INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (product_id, branch_id)
);

-- ── STOCK MOVEMENTS ───────────────────────────────────────
CREATE TABLE stock_movements (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id   UUID NOT NULL REFERENCES products(id),
  branch_id    UUID NOT NULL REFERENCES branches(id),
  user_id      UUID REFERENCES user_profiles(id),
  type         TEXT NOT NULL CHECK (type IN ('sale','receive','adjustment','void')),
  quantity     INTEGER NOT NULL,
  cost_price   INTEGER,
  reason       TEXT,
  reference_id UUID,
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- ── PROMOTIONS ────────────────────────────────────────────
CREATE TABLE promotions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  name            TEXT NOT NULL,
  type            TEXT NOT NULL CHECK (type IN ('percentage','fixed')),
  value           INTEGER NOT NULL,
  target_type     TEXT NOT NULL CHECK (target_type IN ('all','category','product')),
  target_value    TEXT,
  is_happy_hour   BOOLEAN DEFAULT false,
  happy_hour_start TIME,
  happy_hour_end   TIME,
  active_days     TEXT[],
  valid_from      DATE,
  valid_until     DATE,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ── CUSTOMERS ─────────────────────────────────────────────
CREATE TABLE customers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organisation_id UUID NOT NULL REFERENCES organisations(id),
  name            TEXT NOT NULL,
  phone           TEXT NOT NULL,
  company_name    TEXT,
  address         TEXT,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ── SALES ─────────────────────────────────────────────────
CREATE TABLE sales (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id      UUID NOT NULL REFERENCES branches(id),
  staff_id       UUID REFERENCES staff(id),
  customer_id    UUID REFERENCES customers(id),
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash','mpesa','card')),
  subtotal       INTEGER NOT NULL,
  discount_amount INTEGER NOT NULL DEFAULT 0,
  total          INTEGER NOT NULL,
  promotion_ids  UUID[],
  is_voided      BOOLEAN DEFAULT false,
  voided_by      UUID REFERENCES user_profiles(id),
  voided_at      TIMESTAMPTZ,
  source         TEXT DEFAULT 'pos' CHECK (source IN ('pos','tab','invoice')),
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- ── SALE ITEMS ────────────────────────────────────────────
CREATE TABLE sale_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id         UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id      UUID NOT NULL REFERENCES products(id),
  quantity        INTEGER NOT NULL,
  unit_price      INTEGER NOT NULL,
  cost_price      INTEGER NOT NULL,
  discount_amount INTEGER NOT NULL DEFAULT 0,
  line_total      INTEGER NOT NULL
);

-- ── OPEN TABS ─────────────────────────────────────────────
CREATE TABLE open_tabs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   UUID NOT NULL REFERENCES branches(id),
  name        TEXT NOT NULL,
  opened_by   UUID REFERENCES staff(id),
  customer_id UUID REFERENCES customers(id),
  is_open     BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ── TAB ITEMS ─────────────────────────────────────────────
CREATE TABLE tab_items (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tab_id     UUID NOT NULL REFERENCES open_tabs(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity   INTEGER NOT NULL,
  unit_price INTEGER NOT NULL,
  added_by   UUID REFERENCES staff(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── INVOICES ──────────────────────────────────────────────
CREATE TABLE invoices (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id        UUID NOT NULL REFERENCES sales(id),
  branch_id      UUID NOT NULL REFERENCES branches(id),
  customer_id    UUID NOT NULL REFERENCES customers(id),
  invoice_number TEXT NOT NULL,
  status         TEXT DEFAULT 'unpaid' CHECK (status IN ('unpaid','paid','overdue')),
  due_date       DATE,
  notes          TEXT,
  paid_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- ── CASH RECONCILIATIONS ──────────────────────────────────
CREATE TABLE cash_reconciliations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     UUID NOT NULL REFERENCES branches(id),
  cashier_id    UUID REFERENCES user_profiles(id),
  date          DATE NOT NULL,
  expected_cash INTEGER NOT NULL,
  actual_cash   INTEGER NOT NULL,
  discrepancy   INTEGER GENERATED ALWAYS AS (actual_cash - expected_cash) STORED,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (branch_id, cashier_id, date)
);

-- ── TRIGGERS ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION decrement_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE stock_levels
  SET quantity = quantity - NEW.quantity, updated_at = now()
  WHERE product_id = NEW.product_id
    AND branch_id = (SELECT branch_id FROM sales WHERE id = NEW.sale_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_decrement_stock
AFTER INSERT ON sale_items
FOR EACH ROW EXECUTE FUNCTION decrement_stock_on_sale();

CREATE OR REPLACE FUNCTION adjust_stock_on_movement()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO stock_levels (product_id, branch_id, quantity)
  VALUES (NEW.product_id, NEW.branch_id, NEW.quantity)
  ON CONFLICT (product_id, branch_id)
  DO UPDATE SET quantity = stock_levels.quantity + NEW.quantity, updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_adjust_stock
AFTER INSERT ON stock_movements
FOR EACH ROW
WHEN (NEW.type IN ('receive', 'adjustment'))
EXECUTE FUNCTION adjust_stock_on_movement();

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_update_stock_levels_updated_at BEFORE UPDATE ON stock_levels FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_update_open_tabs_updated_at BEFORE UPDATE ON open_tabs FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── RLS POLICIES ──────────────────────────────────────────
ALTER TABLE organisations ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_branch_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE open_tabs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tab_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_reconciliations ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION check_branch_access(target_branch_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN target_branch_id IN (
    SELECT jsonb_array_elements_text(auth.jwt()->'user_metadata'->'branch_ids')::uuid
  );
END;
$$ LANGUAGE plpgsql;

CREATE POLICY "branch_access_staff" ON staff FOR ALL USING (check_branch_access(branch_id));
CREATE POLICY "branch_access_stock_levels" ON stock_levels FOR ALL USING (check_branch_access(branch_id));
CREATE POLICY "branch_access_stock_movements" ON stock_movements FOR ALL USING (check_branch_access(branch_id));
CREATE POLICY "branch_access_sales" ON sales FOR ALL USING (check_branch_access(branch_id));
CREATE POLICY "branch_access_sale_items" ON sale_items FOR ALL USING (
  EXISTS (SELECT 1 FROM sales WHERE id = sale_items.sale_id AND check_branch_access(branch_id))
);
CREATE POLICY "branch_access_open_tabs" ON open_tabs FOR ALL USING (check_branch_access(branch_id));
CREATE POLICY "branch_access_tab_items" ON tab_items FOR ALL USING (
  EXISTS (SELECT 1 FROM open_tabs WHERE id = tab_items.tab_id AND check_branch_access(branch_id))
);
CREATE POLICY "branch_access_invoices" ON invoices FOR ALL USING (check_branch_access(branch_id));
CREATE POLICY "branch_access_cash_reconciliations" ON cash_reconciliations FOR ALL USING (check_branch_access(branch_id));

CREATE OR REPLACE FUNCTION check_org_access(target_org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN target_org_id = (auth.jwt()->'user_metadata'->>'organisation_id')::uuid;
END;
$$ LANGUAGE plpgsql;

CREATE POLICY "org_access_organisations" ON organisations FOR ALL USING (check_org_access(id));
CREATE POLICY "org_access_branches" ON branches FOR ALL USING (check_org_access(organisation_id));
CREATE POLICY "org_access_products" ON products FOR ALL USING (check_org_access(organisation_id));
CREATE POLICY "org_access_promotions" ON promotions FOR ALL USING (check_org_access(organisation_id));
CREATE POLICY "org_access_customers" ON customers FOR ALL USING (check_org_access(organisation_id));
CREATE POLICY "org_access_user_profiles" ON user_profiles FOR ALL USING (check_org_access(organisation_id));
CREATE POLICY "org_access_user_branch_access" ON user_branch_access FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = user_branch_access.user_id AND check_org_access(organisation_id))
);
