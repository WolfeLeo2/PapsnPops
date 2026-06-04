// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tabs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openTabs)
final openTabsProvider = OpenTabsProvider._();

final class OpenTabsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OpenTab>>,
          List<OpenTab>,
          Stream<List<OpenTab>>
        >
    with $FutureModifier<List<OpenTab>>, $StreamProvider<List<OpenTab>> {
  OpenTabsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openTabsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openTabsHash();

  @$internal
  @override
  $StreamProviderElement<List<OpenTab>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OpenTab>> create(Ref ref) {
    return openTabs(ref);
  }
}

String _$openTabsHash() => r'618336c86289fb0d07744ae35ebd6392f4b58c21';

@ProviderFor(tabItems)
final tabItemsProvider = TabItemsFamily._();

final class TabItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TabItem>>,
          List<TabItem>,
          Stream<List<TabItem>>
        >
    with $FutureModifier<List<TabItem>>, $StreamProvider<List<TabItem>> {
  TabItemsProvider._({
    required TabItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tabItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tabItemsHash();

  @override
  String toString() {
    return r'tabItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TabItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TabItem>> create(Ref ref) {
    final argument = this.argument as String;
    return tabItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TabItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tabItemsHash() => r'ad8914b1ed346a836bbc9bd74fe029f9f04d43fe';

final class TabItemsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TabItem>>, String> {
  TabItemsFamily._()
    : super(
        retry: null,
        name: r'tabItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TabItemsProvider call(String tabId) =>
      TabItemsProvider._(argument: tabId, from: this);

  @override
  String toString() => r'tabItemsProvider';
}

@ProviderFor(tabTotal)
final tabTotalProvider = TabTotalFamily._();

final class TabTotalProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  TabTotalProvider._({
    required TabTotalFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tabTotalProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tabTotalHash();

  @override
  String toString() {
    return r'tabTotalProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return tabTotal(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TabTotalProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tabTotalHash() => r'ccf2f65d71d9bd61ef33930f8c474d427a971c27';

final class TabTotalFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  TabTotalFamily._()
    : super(
        retry: null,
        name: r'tabTotalProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TabTotalProvider call(String tabId) =>
      TabTotalProvider._(argument: tabId, from: this);

  @override
  String toString() => r'tabTotalProvider';
}

@ProviderFor(tabsSummary)
final tabsSummaryProvider = TabsSummaryProvider._();

final class TabsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          Stream<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $StreamProvider<Map<String, dynamic>> {
  TabsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tabsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tabsSummaryHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>> create(Ref ref) {
    return tabsSummary(ref);
  }
}

String _$tabsSummaryHash() => r'3377ab133018940badfa64abf5b7c037c8557cdd';

@ProviderFor(SelectedTab)
final selectedTabProvider = SelectedTabProvider._();

final class SelectedTabProvider
    extends $NotifierProvider<SelectedTab, OpenTab?> {
  SelectedTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTabHash();

  @$internal
  @override
  SelectedTab create() => SelectedTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenTab? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenTab?>(value),
    );
  }
}

String _$selectedTabHash() => r'a8c260f4e78de784f9e6e0cbcce57f04101100a7';

abstract class _$SelectedTab extends $Notifier<OpenTab?> {
  OpenTab? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OpenTab?, OpenTab?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OpenTab?, OpenTab?>,
              OpenTab?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
