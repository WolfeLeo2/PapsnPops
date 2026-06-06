// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedSettingsCategory)
final selectedSettingsCategoryProvider = SelectedSettingsCategoryProvider._();

final class SelectedSettingsCategoryProvider
    extends $NotifierProvider<SelectedSettingsCategory, SettingsCategory> {
  SelectedSettingsCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSettingsCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSettingsCategoryHash();

  @$internal
  @override
  SelectedSettingsCategory create() => SelectedSettingsCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsCategory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsCategory>(value),
    );
  }
}

String _$selectedSettingsCategoryHash() =>
    r'22d8b830288af03172038f80bf40a44a3433a490';

abstract class _$SelectedSettingsCategory extends $Notifier<SettingsCategory> {
  SettingsCategory build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SettingsCategory, SettingsCategory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettingsCategory, SettingsCategory>,
              SettingsCategory,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
