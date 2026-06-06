// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedReportTab)
final selectedReportTabProvider = SelectedReportTabProvider._();

final class SelectedReportTabProvider
    extends $NotifierProvider<SelectedReportTab, int> {
  SelectedReportTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedReportTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedReportTabHash();

  @$internal
  @override
  SelectedReportTab create() => SelectedReportTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedReportTabHash() => r'da52487febf171aa20095ee713b18a66bf63d488';

abstract class _$SelectedReportTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedReportPeriod)
final selectedReportPeriodProvider = SelectedReportPeriodProvider._();

final class SelectedReportPeriodProvider
    extends $NotifierProvider<SelectedReportPeriod, ReportPeriod> {
  SelectedReportPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedReportPeriodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedReportPeriodHash();

  @$internal
  @override
  SelectedReportPeriod create() => SelectedReportPeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportPeriod>(value),
    );
  }
}

String _$selectedReportPeriodHash() =>
    r'c49395ee4b6077972a2984bac87f86c0666cfcdd';

abstract class _$SelectedReportPeriod extends $Notifier<ReportPeriod> {
  ReportPeriod build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReportPeriod, ReportPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportPeriod, ReportPeriod>,
              ReportPeriod,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CustomReportDateRange)
final customReportDateRangeProvider = CustomReportDateRangeProvider._();

final class CustomReportDateRangeProvider
    extends $NotifierProvider<CustomReportDateRange, ReportDateRange?> {
  CustomReportDateRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customReportDateRangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customReportDateRangeHash();

  @$internal
  @override
  CustomReportDateRange create() => CustomReportDateRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportDateRange? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportDateRange?>(value),
    );
  }
}

String _$customReportDateRangeHash() =>
    r'0ce05b2ae590e6cf58b78715d6114416e94b71e0';

abstract class _$CustomReportDateRange extends $Notifier<ReportDateRange?> {
  ReportDateRange? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReportDateRange?, ReportDateRange?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportDateRange?, ReportDateRange?>,
              ReportDateRange?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(activeDateRange)
final activeDateRangeProvider = ActiveDateRangeProvider._();

final class ActiveDateRangeProvider
    extends
        $FunctionalProvider<ReportDateRange, ReportDateRange, ReportDateRange>
    with $Provider<ReportDateRange> {
  ActiveDateRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDateRangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDateRangeHash();

  @$internal
  @override
  $ProviderElement<ReportDateRange> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReportDateRange create(Ref ref) {
    return activeDateRange(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportDateRange value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportDateRange>(value),
    );
  }
}

String _$activeDateRangeHash() => r'2d4fb1e4e5eaf9a7718083b7e10c36996f87ba6e';

@ProviderFor(reportSales)
final reportSalesProvider = ReportSalesProvider._();

final class ReportSalesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  ReportSalesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportSalesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportSalesHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return reportSales(ref);
  }
}

String _$reportSalesHash() => r'42dfd372f3524bafb26cb3c5d81a9c7332e47460';

@ProviderFor(salesSummary)
final salesSummaryProvider = SalesSummaryProvider._();

final class SalesSummaryProvider
    extends $FunctionalProvider<SalesSummary, SalesSummary, SalesSummary>
    with $Provider<SalesSummary> {
  SalesSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesSummaryHash();

  @$internal
  @override
  $ProviderElement<SalesSummary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SalesSummary create(Ref ref) {
    return salesSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SalesSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SalesSummary>(value),
    );
  }
}

String _$salesSummaryHash() => r'3f8a5670ddd8f319386f9db7332d362d0330f6ae';

@ProviderFor(cashierReport)
final cashierReportProvider = CashierReportProvider._();

final class CashierReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CashierReportRow>>,
          List<CashierReportRow>,
          Stream<List<CashierReportRow>>
        >
    with
        $FutureModifier<List<CashierReportRow>>,
        $StreamProvider<List<CashierReportRow>> {
  CashierReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashierReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashierReportHash();

  @$internal
  @override
  $StreamProviderElement<List<CashierReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CashierReportRow>> create(Ref ref) {
    return cashierReport(ref);
  }
}

String _$cashierReportHash() => r'18bb6a74e579ff135cf774bb54f4997807a55c6a';

@ProviderFor(salespersonReport)
final salespersonReportProvider = SalespersonReportProvider._();

final class SalespersonReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SalespersonReportRow>>,
          List<SalespersonReportRow>,
          Stream<List<SalespersonReportRow>>
        >
    with
        $FutureModifier<List<SalespersonReportRow>>,
        $StreamProvider<List<SalespersonReportRow>> {
  SalespersonReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salespersonReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salespersonReportHash();

  @$internal
  @override
  $StreamProviderElement<List<SalespersonReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SalespersonReportRow>> create(Ref ref) {
    return salespersonReport(ref);
  }
}

String _$salespersonReportHash() => r'5facd941b87df23a6e901be7b3392f7e25617338';

@ProviderFor(productsReport)
final productsReportProvider = ProductsReportProvider._();

final class ProductsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProductReportRow>>,
          List<ProductReportRow>,
          Stream<List<ProductReportRow>>
        >
    with
        $FutureModifier<List<ProductReportRow>>,
        $StreamProvider<List<ProductReportRow>> {
  ProductsReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productsReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productsReportHash();

  @$internal
  @override
  $StreamProviderElement<List<ProductReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProductReportRow>> create(Ref ref) {
    return productsReport(ref);
  }
}

String _$productsReportHash() => r'abdad2bef8a8123a54101aa684807445035d66fe';

@ProviderFor(stockLevelsReport)
final stockLevelsReportProvider = StockLevelsReportProvider._();

final class StockLevelsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StockLevelReportRow>>,
          List<StockLevelReportRow>,
          Stream<List<StockLevelReportRow>>
        >
    with
        $FutureModifier<List<StockLevelReportRow>>,
        $StreamProvider<List<StockLevelReportRow>> {
  StockLevelsReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockLevelsReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockLevelsReportHash();

  @$internal
  @override
  $StreamProviderElement<List<StockLevelReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StockLevelReportRow>> create(Ref ref) {
    return stockLevelsReport(ref);
  }
}

String _$stockLevelsReportHash() => r'a06b05c810cb58b03274a4f82b9f41ddf163d77d';

@ProviderFor(invoicesReport)
final invoicesReportProvider = InvoicesReportProvider._();

final class InvoicesReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvoiceReportRow>>,
          List<InvoiceReportRow>,
          Stream<List<InvoiceReportRow>>
        >
    with
        $FutureModifier<List<InvoiceReportRow>>,
        $StreamProvider<List<InvoiceReportRow>> {
  InvoicesReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoicesReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoicesReportHash();

  @$internal
  @override
  $StreamProviderElement<List<InvoiceReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InvoiceReportRow>> create(Ref ref) {
    return invoicesReport(ref);
  }
}

String _$invoicesReportHash() => r'5924023f7cd7f06e9824b7b58efa8f56ee546801';

@ProviderFor(reconciliationsReport)
final reconciliationsReportProvider = ReconciliationsReportProvider._();

final class ReconciliationsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReconciliationReportRow>>,
          List<ReconciliationReportRow>,
          Stream<List<ReconciliationReportRow>>
        >
    with
        $FutureModifier<List<ReconciliationReportRow>>,
        $StreamProvider<List<ReconciliationReportRow>> {
  ReconciliationsReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconciliationsReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconciliationsReportHash();

  @$internal
  @override
  $StreamProviderElement<List<ReconciliationReportRow>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReconciliationReportRow>> create(Ref ref) {
    return reconciliationsReport(ref);
  }
}

String _$reconciliationsReportHash() =>
    r'567e16c23dcd0614f5724d37ac66a7e029a74a6a';
