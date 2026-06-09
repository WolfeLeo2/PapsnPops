import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/repositories/branch_provider.dart';
import '../../data/repositories/staff_repository.dart';
import 'widgets/add_staff_dialog.dart';
import 'settings_data_provider.dart';

class StaffSettings extends ConsumerWidget {
  const StaffSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncStaff = ref.watch(allStaffStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Staff Member',
            onPressed: () {
              final branchId = ref.read(currentBranchIdProvider);
              if (branchId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a branch first')),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) => AddStaffDialog(branchId: branchId),
              );
            },
          ),
        ],
      ),
      body: asyncStaff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (staffList) {
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
              if (staffList.any((s) => s['is_active'] == 1))
                SettingsSection(
                  title: const Text('Active Staff'),
                  tiles: staffList.where((s) => s['is_active'] == 1).map((staff) {
                    return SettingsTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.user),
                      title: Text(staff['name'] as String),
                      value: Text(staff['role_label'] ?? 'Staff'),
                      trailing: PopupMenuButton<String>(
                        icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditStaffDialog(context, ref, staff['id'] as String, staff['name'] as String);
                          } else if (value == 'deactivate') {
                            await ref.read(staffRepositoryProvider).updateStaffStatus(staff['id'] as String, false);
                          } else if (value == 'delete') {
                            await ref.read(staffRepositoryProvider).deleteStaffMember(staff['id'] as String);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Name')),
                          const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (staffList.any((s) => s['is_active'] == 0))
                SettingsSection(
                  title: const Text('Inactive Staff'),
                  tiles: staffList.where((s) => s['is_active'] == 0).map((staff) {
                    return SettingsTile(
                      leading: const PhosphorIcon(PhosphorIconsRegular.userMinus),
                      title: Text(staff['name'] as String),
                      value: Text(staff['role_label'] ?? 'Staff'),
                      trailing: PopupMenuButton<String>(
                        icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
                        onSelected: (value) async {
                          if (value == 'reactivate') {
                            await ref.read(staffRepositoryProvider).updateStaffStatus(staff['id'] as String, true);
                          } else if (value == 'delete') {
                            await ref.read(staffRepositoryProvider).deleteStaffMember(staff['id'] as String);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (staffList.isEmpty)
                SettingsSection(
                  title: const Text('Staff'),
                  tiles: [
                    SettingsTile(
                      title: const Text('No staff found'),
                    )
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, WidgetRef ref, String id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Staff Name'),
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
                  await ref.read(staffRepositoryProvider).updateStaffName(id, newName);
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
