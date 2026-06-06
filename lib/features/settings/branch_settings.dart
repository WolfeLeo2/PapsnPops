import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/repositories/branch_provider.dart';

class BranchSettings extends ConsumerWidget {
  const BranchSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncBranches = ref.watch(branchesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Branch',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add branch coming soon')),
              );
            },
          ),
        ],
      ),
      body: asyncBranches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (branches) {
          return SettingsList(
            lightTheme: SettingsThemeData(
              settingsListBackground: theme.colorScheme.surface,
              settingsSectionBackground: theme.colorScheme.surfaceContainer,
            ),
            darkTheme: SettingsThemeData(
              settingsListBackground: theme.colorScheme.surface,
              settingsSectionBackground: theme.colorScheme.surfaceContainer,
            ),
            sections: [
              SettingsSection(
                title: const Text('All Branches'),
                tiles: branches.isEmpty
                    ? [
                        SettingsTile(
                          title: const Text('No branches available'),
                        )
                      ]
                    : branches.map((branch) {
                        return SettingsTile.navigation(
                          leading: const PhosphorIcon(PhosphorIconsRegular.storefront),
                          title: Text(branch.name),
                          value: Text(branch.location ?? 'No location'),
                          onPressed: (context) {
                            // Edit branch
                          },
                        );
                      }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
