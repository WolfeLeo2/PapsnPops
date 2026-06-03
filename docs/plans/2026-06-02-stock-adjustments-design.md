# Stock Adjustments Design

Date: 2026-06-02

## Summary

PAPs n POPs will move from immediate stock mutation on receive/adjustment to a Zynk-style stock adjustment workflow. Users create a batch of proposed stock changes. By default, the batch remains pending until approved. Approval creates stock movements, and the existing server trigger remains the source of truth for updating `stock_levels`.

This gives the app better auditability, safer correction before stock changes, and a clearer sync model.

## Goals

- Create stock adjustment batches with multiple line items.
- Keep adjustments pending by default.
- Allow pending adjustments to be approved, rejected, deleted, or edited.
- Keep `stock_movements` as the stock-changing audit table.
- Keep `stock_levels` server-trigger-authoritative.
- Add an org-wide auto-approve setting, off by default.
- Show Current Stock and New Stock in the UI before approval.
- Support positive and negative adjustments while preventing final negative stock.

## Non-goals

- Do not add a new Edge Function.
- Do not move stock calculations into Flutter widgets.
- Do not update `stock_levels` directly from the client for adjustment creation.
- Do not require a central Zynk-style `repository.dart`; Paps can keep feature-scoped repositories/providers.

## Data model

### `stock_adjustments`

Add a new Supabase table, synced through PowerSync.

Each row represents one product adjustment line. Rows are grouped into a batch by `bundle_id`.

Suggested columns:

- `id uuid primary key default gen_random_uuid()`
- `bundle_id uuid not null`
- `branch_id uuid not null references branches(id)`
- `product_id uuid not null references products(id)`
- `quantity integer not null`
- `adjustment_type text not null`
- `reason text`
- `reference text`
- `created_by uuid references user_profiles(id)`
- `status text not null default 'pending' check (status in ('pending', 'approved', 'rejected'))`
- `approved_by uuid references user_profiles(id)`
- `approved_at timestamptz`
- `rejected_by uuid references user_profiles(id)`
- `rejected_at timestamptz`
- `rejection_reason text`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### Organisation setting

Add to `organisations`:

- `auto_approve_stock_adjustments boolean not null default false`

This setting is org-wide and persists across devices.

### Sync rules

Update `powersync/sync-rules.yaml`:

- Add `stock_adjustments` to the branch bucket:
  - `SELECT * FROM stock_adjustments WHERE branch_id = bucket.branch_id`
- Add organisation data to sync the current organisation row, including `auto_approve_stock_adjustments`.

### PowerSync local schema

Update `lib/data/powersync/schema.dart`:

- Add the new `stock_adjustments` table.
- Add `auto_approve_stock_adjustments` to `organisations` if/when `organisations` is included in the local schema.

## RLS and security

- Enable RLS on `stock_adjustments`.
- Add a branch-access policy using the same pattern as `stock_movements` and `stock_levels`:
  - `check_branch_access(branch_id)`
- Use existing org RLS for `organisations`.
- Owner-only UI controls should gate approval, rejection, deletion, and editing unless the product decision changes later.
- Approved/rejected adjustments are immutable in the UI.

## Workflow

### Create adjustment batch

`ReceiveStockScreen` becomes the batch creation UI.

When the user confirms:

1. Validate branch selection, selected products, reason, and quantities.
2. Generate a single `bundle_id` for the batch.
3. Insert one `stock_adjustments` row per product/branch item.
4. If `auto_approve_stock_adjustments` is false, leave rows `pending`.
5. If `auto_approve_stock_adjustments` is true, immediately approve the batch.

The create flow must not directly insert `stock_movements` unless auto-approval is enabled through the same approval path. It must not update `stock_levels` directly.

### Approve batch

Approval runs as one PowerSync transaction:

1. Read pending `stock_adjustments` rows by `bundle_id`.
2. Validate each row still has `status = pending`.
3. Validate each row would not produce final negative stock.
4. Insert matching `stock_movements` rows.
5. Mark adjustment rows `approved`, setting `approved_by` and `approved_at`.
6. Supabase trigger updates remote `stock_levels` from the inserted `stock_movements`.
7. PowerSync syncs the updated `stock_levels` back locally.

### Reject batch

Pending batches can be rejected:

1. Set `status = rejected`.
2. Set `rejected_by`, `rejected_at`, and optional `rejection_reason`.
3. Do not create stock movements.
4. Do not mutate stock levels.

### Delete batch

Pending batches can be deleted entirely.

Rules:

- Only pending batches can be deleted.
- Approved/rejected batches remain as audit history.

### Edit batch

Pending batches can be edited before approval.

Allowed edits:

- Change item quantity.
- Remove an item from the batch.
- Optionally add more products to the same batch, if implementation complexity remains reasonable.

Rules:

- Only pending batches can be edited.
- Approved/rejected batches are read-only.
- Editing recalculates Current/New stock in the UI immediately.

## Quantity validation

Stock adjustments may be positive or negative.

Validation rules:

- If current stock is zero, negative adjustment is blocked.
- Block any adjustment where `currentStock + quantityChange < 0`.
- This prevents final negative stock while still allowing legitimate reductions.

Examples:

- Current `10`, change `-3` → allowed, new `7`.
- Current `3`, change `-5` → blocked, new would be `-2`.
- Current `0`, change `-1` → blocked.
- Current `0`, change `5` → allowed, new `5`.

## UI design

### Receive Stock / Create Adjustment

- Desktop keeps two-panel layout: product selection on the left, batch review on the right.
- Mobile keeps tabbed layout: Select Items and Review & Adjust.
- AppBar overflow menu includes an org-wide toggle:
  - `Auto-approve adjustments`
  - Off by default.
  - Changing it updates `organisations.auto_approve_stock_adjustments`.

### Current vs New stock

Selected item rows show:

- `Current`: current `stock_levels.quantity` for selected branch/product.
- `New`: `current + quantityChange`.

If exactly one branch is selected, show the numeric values.

If multiple branches are selected, show a hint instead of one stock number, such as:

- `Multiple branches selected`

### Stock Adjustments list

Add a screen that groups rows by `bundle_id` and shows:

- Created date/time
- Status
- Branch
- Created by
- Item count
- Net quantity change
- Reference/reason

### Adjustment detail

Shows all items in a batch:

- Product name/SKU
- Quantity change
- Current stock
- New stock if approved
- Reason/reference
- Status metadata

Pending actions:

- Approve
- Reject
- Delete
- Edit

Approved/rejected batches are read-only.

## Data access pattern

Use Paps' existing feature-scoped repository/provider style.

Recommended additions:

- Extend `StockRepository` with stock adjustment methods.
- Keep `StockAdjustmentController` or replace it with repository-backed methods.
- Avoid a central `repository.dart` unless a larger architecture refactor is requested later.

Widgets should call providers/controllers, not PowerSync directly.

## Error handling

- Show a validation message for empty batches.
- Show a validation message if no branch is selected.
- Show a validation message if reason/reference is required and missing.
- Show a validation message if a negative adjustment would make stock negative.
- Disable actions for non-pending batches.
- Treat missing local stock as `0` for Current stock display.

## Testing and verification

Implementation should include or update tests where practical:

- Creating a pending batch inserts `stock_adjustments` only.
- Approving a batch inserts `stock_movements` and marks adjustments approved.
- Rejecting/deleting does not create stock movements.
- Editing a pending batch updates quantities and recalculates New stock.
- Negative final stock is blocked.

Run validation after implementation:

- `dart analyze` or `flutter analyze`
- targeted tests if present or added
