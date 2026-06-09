import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../auth/auth_provider.dart';
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
          final activeOwners = users.where((u) => u['role'] == 'owner' && (u['is_active'] == 1 || u['is_active'] == null)).toList();
          final activeCashiers = users.where((u) => u['role'] == 'cashier' && (u['is_active'] == 1 || u['is_active'] == null)).toList();
          final inactiveUsers = users.where((u) => u['is_active'] == 0).toList();

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
              if (activeOwners.isNotEmpty)
                SettingsSection(
                  title: const Text('Owners'),
                  tiles: activeOwners.map((user) {
                    return SettingsTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.shieldCheck),
                      title: Text(user['full_name'] as String),
                      value: const Text('Owner'),
                      trailing: PopupMenuButton<String>(
                        icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditUserDialog(context, ref, user['id'] as String, user['full_name'] as String);
                          } else if (value == 'deactivate') {
                            await ref.read(authProvider.notifier).updateUserStatus(user['id'] as String, false);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Name')),
                          const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (activeCashiers.isNotEmpty)
                SettingsSection(
                  title: const Text('Cashiers'),
                  tiles: activeCashiers.map((user) {
                    return SettingsTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.user),
                      title: Text(user['full_name'] as String),
                      value: const Text('Cashier'),
                      trailing: PopupMenuButton<String>(
                        icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditUserDialog(context, ref, user['id'] as String, user['full_name'] as String);
                          } else if (value == 'deactivate') {
                            await ref.read(authProvider.notifier).updateUserStatus(user['id'] as String, false);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Name')),
                          const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (inactiveUsers.isNotEmpty)
                SettingsSection(
                  title: const Text('Inactive Users'),
                  tiles: inactiveUsers.map((user) {
                    return SettingsTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.userMinus),
                      title: Text(user['full_name'] as String),
                      value: Text(user['role'] == 'owner' ? 'Owner' : 'Cashier'),
                      trailing: PopupMenuButton<String>(
                        icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
                        onSelected: (value) async {
                          if (value == 'reactivate') {
                            await ref.read(authProvider.notifier).updateUserStatus(user['id'] as String, true);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (activeOwners.isEmpty && activeCashiers.isEmpty && inactiveUsers.isEmpty)
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

  void _showEditUserDialog(BuildContext context, WidgetRef ref, String id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User Name'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = ctrl.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  await ref.read(authProvider.notifier).updateUserName(id, newName);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
