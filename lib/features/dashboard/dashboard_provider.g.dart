// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todaySales)
final todaySalesProvider = TodaySalesProvider._();

final class TodaySalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  TodaySalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaySalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaySalesHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return todaySales(ref);
  }
}

String _$todaySalesHash() => r'd956bc57214ebea048eb99fdd239753eb8b5abde';

@ProviderFor(activeReconciliations)
final activeReconciliationsProvider = ActiveReconciliationsProvider._();

final class ActiveReconciliationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  ActiveReconciliationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeReconciliationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeReconciliationsHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return activeReconciliations(ref);
  }
}

String _$activeReconciliationsHash() =>
    r'6ae337daeb0d6a31c3eab06b3341e2afd13c42fa';

@ProviderFor(dashboardMetrics)
final dashboardMetricsProvider = DashboardMetricsProvider._();

final class DashboardMetricsProvider
    extends
        $FunctionalProvider<
          DashboardMetrics,
          DashboardMetrics,
          DashboardMetrics
        >
    with $Provider<DashboardMetrics> {
  DashboardMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardMetricsHash();

  @$internal
  @override
  $ProviderElement<DashboardMetrics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DashboardMetrics create(Ref ref) {
    return dashboardMetrics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardMetrics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardMetrics>(value),
    );
  }
}

String _$dashboardMetricsHash() => r'2af84d0069f9cd56cffd9cd5109eaeca42c7b4ac';

@ProviderFor(recentSales)
final recentSalesProvider = RecentSalesProvider._();

final class RecentSalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecentSale>>,
          List<RecentSale>,
          Stream<List<RecentSale>>
        >
    with $FutureModifier<List<RecentSale>>, $StreamProvider<List<RecentSale>> {
  RecentSalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentSalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSalesHash();

  @$internal
  @override
  $StreamProviderElement<List<RecentSale>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RecentSale>> create(Ref ref) {
    return recentSales(ref);
  }
}

String _$recentSalesHash() => r'a2cc484146144d01581b48125fbefba9fc2dff7d';

@ProviderFor(stockLevels)
final stockLevelsProvider = StockLevelsProvider._();

final class StockLevelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StockLevelItem>>,
          List<StockLevelItem>,
          Stream<List<StockLevelItem>>
        >
    with
        $FutureModifier<List<StockLevelItem>>,
        $StreamProvider<List<StockLevelItem>> {
  StockLevelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockLevelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockLevelsHash();

  @$internal
  @override
  $StreamProviderElement<List<StockLevelItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StockLevelItem>> create(Ref ref) {
    return stockLevels(ref);
  }
}

String _$stockLevelsHash() => r'4900006600fab71b8b0cda4e7b7a8aa1257bbc95';

@ProviderFor(openTabs)
final openTabsProvider = OpenTabsProvider._();

final class OpenTabsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OpenTabItem>>,
          List<OpenTabItem>,
          Stream<List<OpenTabItem>>
        >
    with
        $FutureModifier<List<OpenTabItem>>,
        $StreamProvider<List<OpenTabItem>> {
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
  $StreamProviderElement<List<OpenTabItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<OpenTabItem>> create(Ref ref) {
    return openTabs(ref);
  }
}

String _$openTabsHash() => r'10fc7277dc064a1fa59dd50357adc1cd3fa8bddd';

@ProviderFor(lowStockAlerts)
final lowStockAlertsProvider = LowStockAlertsProvider._();

final class LowStockAlertsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LowStockAlertItem>>,
          List<LowStockAlertItem>,
          Stream<List<LowStockAlertItem>>
        >
    with
        $FutureModifier<List<LowStockAlertItem>>,
        $StreamProvider<List<LowStockAlertItem>> {
  LowStockAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lowStockAlertsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lowStockAlertsHash();

  @$internal
  @override
  $StreamProviderElement<List<LowStockAlertItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LowStockAlertItem>> create(Ref ref) {
    return lowStockAlerts(ref);
  }
}

String _$lowStockAlertsHash() => r'2d3f4e3e315b401d17407015ab9890005053eeed';

@ProviderFor(topProducts)
final topProductsProvider = TopProductsProvider._();

final class TopProductsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TopProductItem>>,
          List<TopProductItem>,
          Stream<List<TopProductItem>>
        >
    with
        $FutureModifier<List<TopProductItem>>,
        $StreamProvider<List<TopProductItem>> {
  TopProductsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'topProductsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$topProductsHash();

  @$internal
  @override
  $StreamProviderElement<List<TopProductItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TopProductItem>> create(Ref ref) {
    return topProducts(ref);
  }
}

String _$topProductsHash() => r'1facbd2114d031fdfd126b3c3f49c8baec222192';
