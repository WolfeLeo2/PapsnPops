import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'widgets/add_user_dialog.dart';
import 'settings_data_provider.dart';

class UserAccountsScreen extends ConsumerWidget {
  const UserAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncUsers = ref.watch(allUsersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add User Account',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddUserDialog(),
              );
            },
          ),
        ],
      ),
      body: asyncUsers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (users) {
          final owners = users.where((u) => u['role'] == 'owner').toList();
          final cashiers = users.where((u) => u['role'] == 'cashier').toList();

          return SettingsList(
            lightTheme: SettingsThemeData(
              settingsListBackground: theme.colorScheme.surface,
              settingsSectionBackground: theme.colorScheme.surfaceContainer,
            ),
            darkTheme: SettingsThemeData(
              settingsListBackground: theme.colorScheme.surface,
              settingsSectionBackground: theme.colorScheme.surfaceContainer,
            ),
            applicationType: ApplicationType.material,
            sections: [
              if (owners.isNotEmpty)
                SettingsSection(
                  title: const Text('Owners'),
                  tiles: owners.map((user) {
                    return SettingsTile.navigation(
                      leading: const PhosphorIcon(PhosphorIconsRegular.shieldCheck),
                      title: Text(user['full_name'] as String),
                      value: const Text('Owner'),
                      onPressed: (context) {
                        // Edit user
                      },
                    );
                  }).toList(),
                ),
              if (cashiers.isNotEmpty)
                SettingsSection(
                  title: const Text('Cashiers'),
                  tiles: cashiers.map((user) {
                    return SettingsTile.navigation(
                      leading: const PhosphorIcon(PhosphorIconsRegular.user),
                      title: Text(user['full_name'] as String),
                      value: const Text('Cashier'),
                      onPressed: (context) {
                        // Edit user
                      },
                    );
                  }).toList(),
                ),
              if (owners.isEmpty && cashiers.isEmpty)
                SettingsSection(
                  title: const Text('Users'),
                  tiles: [
                    SettingsTile(
                      title: const Text('No users found'),
                    )
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
