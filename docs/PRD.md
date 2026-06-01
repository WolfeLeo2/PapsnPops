# PRD — PAPs n POPs ERP/POS System

**Version:** 1.1  
**Status:** Active development  
**Last updated:** May 2026

---

## 1. Overview

PAPs n POPs is a custom point-of-sale and business management system built for a Kenyan liquor store with bar operations. The system handles daily sales, stock management, open bar tabs, formal B2B invoicing, team management, and business reporting across one or more branches.

### Goals
- Replace manual/paper-based sales tracking with a fast, reliable digital system
- Give the owner real-time visibility into stock levels, sales, and staff performance from any device
- Support bar tab operations (add items over time, close at end of session)
- Generate formal invoices for B2B customers with PDF sharing via WhatsApp
- Work reliably even when the internet is down

### Non-goals (v1)
- Customer loyalty / points system
- Automated supplier ordering
- Payroll management
- Accounting system integration (e.g. QuickBooks)
- E-commerce / online ordering

---

## 2. Users & roles

| Role | Description | Access |
|---|---|---|
| **Owner** | Business owner | All branches, all features, all settings |
| **Cashier** | Till operator | Assigned branch only — POS, tabs, stock view (no settings, no reports) |
| **Staff member** | Physical person (no login) | Appears as selectable salesperson on sales/invoices |

### Branch access logic
- Owner sees a **branch switcher** in the sidebar — can view "All branches" (combined) or switch to a specific branch
- Cashier sees a **static branch label** — no switching
- All data is tenant-isolated by `branch_id` at the database level via RLS

---

## 3. Features

### 3.1 Authentication
- Email + password login via Supabase Auth
- Session persists across app restarts
- Owner can create cashier accounts from Settings
- Password reset via email

### 3.2 Point of Sale

**Product search & cart**
- Search products by name (instant, local SQLite)
- Filter by category (Beer, Spirits, Wine, RTDs, Snacks, Other)
- Product card shows: name, unit of measure, price
- Tap to add to cart; qty stepper to adjust quantity
- In-cart products are visually highlighted in the grid

**Cart**
- Shows all cart items with name, unit, qty stepper, line total
- Salesperson selector (picks from staff list)
- Payment method selector: Cash, M-Pesa, Card
- Active promotions checked client-side against synced promotions table — discount chip shown inline
- Running total always visible

**Completing a sale**
- **Charge** — primary action. Promotions calculated client-side, sale written to Supabase, receipt shown
- **Save tab** — secondary action. Creates an open tab from current cart
- **Save as invoice** — overflow action (`···`). Opens invoice bottom sheet for B2B/credit sales

**Quick sale mode**  
Walk-in cash customers can skip the salesperson selector — a default "Walk-in" staff entry is pre-selected.

**Receipt screen**  
After a sale is charged: shows itemised receipt with totals, promotion applied, payment method. Actions: Download PDF, Print, Share (native share sheet), WhatsApp direct. PDF generated client-side using the `pdf` + `printing` Flutter packages — no server call needed.

### 3.3 Open tabs

**Tab list view**
- Lists all open tabs for the active branch
- Each tab shows: name (table number or customer name), duration open, item count, running total
- Duration badge colour: orange (< 1h), amber (1–2h), red (> 2h)
- Summary bar: active tab count, total outstanding, longest open tab

**Tab detail view**
- Full item list with timestamps (grouped by when items were added)
- Newer additions are visually tinted to distinguish from opening order
- Qty stepper on each item — can reduce or remove items
- "Add items" inline button — opens product search and adds to this tab
- Footer: subtotal, any active promotions, grand total
- Actions: **Close & charge** (primary), **Rename**, **Void tab** (destructive)

**Closing a tab**
- Client writes `sale` + `sale_items` to Supabase and marks `open_tabs.is_open = false` in a single Supabase transaction
- Stock decremented via DB trigger on `sale_items` insert
- Shows receipt screen (same as direct sale)

### 3.4 Stock management

**Products**
- Add / edit products: name, category, selling price, cost price, unit of measure, low stock threshold, is_active flag
- Unit of measure is configurable per product (e.g. bottle, crate, tot, can, pack)
- UOM conversions: e.g. 1 crate = 24 bottles — defined at product level
- Product list shows current stock level alongside product details
- Filter by category, sort by name / stock level / last updated

**Receive stock**
- Select product, enter quantity received and cost price at time of delivery
- Optional: supplier name, notes
- Writes a `stock_movement` record (type: `receive`)
- DB trigger increments `stock_levels.quantity`

**Stock adjustments**
- Manual corrections for breakage, theft, write-offs
- Requires a reason selection (Breakage / Theft / Correction / Other)
- Writes a `stock_movement` record (type: `adjustment`)
- Owner-only feature

**Low stock alerts**
- Shown on dashboard and in sidebar badge
- Threshold set per product
- Alert persists until stock is replenished above threshold

### 3.5 Invoices (B2B)

**Invoice creation** (from POS)
- Triggered from POS `···` menu → "Save as invoice"
- Bottom sheet collects:
  - Customer name (required)
  - Phone number (required)
  - Company / business name (optional)
  - Address (optional)
  - Charge now toggle (default: off)
  - Due date: 7 / 14 / 30 days / custom (shown when charge now is off)
  - Notes (optional)
- Invoice record written to Supabase
- PDF generated client-side using `pdf` + `printing` packages
- Shared via native share sheet (WhatsApp, email, download)

**Invoice PDF**
- PAPs n POPs branding (name, contact, branch)
- Invoice number (auto-incremented per branch)
- Date issued + due date
- Customer details
- Itemised list with quantities, unit prices, subtotals
- Promotions/discounts applied
- Grand total
- Payment status (Paid / Due / Overdue)

**Invoice list** (in Sales History)
- Tab alongside regular sales
- Filter: All / Paid / Outstanding / Overdue
- Mark as paid action (owner only)

### 3.6 Sales history

- Full list of all completed sales and closed tabs
- Filter by: date range, cashier, payment method, branch
- Search by sale ID or customer name
- Tap any sale to see full detail (items, timestamps, salesperson, payment)
- Owner can void a sale (writes reversal stock movements, flags sale as voided)

### 3.7 Branches

**Branch management** (Owner only, in Settings)
- Add a new branch: name, location/address
- Each branch is data-isolated — stock, sales, tabs, and staff are per-branch
- Deactivate a branch (hides from switcher, retains data)

**Branch switcher**
- Owner: dropdown in sidebar — options are "All branches" + each branch name
- "All branches" shows aggregated dashboard data
- Cashier: static label, no interaction

### 3.8 User accounts & staff

**User accounts** (logins)
- Owner creates cashier accounts: name, email, password, assigned branch
- Owner can deactivate accounts
- Cashiers cannot create or manage accounts

**Staff list** (no logins)
- Owner adds staff members: name, role label (optional), assigned branch
- Staff appear in the salesperson dropdown on POS and invoices
- Staff can be marked inactive (hidden from dropdowns)

### 3.9 Promotions

Managed by the owner under **Settings → Promotions**.

**Promotion types**
- **Percentage discount** — e.g. 10% off all spirits
- **Fixed amount discount** — e.g. KES 50 off Red Bull
- **Happy hour** — time-based: applies between set hours on selected days
- Promotions can target: all products / specific categories / specific products

**Promotion management** (Settings → Promotions)
- Add / edit / deactivate promotions
- Set: name, type, value, target, time conditions (for happy hour), active dates
- Multiple promotions can be active simultaneously; all matching ones apply

**At point of sale**
- Active promotions are read from local SQLite (already synced via PowerSync)
- Client checks time conditions, applies all matching promotions to the cart
- Promotion chip shows name + discount amount inline on the cart
- Discounts reflected in line totals and grand total

### 3.10 Reports (Owner only)

All reports computed client-side from local SQLite data — no server call needed. All data is already synced via PowerSync. Reports are filterable by date range (Today / Yesterday / This week / This month / Custom) and by branch.

**Sales summary**
- Total revenue, total sales count, gross profit, average sale value
- Revenue breakdown by payment method (cash / M-Pesa / card) with percentages
- Hourly revenue bar chart
- Trend vs previous period (↑ / ↓)

**Sales by cashier**
- Sales count, revenue, and average sale value per cashier
- For the selected date range and branch

**Products report**
- Top products by units sold (velocity)
- Revenue and gross profit per product
- Slow movers highlighted (products with 0 or very low sales in period)
- Cost vs selling price margin per product

**End-of-day reconciliation**
- Expected cash (sum of all cash sales)
- Cashier enters actual cash counted
- Discrepancy flagged in red if gap > 0
- Reconciliation records saved per day per branch

**Stock levels**
- Current quantity per product per branch
- Visual stock bar (full / low / critical)
- Last received date and quantity

**Export**
- All reports exportable as PDF (client-side, `pdf` + `printing`) or CSV

---

## 4. System architecture

```
┌──────────────────────────────────────────────────┐
│                  Flutter App                      │
│      (Windows desktop + Android/iOS mobile)       │
│                                                   │
│  ┌─────────────────┐      ┌────────────────────┐  │
│  │  Riverpod        │      │  Supabase          │  │
│  │  Providers       │      │  Client SDK        │  │
│  └────────┬─────────┘      └────────┬───────────┘  │
│           │ reads                   │ writes/auth  │
│           ▼                         ▼              │
│  ┌─────────────────┐                              │
│  │ PowerSync        │                              │
│  │ Local SQLite     │                              │
│  └────────┬─────────┘                              │
└───────────┼──────────────────────────────────────┘
            │ auto-sync (bidirectional)
            ▼
┌───────────────────────────────────┐
│           Supabase                │
│                                   │
│  ┌──────────────┐  ┌───────────┐  │
│  │  PostgreSQL  │  │   Auth    │  │
│  │   + RLS      │  └───────────┘  │
│  └──────────────┘                 │
└───────────────────────────────────┘
```

### Data flow
- **Everything syncs** — all tables are synced to local SQLite via PowerSync. No selective sync, no offline exceptions. The dataset for a single liquor store is small; sync it all.
- **Reads**: always from local PowerSync SQLite — instant, works offline
- **Writes**: Flutter writes to Supabase via client SDK — PowerSync syncs changes back down automatically
- **Reports**: computed client-side from local SQLite — no server aggregation needed
- **PDFs**: generated client-side using `pdf` + `printing` — no server storage needed
- **Promotions**: validated client-side against synced promotions table — no Edge Function needed
- **No Edge Functions in v1** — the architecture is Flutter + Supabase + PowerSync, nothing else

---

## 5. Database schema

All monetary values stored as **integers in Kenya Shillings × 100** (KES 1,200 = `120000`). All tables include `created_at` and `updated_at` where relevant. RLS enabled on all tables.

```sql
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
```

### Key DB triggers

```sql
-- Decrement stock on sale item insert
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

-- Adjust stock on receive or manual adjustment
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

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
-- Apply to: products, stock_levels, open_tabs
```

### RLS policy pattern

```sql
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branch_access" ON sales
  FOR ALL USING (
    branch_id IN (
      SELECT branch_id FROM user_branch_access WHERE user_id = auth.uid()
    )
  );
-- Same pattern applied to all tables
```

---

## 6. Route guards & privilege model

Role is read from JWT metadata (`auth.jwt()->'user_metadata'->>'role'`) on login, stored in a global Riverpod provider, and never re-fetched unless the session changes.

Guards are enforced at two levels — route level (go_router `redirect`) and widget level (UI visibility). RLS at the DB level is the final safety net regardless of what the client does.

### Owner-only routes

| Route | Reason |
|---|---|
| `/reports` | Business intelligence — cashier has no need |
| `/settings` | All settings sub-routes |
| `/settings/branches` | Branch management |
| `/settings/users` | User account creation/deactivation |
| `/settings/staff` | Staff list management |
| `/settings/promotions` | Promotion engine management |

All of the above redirect to `/pos` if the authenticated user's role is `cashier`.

### Owner-only actions (within shared screens)

These screens are accessible to cashiers but certain actions within them are hidden or disabled:

| Screen | Restricted action | Reason |
|---|---|---|
| Sales history | Void a sale | Fraud prevention — cashier cannot undo their own sales |
| Stock / Products | Stock adjustment (breakage, write-off) | Owner-only audit action |
| Dashboard | Branch switcher | Cashier sees static label only |

### go_router guard pattern

```dart
// In app.dart — applied to all owner-only routes
redirect: (context, state) {
  final role = ref.read(authProvider).role;
  if (role != 'owner') return '/pos';
  return null;
},
```

### Sale voiding

Voiding is an owner-only action that safely undoes a completed sale without deleting any records:

1. Owner marks `sales.is_voided = true`, sets `voided_by` + `voided_at`
2. Reversal `stock_movements` are written (type: `void`, positive quantity) to restore stock
3. The original sale record is **never deleted** — it remains in the audit trail
4. Reports exclude voided sales from revenue totals but can display them separately
5. Cashier cannot void their own sales — must request owner approval

---

## 7. Edge Functions

There is exactly one Edge Function in this project. It exists solely because Supabase's user creation API (`admin.createUser()`) requires the service role key, which cannot live in the Flutter client.

### `create-user`
```
POST /functions/v1/create-user
Body: {
  email: string,
  password: string,
  full_name: string,
  role: 'cashier',
  organisation_id: string,
  branch_ids: string[]   // one branch for cashier, all branches for owner
}
```

**What it does:**
1. Validates the caller's JWT — verifies the calling user has `role: 'owner'`
2. Calls `supabase.auth.admin.createUser()` with the provided credentials
3. Sets `raw_user_meta_data` on the new auth user (see User metadata below)
4. Inserts a row into `user_profiles`
5. Inserts rows into `user_branch_access` for each branch in `branch_ids`

No other Edge Functions exist or are needed.

---

## 8. User metadata

Every Supabase auth user has the following `raw_user_meta_data` set at creation time by the `create-user` Edge Function:

```json
{
  "role": "cashier",
  "full_name": "Brian Odhiambo",
  "organisation_id": "uuid-here",
  "branch_ids": ["uuid-branch-1"]
}
```

For an owner:
```json
{
  "role": "owner",
  "full_name": "James M.",
  "organisation_id": "uuid-here",
  "branch_ids": ["uuid-branch-1", "uuid-branch-2"]
}
```

**Why metadata matters:**

- **PowerSync** reads `user_metadata` directly from the JWT to determine which branches to sync — no extra DB lookup needed at sync time
- **RLS policies** can reference `auth.jwt()->'user_metadata'` directly for fast, join-free access checks
- **Flutter** reads the role from metadata on login to decide which UI to render (owner layout vs cashier layout)

When a cashier is reassigned to a different branch, the owner calls the `create-user` function's companion `update-user-metadata` endpoint (same function, different action) to refresh the JWT metadata.

---

## 9. Security

- **RLS on every table** — enforced at DB level, not just app code
- **No service role key on client** — only `anonKey` in Flutter; service key only in the `create-user` Edge Function
- **RLS via metadata** — policies reference `auth.jwt()->'user_metadata'` directly, avoiding joins on every request
- **Money as integers** — no floating point arithmetic in the money chain
- **Input validation** — Flutter form validators on client + DB constraints server-side
- **Audit trail** — `stock_movements` records every stock change with user ID + timestamp; voided sales retain their records with void metadata
- **Secure storage** — auth tokens in `flutter_secure_storage`, never `SharedPreferences`

---

## 10. Offline strategy

**Everything syncs. No exceptions.** PowerSync syncs all tables to local SQLite automatically. The dataset for a single liquor store branch is small — there is no benefit to selective sync and significant complexity cost.

All core operations work fully offline:
- POS sales
- Tab management
- Stock viewing
- Reports (computed from local SQLite)
- PDF generation (client-side)

Writes made offline are queued by PowerSync and uploaded to Supabase automatically when connectivity returns. The UI shows a subtle connectivity indicator (synced / syncing / offline) in the sidebar footer — never blocks the user.

---

## 11. Flutter package list

```yaml
dependencies:
  flutter_riverpod:
  riverpod_annotation:
  go_router:
  powersync:
  supabase_flutter:
  phosphor_flutter:
  pdf:
  printing:
  share_plus:
  flutter_secure_storage:
  intl:
  google_fonts:
  fl_chart:
  shared_preferences:       # theme mode preference persistence

dev_dependencies:
  riverpod_generator:
  build_runner:
  flutter_lints:
  very_good_analysis:
```

---

## 12. Development phases

### Phase 1 — Core POS (Milestone 1 · KES 12,000 deposit)
- [ ] Project setup: Flutter, Supabase, PowerSync, Riverpod, go_router
- [ ] Auth (login screen, session persistence)
- [ ] DB schema + RLS + triggers (initial migration)
- [ ] Product management (add, edit, list)
- [ ] Stock levels (receive stock, view levels)
- [ ] POS screen (search, cart, charge — cash and M-Pesa)
- [ ] Client-side promotion engine
- [ ] Receipt screen (view, PDF via `pdf` + `printing`)

**Milestone 1 deliverable:** Working POS — cashier can log in, add products, apply promotions, charge a sale, view and share receipt.

### Phase 2 — Tabs, Invoices, Reports (Milestone 2 · KES 12,000)
- [ ] Open tabs screen (create, add to, close)
- [ ] Invoice bottom sheet + client-side PDF generation
- [ ] B2B customer records
- [ ] Sales history screen
- [ ] Reports screen (all 5 tabs, client-side computed)
- [ ] Promotions management screen (Settings → Promotions)
- [ ] End-of-day reconciliation

**Milestone 2 deliverable:** Full working system demoed live.

### Phase 3 — Polish & handover (Final · KES 8,000)
- [ ] Branch management + multi-branch switcher
- [ ] User accounts + staff management
- [ ] Settings screen (Business, Team, Promotions, Products, Receipts)
- [ ] Mobile responsive layout (owner phone monitoring)
- [ ] Connectivity indicator
- [ ] PDF export for reports
- [ ] Bug fixes, performance, UX polish
- [ ] Client training session
- [ ] Deployment (Supabase project, app installation on Windows PC)

**Final deliverable:** Installed, trained, signed off.
