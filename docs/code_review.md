# Paps n Pops — Code Review & Architecture Notes

_Reviewed: 2026-06-18 · App version 1.8.0+15_

This document maps the architecture, flags the highest-risk pitfalls, and — at the
bottom — investigates the production report that **"some sales were made but cannot
be seen."**

---

## 1. Architecture Overview

**Stack:** Flutter + Riverpod (codegen) + go_router, offline-first via **PowerSync**
on top of **Supabase** (Postgres + Auth + Edge Functions).

```
UI (features/*)  →  Riverpod providers  →  Repositories (data/repositories)
                                              │
                                   db.watch / db.writeTransaction
                                              │
                                   PowerSync local SQLite
                                        ↑ download        ↓ upload
                                   sync-config.yaml   SupabaseConnector.uploadData
                                              │
                                        Supabase Postgres (RLS)
```

### Layers
- **`lib/domain/models`** — plain Dart models. Each has `fromRow(Map)` / `toRow()` that
  translate between SQLite rows and typed objects. Money is stored as **integer minor
  units** (cents); booleans as `0/1`; timestamps as **UTC ISO-8601 strings**.
- **`lib/data/powersync`** — `schema.dart` (local table definitions) and
  `powersync_client.dart` (the `SupabaseConnector` that uploads the local write queue
  to Supabase).
- **`lib/data/repositories`** — all DB access. Reads are `db.watch(...)` streams;
  writes go through `db.writeTransaction(...)`.
- **`lib/features/*`** — screen + provider per feature (pos, sales_history, stock,
  reports, tabs, invoices, dashboard, auth, settings).
- **`supabase/migrations`** — the **server** schema (source of truth) and **RLS**.
- **`powersync/sync-config.yaml`** — the **sync rules** that decide which server rows
  reach which device.

### The two access-control systems that MUST agree
This is the single most important thing to understand about this codebase. There are
**two independent gates**, fed by **two different data sources**:

| Concern | Mechanism | Source of truth |
|---|---|---|
| Can this device **upload/write** a row? | RLS policy `check_branch_access(branch_id)` | **JWT** `user_metadata.branch_ids` |
| Will this row **sync down** to a device? | `sync-config.yaml` `branch_data` stream | **`user_branch_access` table** |
| Which branch does the app **write sales to**? | `CurrentBranchId` provider | **JWT** `user_metadata.branch_ids` |

When the JWT `branch_ids` and the `user_branch_access` table disagree, you get
write-but-never-read-back behavior. **This divergence is the root architectural
hazard of the app** (see §3 H2).

---

## 2. Data flow for a sale (the critical path)

1. `cart_panel.dart` / `invoice_sheet.dart` / `tab_detail_panel.dart` build a `Sale`
   with `branchId = ref.read(currentBranchIdProvider)` and `cashierId = authUser.id`.
2. `SaleRepository.createSale` runs one `writeTransaction`: inserts `sales`, then each
   `sale_items`, then a `stock_movements` row, then updates `stock_levels` **locally**.
3. PowerSync records these as a CRUD transaction in its local upload queue.
4. `SupabaseConnector.uploadData` drains the queue **in strict order**, one transaction
   at a time, translating each op into a Supabase `upsert`/`update`/`delete`.
5. Server RLS authorizes the write (JWT branch check). Server triggers fire.
6. The row is replicated back down to every device whose `user_branch_access` includes
   that `branch_id`.

A sale is "visible to the client/owner" only if **all six** steps succeed. Steps 4, 5,
and 6 are where production sales silently fall off (see §3).

---

## 3. Sales-Visibility Investigation — "sales made but cannot be seen"

> **Verified against the live production database (`ugxjqmqiatbsapjmajnw`) on
> 2026-06-19.** The conclusion below is no longer hypothetical — the root-cause
> mechanism (H1) is confirmed by live logs and leftover data damage. The two
> originally-suspected divergence causes (orphaned cashiers, JWT vs access-table
> mismatch) were **checked and are NOT currently present** — see §3.1.

### 3.1 What the live data showed
- **Server-side sales data is clean and complete.** 77 sales total, **every** one has
  sale_items, **zero** NULL/dangling `cashier_id`, no `total = 0`, no sale whose
  `branch_id` is missing from `user_branch_access`. → Sales that *reach* the server are
  intact and reachable. The "missing" sales **never reached the server.**
- **No orphaned cashiers** — all 4 auth users have a `user_profiles` row (H-orphan ❌).
- **JWT `branch_ids` == `user_branch_access`** for all 4 users (H2 not active ❌).
- **🔴 SMOKING GUN — `product_variants` uploads are being rejected with `403` in
  production.** The API logs show a repeating pattern: `POST /rest/v1/products` → `200`,
  immediately followed by `POST /rest/v1/product_variants` → **`403`**, dozens of times.
- **🔴 Leftover damage:** org `5759415d` has **3 products with no variants** — the exact
  rows whose variant inserts were 403'd and never landed.

### H1 — A poisoned upload blocks the ENTIRE queue (CONFIRMED root cause) 🔴

`SupabaseConnector.uploadData` (`powersync_client.dart:24-67`):

```dart
} on PostgrestException catch (e) {
  if (e.code == '23505') {        // duplicate key → ack and move on
    await transaction.complete();
  } else {
    rethrow;                      // EVERYTHING else → throw
  }
}
```

PowerSync retries a failed transaction **forever, in order, before processing any
later transaction**. So a single write the server *permanently* rejects freezes the
whole queue. Every sale rung up afterward stays in local SQLite only — **the cashier
sees it on their screen, but it never reaches the server and the owner never sees it.**
This matches the symptom exactly.

Only `23505` (unique violation) is handled. **Crucially, the entire upload queue is a
single ordered stream — sales share it with product/variant/stock writes.** So a poison
write on *any* table strands every sale queued behind it on that device.

**The confirmed trigger in production: an RLS asymmetry between `products` and
`product_variants`.** Verified live:
- `products` INSERT/UPDATE/DELETE → policy `org_access_products` → allowed for **any org
  member** (`check_org_access(organisation_id)`). This is why product POSTs return `200`.
- `product_variants` INSERT → policy `owner_manage_variants` → required
  `auth.jwt()->'user_metadata'->>'role' = 'owner'`.

So when a **cashier** added a product + its variant (the app lets cashiers manage the
catalog — `stock_provider.dart:283,300` writes both with no role gate), the product
insert succeeded and the variant insert was **rejected with `403`**. The 3 orphaned
products (REDBULL 250ml, KONYAGI 750ml ×2 — all org `5759415d`, dated 06-10/06-14/06-15)
are cashier-created products whose variant insert 403'd. _(A second, rarer path to the
same 403 is an owner acting on a **stale token** before the `role` claim propagates.)_

PostgREST returns `403` (`PostgrestException`, not `23505`) → `uploadData` re-throws →
PowerSync halts the device's whole queue and retries forever → **any sale rung up on
that device afterward never uploads and is invisible to the owner/other devices.** The
3 variant-less products are the permanent scar this left.

Other permanent rejections that would wedge the queue identically (latent, not all
currently firing):
- **`23503` FK** on `cashier_id`/`staff_id`/`customer_id` if the referenced row was never
  synced up or was deleted server-side. (Note: `create-user/index.ts:90-94` deliberately
  does **not** throw if the `user_profiles` insert fails — it *can* create an orphaned
  cashier whose every sale 23503s. Not present today, but the code permits it.)
- **`23514` check** — `payment_method` outside `('cash','mpesa','card')` or `source`
  outside `('pos','tab','invoice')`.
- **`42703` undefined column** — local `schema.dart` drift vs server. _(Checked live:
  schema currently matches — not an active cause.)_

**Already confirmed via:** repeating `product_variants 403` in the REST API logs +
3 products with zero variants on the server.

**Fixes:**
- Make `create-user` **transactional** — roll back the auth user if the profile or
  `user_branch_access` inserts fail, instead of swallowing the error.
- In `uploadData`, stop letting one bad row wedge everything: catch terminal,
  non-retryable Postgres codes (`23502`, `23503`, `23514`, `42703`, `22P02`), **log
  them to a dead-letter store, and `transaction.complete()`** so the queue drains. A
  silently-dropped sale is bad, but a silently-frozen queue that loses *all* later
  sales is far worse. Surface both to the user/owner.

### H2 — JWT `branch_ids` ≠ `user_branch_access` table (latent; NOT active today) 🟡

> **Checked live (2026-06-19): all 4 users currently have matching JWT and
> `user_branch_access`, and no sale has an unreachable `branch_id`.** This is not the
> current cause, but it remains a real latent hazard because the safeguards that keep
> the two in sync are missing — keep it on the radar.


A sale's upload is authorized by the **JWT** (`check_branch_access` reads
`auth.jwt()->'user_metadata'->'branch_ids'`, `001_initial_schema.sql:256-262`), but
whether the sale **syncs back down** is gated by the **`user_branch_access` table**
(`sync-config.yaml` `branch_data` stream). If a `branch_id` is present in a user's JWT
but **absent from `user_branch_access`**, sales there upload successfully and then
**never sync to any device** — invisible everywhere except the originating phone's
local DB.

Concrete ways this diverges in production:
- **`create-user` swallows the `user_branch_access` insert error too**
  (`create-user/index.ts:104-106` — logs, doesn't throw). A user can end up with
  `branch_ids` in their JWT but no matching access rows → all their sales are
  write-only.
- **No "add branch" flow keeps the two in sync.** There is no code path anywhere that
  inserts into `user_branch_access` after creation except `create-user` and the
  onboarding function. If branches were added later by editing JWT metadata (dashboard
  / SQL), the access table was almost certainly not updated.
- **Owner branch switching.** `CurrentBranchId.setBranchId` lets an owner switch the
  active branch, and `createSale` writes to it. If that branch isn't in the owner's
  own `user_branch_access`, the owner's own sales won't sync back.

**How to confirm:**
```sql
-- branches a user can WRITE (JWT) vs can READ-BACK (table)
SELECT u.id, u.raw_user_meta_data->'branch_ids' AS jwt_branches,
       array_agg(uba.branch_id) AS access_table_branches
FROM auth.users u
LEFT JOIN user_branch_access uba ON uba.user_id = u.id
GROUP BY 1,2;
-- then: SELECT branch_id, count(*) FROM sales GROUP BY 1  → look for branches
-- with sales that no user has in user_branch_access.
```

**Fix:** Make `user_branch_access` the single source of truth (derive JWT from it, or
add a trigger/backfill that keeps them identical), and add a backfill migration that
inserts missing `(user_id, branch_id)` rows for every branch in every user's JWT.

### H3 — Sales are branch-scoped in the UI; owner is on the wrong branch 🟠

`salesHistoryStream` (`sales_history_provider.dart:78`) and
`SaleRepository.watchSales` both filter `WHERE branch_id = currentBranchId`, and
`CurrentBranchId` **always defaults to `branch_ids.first`**. There is no "all branches"
view. An owner with multiple branches only ever sees the first one's sales unless they
explicitly switch; sales rung up at other branches *look* missing even though they
synced fine. Worth confirming with the client: _"are the missing sales from a different
branch/till than the one you're looking at?"_

### H4 — Date-range / timezone filtering can hide recent sales 🟠

`created_at` is stored as UTC ISO strings, but the history date filter builds its
bounds from **local-naive** `DateTime`s:
`sales_history_provider.dart:83-86` uses `dateRange.start.toIso8601String()` and an end
bound of local `...23:59:59`, compared as strings against UTC values. Near day
boundaries (and this app's data has a known +3h offset history — see migrations `007`
and `012` which subtract `INTERVAL '3 hours'`), a sale can fall just outside a "today"
filter and appear missing. Any rows that predate the `012` fix, or were written by a
client version with the bug, will sort/filter into the wrong day. Convert filter bounds
to UTC before comparing, and audit for any remaining mis-offset `created_at` values.

### H5 — Local sales lost before the queue drains 🟠

Because of H1, a frozen queue means sales live only on-device. If the cashier logs out
(`disconnectAndClear` wipes the local DB) or the app is reinstalled before the queue
drains, those sales are **gone permanently**. There is a recent guard
(`hasPendingPowerSyncUploads`, used in the pre-logout check), but it only inspects the
*next* transaction and won't save the user if the queue is wedged on a poison row.

---

## 4. Other notable pitfalls (correctness, not visibility)

- **Double/triple stock decrement.** `createSale` decrements `stock_levels` **locally**
  *and* inserts a `stock_movements` row. The server then *also* runs
  `trg_decrement_stock AFTER INSERT ON sale_items` **and** `adjust_stock_on_movement
  AFTER INSERT ON stock_movements` (`001_initial_schema.sql:208-214`). When these
  server rows sync back down, stock can be decremented multiple times. Confirm exactly
  one authority owns stock math (recommend: client computes, server triggers are
  removed for synced tables — running business logic triggers on PowerSync-replicated
  tables is an anti-pattern).
- **`put` → `upsert` can resurrect deleted rows / clobber server-only columns.** The
  connector upserts the full local row. If the server has columns not in `schema.dart`
  (e.g. `stock_movements.stock_after`, `is_reverted`), an upsert from an older client
  won't include them — fine for upsert, but any server-computed column not echoed
  locally drifts. Keep `schema.dart` and the migrations strictly aligned.
- **`cost_price` placeholder = 0 on tab sales** (`tab_detail_panel.dart:540`) corrupts
  margin/profit reports for tab-originated sales.
- **No write-side validation of required fields.** Models null-coalesce empty strings to
  `null` in `toRow()`, but nothing guarantees FKs (`cashier_id`, `staff_id`) actually
  exist before the row is queued — which is precisely what feeds H1.
- **Split write-path on products/variants (offline-unsafe).** Catalog *creation* is
  offline-first via PowerSync (`stock_provider.dart:283,300` insert into local SQLite),
  but several edits — `updateProductActiveStatus`, `updateVariantActiveStatus`,
  `hardDeleteProduct`, `updateProductName` (`product_repository.dart:51,55,60,70`) —
  call `supabase.from(...).update/delete()` **directly**, bypassing the local DB. Those
  edits fail outright when offline and don't update local state optimistically, which is
  inconsistent with the rest of the app and a data-loss path on flaky connections. Route
  them through `db.writeTransaction` like everything else.
- **`promotion_ids` round-trip** is handled in two places (`Sale.toRow` JSON-encodes;
  the connector `jsonDecode`s back to a list for the Postgres `uuid[]`). Fragile but
  currently correct — keep them in lockstep.

---

## 5. Fixes & next steps

### ✅ Done (2026-06-19)
1. **`product_variants` write RLS fixed (root cause)** — migration
   `013_fix_product_variant_write_rls.sql`, applied to production. The owner-only
   `owner_manage_variants` / `owner_update_variants` / `owner_delete_variants` policies
   were dropped and replaced with org-scoped `org_insert_variants` /
   `org_update_variants` / `org_delete_variants` (mirroring `products`). Variant writes
   from any org member now succeed.
   - **Recovery is automatic and needs no app update:** PowerSync keeps retrying each
     wedged transaction. With the variant insert no longer `403`ing, the next retry
     succeeds, the queue drains in order, and the stranded sales (+ their
     variants/stock) flush to the server cleanly — no data loss, because the variant the
     sale_items depend on now lands too. Affected devices must simply be online.
2. **`uploadData` hardened (prevents recurrence)** — `powersync_client.dart`. Ops are now
   processed individually; permanently-rejected ones (RLS `42501`, `23502/3/14`,
   `22P02`, `42703`, `PGRST*`, …) are **dead-lettered** (recorded in `uploadDeadLetters`
   + logged) and skipped so the queue can never freeze on one bad row. Only transient
   errors (network/5xx) are retried. `23505` still treated as already-applied.
3. **`disconnectAndClear()` on logout removed (stops data loss)** — `powersync_client.dart`.
   `disconnectPowerSync()` now calls `db.disconnect()`, which preserves local data and
   the pending upload queue (it resumes on next `connect()`). Previously logout wiped the
   local DB — so a "Force Logout" with a wedged queue **permanently destroyed** the
   stuck sales (06-18 logout calls are visible in the auth logs; any with pending uploads
   are unrecoverable). Added `clearLocalDataIfSynced()` for the shared-device case, which
   only clears when the queue is empty. **Note: this fix only protects sales made from
   now on — it requires shipping a new app build.**

### ⏳ Next
3. **Verify recovery:** re-run the §3.1 audits over the next hours/days — the server
   sales count should climb well past 77 as devices reconnect and flush.
4. **Re-create the 3 orphaned variants** (REDBULL 250ml, KONYAGI 750ml ×2 in org
   `5759415d`) so those products are sellable and any historical `sale_items` resolve.
5. ✅ **Surface dead-letters in the UI** — `uploadDeadLetters` is now a reactive
   `ValueNotifier`; `UploadIssueBanner` (mounted at the top of `AppScaffold`, both
   layouts) shows a persistent error banner with a Details dialog and dismiss/clear when
   any change was skipped. Still in-memory — persisting to a local table survives app
   restarts and is a worthwhile follow-up.
6. ✅ **Centralized data-error reporting to Sentry** — new `core/utils/error_reporting.dart`
   provides `reportDataError()` (structured, tagged, never throws) and `guardWrite()`
   (report + rethrow so existing UI handling still runs). Wired into the places where
   business data can be lost/corrupted:
   - **Sync** (`uploadData`): dead-lettered ops captured as `warning` with tags
     `area=sync`, `table`, `crud_op`, `pg_code`; transient errors leave a breadcrumb.
   - **Local writes**: `createSale`, `voidSale`, `closeTab`, `createInvoice`,
     `logPayment`, `saveProduct` wrapped with `guardWrite` (tags by area + branch/org,
     extra context with ids/counts).
   - Filter in Sentry by `area:*` or `pg_code:*` to see which operation/table fails
     across the fleet. Unhandled errors are already captured by `SentryFlutter.init`.
   - **Intentionally NOT instrumented:** model `fromRow` parse `catch(_)` blocks — they
     run in hot stream loops over an optional field and would flood Sentry.
6. Make `create-user` transactional; keep `user_branch_access` and JWT `branch_ids`
   identical via trigger/backfill (closes latent H2).
7. Add an "all branches" sales view (or default owners to it); make the sales-history
   date filter timezone-correct (`sales_history_provider.dart:83-86` — the dashboard's
   `date(created_at,'localtime')` is already fine).
8. Resolve the client-vs-server stock authority duplication (§4).
9. **Unify the product/variant write path (§4).** Catalog *creation* goes through
   PowerSync (offline-first) but several edits (`product_repository.dart:51,55,60,70`)
   write **directly to Supabase**, bypassing the local DB — these silently fail offline
   and behave inconsistently with the rest of the app.
