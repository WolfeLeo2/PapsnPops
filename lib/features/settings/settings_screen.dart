import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app.dart';
import 'settings_provider.dart';

import 'branch_settings.dart';
import 'business_settings.dart';
import 'promotions_screen.dart';
import 'staff_settings.dart';
import 'user_accounts_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      context
                          .findRootAncestorStateOfType<ScaffoldState>()
                          ?.openDrawer();
                    },
                  );
                },
              ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!isDesktop) {
            return _buildSettingsMenu(context, ref, isDesktop: false);
          }

          // Desktop Split Pane
          final selectedCategory = ref.watch(selectedSettingsCategoryProvider);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 350,
                child: _buildSettingsMenu(context, ref, isDesktop: true),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Scaffold(
                  body: _buildCategoryContent(selectedCategory),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, WidgetRef ref, {required bool isDesktop}) {
    final selectedCategory = ref.watch(selectedSettingsCategoryProvider);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    return SettingsList(
      lightTheme: SettingsThemeData(
        settingsListBackground: theme.colorScheme.surface,
        settingsSectionBackground: theme.colorScheme.surfaceContainer,
        titleTextColor: theme.colorScheme.primary,
      ),
      darkTheme: SettingsThemeData(
        settingsListBackground: theme.colorScheme.surface,
        settingsSectionBackground: theme.colorScheme.surfaceContainer,
        titleTextColor: theme.colorScheme.primary,
      ),
      sections: [
        SettingsSection(
          title: const Text('Organization'),
          tiles: [
            _buildTile(
              context: context,
              ref: ref,
              isDesktop: isDesktop,
              category: SettingsCategory.business,
              icon: PhosphorIconsRegular.buildings,
              isSelected: selectedCategory == SettingsCategory.business,
            ),
            _buildTile(
              context: context,
              ref: ref,
              isDesktop: isDesktop,
              category: SettingsCategory.branches,
              icon: PhosphorIconsRegular.storefront,
              isSelected: selectedCategory == SettingsCategory.branches,
            ),
          ],
        ),
        SettingsSection(
          title: const Text('Access & Staff'),
          tiles: [
            _buildTile(
              context: context,
              ref: ref,
              isDesktop: isDesktop,
              category: SettingsCategory.users,
              icon: PhosphorIconsRegular.users,
              isSelected: selectedCategory == SettingsCategory.users,
            ),
            _buildTile(
              context: context,
              ref: ref,
              isDesktop: isDesktop,
              category: SettingsCategory.staff,
              icon: PhosphorIconsRegular.identificationBadge,
              isSelected: selectedCategory == SettingsCategory.staff,
            ),
          ],
        ),
        SettingsSection(
          title: const Text('Sales'),
          tiles: [
            _buildTile(
              context: context,
              ref: ref,
              isDesktop: isDesktop,
              category: SettingsCategory.promotions,
              icon: PhosphorIconsRegular.tag,
              isSelected: selectedCategory == SettingsCategory.promotions,
            ),
          ],
        ),
        SettingsSection(
          title: const Text('Appearance'),
          tiles: [
            SettingsTile(
              title: const Text('Theme Mode'),
              leading: const PhosphorIcon(PhosphorIconsRegular.palette),
              trailing: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeMode},
                onSelectionChanged: (set) {
                  ref.read(themeModeProvider.notifier).setMode(set.first);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  SettingsTile _buildTile({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDesktop,
    required SettingsCategory category,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final tileColor = isDesktop && isSelected
        ? theme.colorScheme.primaryContainer
        : Colors.transparent;
    final textColor = isDesktop && isSelected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return SettingsTile.navigation(
      leading: PhosphorIcon(icon, color: textColor),
      title: Text(
        category.label,
        style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
      onPressed: (context) {
        if (isDesktop) {
          ref.read(selectedSettingsCategoryProvider.notifier).select(category);
        } else {
          context.push(category.route);
        }
      },
    );
  }

  Widget _buildCategoryContent(SettingsCategory category) {
    switch (category) {
      case SettingsCategory.business:
        return const BusinessSettings();
      case SettingsCategory.branches:
        return const BranchSettings();
      case SettingsCategory.users:
        return const UserAccountsScreen();
      case SettingsCategory.staff:
        return const StaffSettings();
      case SettingsCategory.promotions:
        return const PromotionsScreen();
    }
  }
}
