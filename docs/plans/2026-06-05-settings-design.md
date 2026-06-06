# Settings Screen Design

## Architecture & Navigation
- **Package**: `settings_ui` for building modern, native-feeling settings lists.
- **Master-Detail Adaptive Layout**:
  - A single `SettingsScreen` wrapper using `LayoutBuilder`.
  - **Mobile (`< 600px`)**: Renders a clean `SettingsList`. Tapping a category pushes a new route via `go_router` (e.g. `/settings/business`).
  - **Desktop (`>= 600px`)**: Renders a split-pane `Row`. The left side is a fixed-width `SizedBox` for the `SettingsList`. The right side is an `Expanded` container that dynamically renders the form for the selected category using a Riverpod state provider. This prevents unnecessary page pushes and gives an instant, premium desktop feel.

## Category Pages & Data Flow
Each settings category will be a standalone widget that can be rendered either as a full page (mobile) or inside the right pane (desktop):
1. **Business Settings**: Global configuration. Contains fields for Business Name, Registration/PIN, and an Appearance section (Theme mode toggle).
2. **Branch Settings**: A list of all branches. Allows the owner to add new branches or edit existing ones. Writes to the `branches` table via PowerSync.
3. **Staff Settings**: Manages the non-login salespeople (waiters, floor staff) for the active branch. Writes to the `staff` table.
4. **Promotions Settings**: Manages the local promotion rules (happy hour times, percentages, active status). Writes to the `promotions` table.
5. **User Accounts**: Manages actual app logins (Owners/Cashiers). This is the only screen that calls the `create-user` Edge Function to register new authentication users and insert into `user_profiles`.

## Aesthetics & Theming
- The `settings_ui` package will be themed to map directly to our `AppTheme`.
- We will use `SettingsThemeData` to inject the custom dark/light surface container colors from `AppColors`, ensuring the settings screens feel like a cohesive part of PAPs n POPs, not a generic plugin overlay.
