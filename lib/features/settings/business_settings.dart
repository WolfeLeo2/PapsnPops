import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../app.dart';

class BusinessSettings extends ConsumerWidget {
  const BusinessSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
      ),
      body: SettingsList(
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
            title: const Text('Profile'),
            tiles: [
              SettingsTile.navigation(
                leading: const PhosphorIcon(PhosphorIconsRegular.storefront),
                title: const Text('Business Name'),
                value: const Text('PAPs n POPs'),
                onPressed: (context) {
                  // Show edit dialog
                },
              ),
              SettingsTile.navigation(
                leading: const PhosphorIcon(PhosphorIconsRegular.receipt),
                title: const Text('KRA PIN'),
                value: const Text('P000000000A'),
                onPressed: (context) {
                  // Show edit dialog
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
