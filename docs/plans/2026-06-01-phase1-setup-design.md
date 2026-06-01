# Phase 1 Setup Design: Backend First

## Overview
This design covers the execution of Phase 1 for the PAPs n POPs ERP/POS System. We are adopting a bottom-up approach (Backend first, then UI) to ensure the data layer is robust before building out visual components.

## Architecture & Data Flow
1. **Remote Database (Supabase)**: We will apply the `001_initial_schema.sql` migration to the remote Supabase instance (`ugxjqmqiatbsapjmajnw`) using the Supabase MCP. This includes all tables, Row Level Security (RLS) policies, and database triggers for stock decrement/adjustment.
2. **Offline Sync (PowerSync)**: We will configure PowerSync via the `powersync` CLI to sync the Supabase data locally. The `sync-rules.yaml` will be created to ensure all tables sync automatically for the authenticated user's assigned branches.
3. **Local Flutter Client**: 
   - `SupabaseClient` for auth and direct writes.
   - `PowerSyncClient` for local SQLite reads and automatic background uploads of offline writes.

## Components to Build

### 1. Database & Sync
- `supabase/migrations/001_initial_schema.sql`: Contains the exact SQL schema defined in the PRD.
- `powersync.yaml` and `sync-rules.yaml`: For configuring the PowerSync CLI and Cloud instance.
- Supabase MCP `execute_sql` will be used to run the migration remotely.

### 2. Flutter Services Layer
- `data/supabase/supabase_client.dart`: Initializes Supabase.
- `data/powersync/powersync_client.dart`: Initializes local SQLite and syncs with Supabase.
- `data/powersync/schema.dart`: Maps the remote schema to local PowerSync tables.
- `features/auth/auth_provider.dart`: Global Riverpod state that reads the user's JWT metadata (role, branch_ids).

### 3. Flutter UI Layer
- `app.dart`: Setup `MaterialApp.router` with `go_router` and `AppTheme`.
- `features/auth/login_screen.dart`: Simple email/password login.
- `shared/widgets/app_scaffold.dart`: The main layout wrapper containing the universal `Drawer` (permanent on desktop, dismissible on mobile).

## Security & Verification
- No Edge Functions will be created in this phase (the `create-user` function is deferred until user management is built).
- We will verify that login works and that PowerSync successfully downloads the initial schema structure to the local SQLite database.
