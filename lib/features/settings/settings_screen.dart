import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app.dart';
import '../auth/auth_provider.dart';
import 'settings_provider.dart';

/* import 'branch_settings.dart'; */
/* import 'promotions_screen.dart'; */
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

    final user = ref.watch(authProvider);
    final isOwner = user?.userMetadata?['role'] == 'owner';

    return ListView(
      children: [
        if (isOwner) ...[
          /*
          _buildSectionHeader(context, 'Organization'),
          _buildTile(
            context: context,
            ref: ref,
            isDesktop: isDesktop,
            category: SettingsCategory.branches,
            icon: PhosphorIconsRegular.storefront,
            isSelected: selectedCategory == SettingsCategory.branches,
          ),
          const Divider(),
          */
          _buildSectionHeader(context, 'Access & Staff'),
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
          /*
          _buildTile(
            context: context,
            ref: ref,
            isDesktop: isDesktop,
            category: SettingsCategory.promotions,
            icon: PhosphorIconsRegular.ticket,
            isSelected: selectedCategory == SettingsCategory.promotions,
          ),
          */
          const Divider(),
        ],
        _buildSectionHeader(context, 'Appearance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PhosphorIcon(PhosphorIconsRegular.palette),
                  const SizedBox(width: 16),
                  Text('Theme Mode', style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
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
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTile({
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

    return Container(
      color: tileColor,
      child: ListTile(
        leading: PhosphorIcon(icon, color: textColor),
        title: Text(
          category.label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isDesktop ? null : const Icon(Icons.chevron_right),
        onTap: () {
          if (isDesktop) {
            ref.read(selectedSettingsCategoryProvider.notifier).select(category);
          } else {
            context.push(category.route);
          }
        },
      ),
    );
  }

  Widget _buildCategoryContent(SettingsCategory category) {
    switch (category) {
      /*
      case SettingsCategory.branches:
        return const BranchSettings();
      */
      case SettingsCategory.users:
        return const UserAccountsScreen();
      case SettingsCategory.staff:
        return const StaffSettings();
      /*
      case SettingsCategory.promotions:
        return const PromotionsScreen();
      */
    }
  }
}
