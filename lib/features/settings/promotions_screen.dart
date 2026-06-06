import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'settings_data_provider.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncPromotions = ref.watch(allPromotionsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Promotion',
            onPressed: () {
              context.go('/settings/promotions/add');
            },
          ),
        ],
      ),
      body: asyncPromotions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (promotions) {
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
                title: const Text('All Promotions'),
                tiles: promotions.isEmpty
                    ? [
                        SettingsTile(
                          title: const Text('No promotions available'),
                        )
                      ]
                    : promotions.map((promo) {
                        return SettingsTile.navigation(
                          leading: const PhosphorIcon(PhosphorIconsRegular.tag),
                          title: Text(promo['name'] as String),
                          value: Text('${promo['discount_percentage']}% off'),
                          trailing: Switch(
                            value: promo['is_active'] == 1,
                            onChanged: (val) {
                              // Toggle active state
                            },
                          ),
                          onPressed: (context) {
                            // Edit promotion
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
