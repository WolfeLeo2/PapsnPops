import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

enum SettingsCategory {
  business('Business Settings', '/settings/business'),
  branches('Branches', '/settings/branches'),
  users('User Accounts', '/settings/users'),
  staff('Staff Members', '/settings/staff'),
  promotions('Promotions', '/settings/promotions');

  const SettingsCategory(this.label, this.route);
  final String label;
  final String route;
}

@riverpod
class SelectedSettingsCategory extends _$SelectedSettingsCategory {
  @override
  SettingsCategory build() => SettingsCategory.business;

  void select(SettingsCategory category) {
    state = category;
  }
}
