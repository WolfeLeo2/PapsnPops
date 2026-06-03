# AGENTS.md — PAPs n POPs ERP/POS

This file is the primary context document for AI coding agents (GitHub Copilot, Claude Code, etc.) working on this codebase. Read it fully before writing or modifying any code.

---

## Project overview

PAPs n POPs is a custom ERP/POS system for a Kenyan liquor store with bar operations. It runs as a **Flutter Windows desktop app** (primary till interface) and a **Flutter mobile app** (owner monitoring — same codebase, responsive layout). There is no separate backend server and no Edge Functions. All logic runs client-side in Flutter. Data is persisted remotely in **Supabase** (PostgreSQL + Auth) and locally in **PowerSync** (SQLite). Everything syncs automatically — no selective sync, no manual refresh logic.

---

## Tech stack

| Layer | Technology |
|---|---|
| UI | Flutter (Windows + Android/iOS) |
| Local DB | SQLite via PowerSync |
| Remote DB | Supabase PostgreSQL |
| Auth | Supabase Auth |
| Offline sync | PowerSync (syncs everything, automatically) |
| PDF generation | `pdf` + `printing` packages (client-side) |
| Share sheet | `share_plus` |
| Icons | `phosphor_flutter` |
| State management | Riverpod |
| Navigation | go_router |
| Charts | `fl_chart` |
| Secure storage | `flutter_secure_storage` |

---

## Repository structure

```
lib/
├── main.dart
├── app.dart                        # GoRouter setup, theme, ProviderScope
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # ThemeData, ColorScheme, TextTheme
│   │   ├── app_colors.dart         # Color constants
│   │   └── app_text_styles.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── extensions/                 # Dart extensions (DateTime, String, num)
│   └── utils/
│       ├── currency.dart           # KES formatting: CurrencyHelper.format(int)
│       ├── date_helpers.dart
│       └── promotion_engine.dart   # Client-side promotion calculation logic
├── data/
│   ├── supabase/
│   │   └── supabase_client.dart    # Singleton Supabase client init
│   ├── powersync/
│   │   ├── powersync_client.dart   # PowerSync database init
│   │   └── schema.dart             # PowerSync table schema definitions
│   └── repositories/
│       ├── auth_repository.dart
│       ├── branch_repository.dart
│       ├── product_repository.dart
│       ├── sale_repository.dart
│       ├── tab_repository.dart
│       ├── stock_repository.dart
│       ├── promotion_repository.dart
│       ├── report_repository.dart
│       ├── invoice_repository.dart
│       └── reconciliation_repository.dart
├── domain/
│   └── models/
│       ├── branch.dart
│       ├── product.dart
│       ├── sale.dart
│       ├── sale_item.dart
│       ├── open_tab.dart
│       ├── tab_item.dart
│       ├── stock_level.dart
│       ├── stock_movement.dart
│       ├── promotion.dart
│       ├── applied_promotion.dart  # Result of client-side promotion calculation
│       ├── invoice.dart
│       ├── customer.dart
│       ├── staff_member.dart
│       └── user_profile.dart
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── auth_provider.dart
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   └── dashboard_provider.dart
│   ├── pos/
│   │   ├── pos_screen.dart
│   │   ├── pos_provider.dart       # Cart state, product search, promotion calc
│   │   └── widgets/
│   │       ├── product_grid.dart
│   │       ├── product_card.dart
│   │       ├── cart_panel.dart
│   │       ├── cart_item_row.dart
│   │       ├── payment_method_selector.dart
│   │       ├── invoice_sheet.dart  # Bottom sheet for B2B invoice
│   │       └── receipt_screen.dart
│   ├── tabs/
│   │   ├── tabs_screen.dart
│   │   ├── tabs_provider.dart
│   │   └── widgets/
│   │       ├── tab_list.dart
│   │       ├── tab_detail_panel.dart
│   │       └── tab_item_row.dart
│   ├── stock/
│   │   ├── products_screen.dart
│   │   ├── receive_stock_screen.dart
│   │   ├── stock_provider.dart
│   │   └── widgets/
│   │       ├── product_form.dart
│   │       └── stock_level_row.dart
│   ├── sales_history/
│   │   ├── sales_history_screen.dart
│   │   ├── sales_history_provider.dart
│   │   └── sale_detail_screen.dart
│   ├── reports/
│   │   ├── reports_screen.dart
│   │   ├── reports_provider.dart   # Queries local SQLite, computes all reports
│   │   └── widgets/
│   │       ├── sales_summary_tab.dart
│   │       ├── cashier_report_tab.dart
│   │       ├── products_report_tab.dart
│   │       ├── reconciliation_tab.dart
│   │       ├── stock_levels_tab.dart
│   │       └── revenue_bar_chart.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── business_settings.dart
│       ├── branch_settings.dart
│       ├── user_accounts_screen.dart
│       ├── staff_settings.dart
│       └── promotions_screen.dart
├── shared/
│   └── widgets/
│       ├── app_scaffold.dart       # Sidebar + content wrapper, handles responsive
│       ├── sidebar.dart
│       ├── branch_switcher.dart
│       ├── qty_stepper.dart        # Custom +/− quantity control
│       ├── stat_card.dart
│       ├── section_label.dart
│       ├── connectivity_dot.dart   # Sidebar footer sync indicator
│       └── empty_state.dart
supabase/
├── functions/
│   └── create-user/
│       └── index.ts
├── migrations/
│   └── 001_initial_schema.sql
└── seed/
    └── seed.sql
```

---

## Design system

### Fonts

- **Headings** (`displayLarge` → `headlineSmall`): `Space Grotesk` — modern, geometric, premium feel
- **Body & labels** (`titleLarge` → `labelSmall`): `DM Sans` — clean, highly readable at small sizes, ideal for data-dense POS screens

```dart
// core/theme/app_theme.dart
final _headingFont = GoogleFonts.bricolageGrotesqueTextTheme();
final _bodyFont    = GoogleFonts.googleSansFlexTextTheme();
```

Never define explicit font sizes. Flutter's `TextTheme` scales correctly with the OS accessibility settings. Always reference text styles by semantic name:

```dart
// ✅ Correct
Text('Revenue', style: Theme.of(context).textTheme.labelMedium)
Text('KES 48,240', style: Theme.of(context).textTheme.headlineSmall)

// ❌ Wrong
Text('Revenue', style: TextStyle(fontSize: 11))
```

### TextTheme semantic names (Material 3)

| Style | Usage |
|---|---|
| `displayLarge/Medium/Small` | Hero numbers (e.g. large revenue figure on dashboard) |
| `headlineLarge/Medium/Small` | Page titles, section headings |
| `titleLarge/Medium/Small` | Card titles, screen sub-headings |
| `bodyLarge/Medium` | Body copy, descriptions |
| `bodySmall` | Secondary descriptions, helper text |
| `labelLarge` | Buttons, prominent labels |
| `labelMedium` | Table headers, badges, chips |
| `labelSmall` | Timestamps, captions, micro labels |

### ColorScheme

Both themes share the same accent and status colours. Only surface/background/text colours change between light and dark.

```dart
// core/theme/app_colors.dart

// ── Brand (same in both themes) ────────────────────────
static const accent           = Color(0xFFC85A0A);
static const accentLight      = Color(0xFFFEF0E6);
static const accentDark       = Color(0xFF9E4508);

// ── Status (same in both themes) ───────────────────────
static const error            = Color(0xFFCC1F35);
static const errorContainer   = Color(0xFFFEE8EB);
static const warning          = Color(0xFFB45309);
static const warningContainer = Color(0xFFFEF3C7);
static const success          = Color(0xFF166534);
static const successContainer = Color(0xFFDCFCE7);
static const info             = Color(0xFF1D4ED8);
static const infoContainer    = Color(0xFFEFF6FF);

// ── Light theme surfaces ────────────────────────────────
static const lightSurface              = Color(0xFFFFFFFF);
static const lightSurfaceContainer     = Color(0xFFF0F4F8); // cards
static const lightSurfaceContainerHigh = Color(0xFFE4EAF0); // elevated cards
static const lightOnSurface            = Color(0xFF0D1B2A); // primary text
static const lightOnSurfaceVariant     = Color(0xFF4A6080); // secondary text
static const lightOutline              = Color(0xFFD0DFF0); // borders

// ── Dark theme surfaces ─────────────────────────────────
static const darkSurface              = Color(0xFF0D1B2A);
static const darkSurfaceContainer     = Color(0xFF162236); // cards
static const darkSurfaceContainerHigh = Color(0xFF1E2F45); // elevated cards
static const darkOnSurface            = Color(0xFFF0F4F8); // primary text
static const darkOnSurfaceVariant     = Color(0xFF8DA4BF); // secondary text
static const darkOutline              = Color(0xFF1E3A5A); // borders
```

```dart
// core/theme/app_theme.dart

static ThemeData light() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary:                AppColors.accent,
    onPrimary:              Colors.white,
    primaryContainer:       AppColors.accentLight,
    onPrimaryContainer:     AppColors.accentDark,
    error:                  AppColors.error,
    onError:                Colors.white,
    errorContainer:         AppColors.errorContainer,
    surface:                AppColors.lightSurface,
    onSurface:              AppColors.lightOnSurface,
    onSurfaceVariant:       AppColors.lightOnSurfaceVariant,
    surfaceContainer:       AppColors.lightSurfaceContainer,
    surfaceContainerHigh:   AppColors.lightSurfaceContainerHigh,
    outline:                AppColors.lightOutline,
  ),
  textTheme: GoogleFonts.bricolageGrotesqueTextTheme()
    .copyWith(
      // Override body/label styles to use googleSansFlex
      bodyLarge:   GoogleFonts.googleSansFlex(),
      bodyMedium:  GoogleFonts.googleSansFlex(),
      bodySmall:   GoogleFonts.googleSansFlex(),
      labelLarge:  GoogleFonts.googleSansFlex(),
      labelMedium: GoogleFonts.googleSansFlex(),
      labelSmall:  GoogleFonts.googleSansFlex(),
    ),
);

static ThemeData dark() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary:                AppColors.accent,
    onPrimary:              Colors.white,
    primaryContainer:       AppColors.accentLight,
    onPrimaryContainer:     AppColors.accentDark,
    error:                  AppColors.error,
    onError:                Colors.white,
    errorContainer:         AppColors.errorContainer,
    surface:                AppColors.darkSurface,
    onSurface:              AppColors.darkOnSurface,
    onSurfaceVariant:       AppColors.darkOnSurfaceVariant,
    surfaceContainer:       AppColors.darkSurfaceContainer,
    surfaceContainerHigh:   AppColors.darkSurfaceContainerHigh,
    outline:                AppColors.darkOutline,
  ),
  textTheme: GoogleFonts.bricolageGrotesqueTextTheme(ThemeData.dark().textTheme)
    .copyWith(
      bodyLarge:   GoogleFonts.googleSansFlex(color: AppColors.darkOnSurface),
      bodyMedium:  GoogleFonts.googleSansFlex(color: AppColors.darkOnSurface),
      bodySmall:   GoogleFonts.googleSansFlex(color: AppColors.darkOnSurfaceVariant),
      labelLarge:  GoogleFonts.googleSansFlex(color: AppColors.darkOnSurface),
      labelMedium: GoogleFonts.googleSansFlex(color: AppColors.darkOnSurfaceVariant),
      labelSmall:  GoogleFonts.googleSansFlex(color: AppColors.darkOnSurfaceVariant),
    ),
);
```

### Theme usage in widgets

```dart
// Always use theme tokens — never hardcode colours or sizes
final cs = Theme.of(context).colorScheme;
final tt = Theme.of(context).textTheme;

Container(
  color: cs.surfaceContainer,       // card background
  child: Text(
    'KES 48,240',
    style: tt.headlineSmall?.copyWith(color: cs.primary),
  ),
)
```

### Theme mode

Default to `ThemeMode.system` — respects the OS setting. Owner can override in Settings → Business → Appearance.

```dart
// In app.dart
MaterialApp.router(
  themeMode: ref.watch(themeModeProvider), // default: ThemeMode.system
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
)
```

### Icon set
- Package: `phosphor_flutter`
- Default: `PhosphorIconsRegular`
- Active / selected: `PhosphorIconsFill`
- Never mix with other icon sets

### Widget philosophy
- **Use native Flutter widgets** themed via `ThemeData` — do not reinvent `DropdownButton`, `FilterChip`, `NavigationRail`, `Drawer`, `BottomSheet`, `Chip`, `TextFormField`, `AlertDialog`
- **Create custom widgets** only when Flutter has no equivalent: `ProductCard`, `QtyStepper`, `BranchSwitcher`, `StatCard`, `ConnectivityDot`, `TabListItem`
- Custom widgets: `shared/widgets/` for global ones, `features/X/widgets/` for feature-specific
- **NEVER USE CIRCLEPROGRESSINDICATOR FOR LOADING STATES FOR PAGES. USE SHIMMER SKELETON FROM shimmer package**

### Responsive layout
- **Windows desktop**: persistent `NavigationRail`. 188px expanded, 64px collapsed (icons only). Toggle on leading AppBar icon.
  - Branch Switcher adapts: shows dropdown when expanded, shows first letter in a CircleAvatar when collapsed.
  - Connectivity Dot adapts: shows text when expanded, hidden when collapsed.
- **Mobile**: `Scaffold` with `Drawer`. AppBar leading icon opens the drawer.
- Breakpoint: `600px` — use `LayoutBuilder` to switch between layouts
- POS screen on mobile: cart slides up as a bottom sheet rather than a side panel

---

## Packages

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
  shared_preferences:       # theme mode persistence

dev_dependencies:
  riverpod_generator:
  build_runner:
  flutter_lints:
  very_good_analysis:
```

---

## State management
- Providers live alongside their feature: `features/pos/pos_provider.dart`
- `AsyncNotifierProvider` — for data loaded from DB (products, sales, tabs)
- `NotifierProvider` — for pure UI state (cart items, active filters, selected branch)
- **Never call Supabase or PowerSync directly from a widget** — always via repository → provider

---

## Data access pattern

```
Widget → Provider (Riverpod) → Repository → PowerSync local SQLite (reads)
                                           → Supabase client SDK (writes)
```

- **Reads**: always from PowerSync local SQLite — fast, works offline, always up to date
- **Writes**: directly to Supabase — PowerSync syncs the change back to local SQLite automatically
- **Reports**: computed entirely from local SQLite queries inside `report_repository.dart` — no server call
- **PDFs**: generated client-side in Flutter using the `pdf` package — no server call

---

## Offline behaviour

PowerSync syncs **all tables** to local SQLite automatically whenever a row changes in Supabase. Do not write manual sync logic. Do not selectively decide what syncs — everything does.

- All core operations work offline: POS, tabs, stock view, reports, PDF generation
- Writes made offline are queued by PowerSync and uploaded when connectivity returns
- Show `ConnectivityDot` in sidebar footer: green = synced, amber = syncing, grey = offline
- Never show a loading spinner or block the UI waiting for network

---

## Route guards & privilege model

Role is read from JWT metadata on login and stored in a global `authProvider`. Never re-fetched unless the session changes.

### Owner-only routes (redirect cashier to `/pos`)

```dart
// go_router redirect — applied to all owner-only routes
redirect: (context, state) {
  final role = ref.read(authProvider).role;
  if (role != 'owner') return '/pos';
  return null;
},
```

Apply this guard to:
- `/reports`
- `/settings` and all sub-routes (`/settings/branches`, `/settings/users`, `/settings/staff`, `/settings/promotions`)

### Owner-only actions within shared screens

Do not render these for cashiers — check role in the widget:

```dart
if (ref.watch(authProvider).isOwner) ...[
  VoidSaleButton(),
]
```

| Screen | Hidden from cashier |
|---|---|
| Sales history | Void sale button |
| Stock screen | Stock adjustment (breakage/write-off) |
| Sidebar | Branch switcher (show static label instead) |

### Sale voiding flow

1. Owner taps "Void sale" on a completed sale
2. Confirmation dialog shown
3. On confirm: write `sales.is_voided = true` + `voided_by` + `voided_at` to Supabase
4. Write reversal `stock_movements` (type: `void`, positive qty) for each sale item
5. PowerSync syncs changes — stock levels update on all devices automatically
6. Sale remains in DB permanently — never deleted

---

## Edge Functions

There is exactly **one** Edge Function in this project: `create-user`.

It exists because `supabase.auth.admin.createUser()` requires the service role key, which cannot live in the Flutter client.

```
POST /functions/v1/create-user
Body: {
  email: string,
  password: string,
  full_name: string,
  role: 'cashier',
  organisation_id: string,
  branch_ids: string[]
}
```

The function:
1. Validates the caller's JWT — must have `role: 'owner'` in metadata
2. Calls `admin.createUser()` with credentials
3. Sets `raw_user_meta_data` on the new user
4. Inserts into `user_profiles`
5. Inserts into `user_branch_access` for each branch

Do not add any other Edge Functions without strong justification. The current architecture needs none.

---

## User metadata

Every auth user has the following shape in `raw_user_meta_data`, set by `create-user`:

```json
{
  "role": "cashier",
  "full_name": "Brian Odhiambo",
  "organisation_id": "uuid-here",
  "branch_ids": ["uuid-branch-1"]
}
```

Owner has all branch IDs in `branch_ids`. Cashier has only their assigned branch.

**Why this matters:**
- **PowerSync** reads `user_metadata` from the JWT to determine which branches to sync — no DB lookup needed
- **RLS policies** reference `auth.jwt()->'user_metadata'` directly — fast, join-free
- **Flutter** reads `role` from metadata on login to decide owner vs cashier layout

RLS policy pattern using metadata:
```sql
CREATE POLICY "branch_access" ON sales
  FOR ALL USING (
    branch_id = ANY(
      ARRAY(
        SELECT jsonb_array_elements_text(
          auth.jwt()->'user_metadata'->'branch_ids'
        )::uuid
      )
    )
  );
```

---

## Auth & roles

Supabase Auth manages sessions. Role stored in `user_profiles.role`.

| Role | Access |
|---|---|
| `owner` | All branches, all features, settings |
| `cashier` | Assigned branch only — POS, tabs, stock view |

- RLS enforces this at DB level — never rely solely on client-side role checks
- Owner gets `BranchSwitcher` in sidebar — sets `currentBranchId` in a global Riverpod provider
- Cashier gets a static branch label — no switcher rendered
- `staff` records are not auth users — they are names in a dropdown on sales/invoices

---

## Promotion engine

Promotions are calculated **entirely client-side** in `core/utils/promotion_engine.dart`.

```dart
// Input: current cart items + current DateTime + synced promotions from local SQLite
// Output: list of AppliedPromotion (which promotion, which items, discount amount)
List<AppliedPromotion> calculatePromotions({
  required List<CartItem> items,
  required List<Promotion> activePromotions,
  required DateTime now,
})
```

- Filter promotions by `is_active`, `valid_from`, `valid_until`
- For happy hour: check `now` against `happy_hour_start`/`happy_hour_end` and `active_days`
- Apply all matching promotions — multiple can stack
- Result is shown inline on the cart and recorded in `sales.promotion_ids` and `sale_items.discount_amount`

---

## PDF generation

All PDFs (receipts, invoices, report exports) are generated client-side using the `pdf` package.

```dart
// After generating:
await Printing.sharePdf(bytes: pdfBytes, filename: 'receipt.pdf');
// This opens the native OS print/share dialog — handles print, download, WhatsApp, email
```

- Never store PDFs in Supabase Storage
- Never call a server to generate PDFs
- `invoice_repository.dart` handles building the PDF layout for invoices
- Receipt layout is simpler — lives in `receipt_screen.dart`

---

## PowerSync sync rules

```yaml
# sync-rules.yaml — syncs everything for the user's accessible branches
bucket_definitions:
  branch_data:
    parameters:
      - name: branch_id
        expression: user_metadata->>'branch_id'
    data:
      - SELECT * FROM products
      - SELECT * FROM stock_levels WHERE branch_id = bucket.branch_id
      - SELECT * FROM stock_movements WHERE branch_id = bucket.branch_id
      - SELECT * FROM sales WHERE branch_id = bucket.branch_id
      - SELECT * FROM sale_items WHERE sale_id IN (SELECT id FROM sales WHERE branch_id = bucket.branch_id)
      - SELECT * FROM open_tabs WHERE branch_id = bucket.branch_id
      - SELECT * FROM tab_items WHERE tab_id IN (SELECT id FROM open_tabs WHERE branch_id = bucket.branch_id)
      - SELECT * FROM promotions
      - SELECT * FROM staff WHERE branch_id = bucket.branch_id
      - SELECT * FROM customers
      - SELECT * FROM invoices WHERE branch_id = bucket.branch_id
      - SELECT * FROM cash_reconciliations WHERE branch_id = bucket.branch_id
      - SELECT * FROM branches
      - SELECT * FROM user_profiles
```

Owner iterates all branch IDs — gets full sync across all branches.

---

## Database Migrations

- **Migration Files**: Any SQL migrations (schema changes, new tables, RLS policy updates, function changes) MUST be added as sequential `.sql` files inside the `supabase/migrations/` folder.
- **Why**: This ensures a clear, version-controlled audit trail of all database changes and allows easy rebuilds of the Supabase environment. Never apply structural changes directly via the Supabase dashboard without also committing the corresponding SQL migration file.

---

## Security

- **RLS on every table** — before using any table, it must have RLS enabled with correct policies
- **Never use the service role key in Flutter** — only `anonKey`
- **Money is always integers** — KES stored as `int` (× 100). Never `double`.
- **No hardcoded IDs** — branch IDs, user IDs, org IDs always come from auth context or provider state
- **Auth tokens** in `flutter_secure_storage` — never `SharedPreferences`
- **Input validation** on both client (Flutter form validators) and DB (CHECK constraints, NOT NULL)
- **Audit trail** — `stock_movements` records every stock change with `user_id` + `created_at`. Voided sales retain their record with `voided_by` + `voided_at`.

---

## Key flows

### POS sale
1. Cashier searches/taps products → added to cart (local `NotifierProvider` state)
2. `promotion_engine.dart` recalculates discounts on every cart change
3. Cashier selects salesperson + payment method
4. Tap "Charge" → write `sale` + `sale_items` to Supabase
5. DB trigger decrements `stock_levels`
6. PowerSync syncs stock change back to local SQLite
7. Receipt screen shown — PDF generated client-side, share sheet opened

### Tab open/add/close
1. "Save tab" → write `open_tabs` + initial `tab_items` to Supabase
2. "Add items" → append new `tab_items` (timestamp = `created_at`)
3. "Close tab" → write `sale` + `sale_items`, set `open_tabs.is_open = false` in a single Supabase RPC call or sequential writes
4. DB trigger decrements stock via `sale_items` insert
5. Receipt screen shown

### Invoice (B2B)
1. POS `···` → "Save as invoice" → bottom sheet
2. Fill customer details → write `customer` (or match by phone) + `sale` + `sale_items` + `invoice` to Supabase
3. PDF generated client-side
4. Native share sheet opens — WhatsApp, email, download

### Stock receive
1. "Receive stock" → select product, enter qty + cost price
2. Write `stock_movement` (type: `receive`) to Supabase
3. DB trigger increments `stock_levels.quantity`
4. PowerSync syncs new stock level to local SQLite instantly

### Reports
1. Owner opens Reports screen, selects date range + branch
2. `report_repository.dart` runs SQL queries against local PowerSync SQLite
3. Results returned synchronously — no loading state, no network call
4. Charts rendered by `fl_chart`
5. Export: PDF generated client-side via `pdf` package, shared via `share_plus`

---

## Settings structure

Settings screen is owner-only and organised into sections:

| Section | Contents |
|---|---|
| Business | Organisation name, receipt header/footer |
| Branches | Add / edit / deactivate branches |
| Team | User accounts (logins), staff list (salesperson names) |
| Promotions | Add / edit / deactivate promotions |
| Products | Categories, UOM definitions |

---

## Coding conventions

- Dart: follow `flutter_lints` + `very_good_analysis`
- File names: `snake_case.dart` — class names: `PascalCase`
- Currency: always use `CurrencyHelper.format(int amountInCents)` → `"KES 1,200"`
- Dates: `DateFormat('d MMM yyyy')` for display, ISO 8601 for storage
- Never use `print()` — use `debugPrint()` in dev, remove before release
- All repository methods return `Result<T>` or throw typed exceptions — never raw `dynamic`
- No business logic in screen files — screens observe providers, providers call repositories
- Every monetary value is `int` — if you find yourself writing `double` for money, stop

---

## What NOT to do

- Do not call Supabase directly from widgets — always through repository → provider
- Do not write manual sync logic — PowerSync handles it
- Do not selectively decide what is available offline — everything is
- Do not generate PDFs server-side — use the `pdf` + `printing` packages client-side
- Do not validate promotions server-side — calculate in `promotion_engine.dart`
- Do not store auth tokens in `SharedPreferences` — use `flutter_secure_storage`
- Do not use `double` for money — use `int`
- Do not skip RLS on any table
- Do not hardcode any IDs
- Do not call `supabase.auth.admin.createUser()` from Flutter — use the `create-user` Edge Function
- Do not add Edge Functions beyond `create-user` without strong justification — the architecture needs none
