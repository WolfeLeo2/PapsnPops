// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SalesSearchQuery)
final salesSearchQueryProvider = SalesSearchQueryProvider._();

final class SalesSearchQueryProvider
    extends $NotifierProvider<SalesSearchQuery, String> {
  SalesSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesSearchQueryHash();

  @$internal
  @override
  SalesSearchQuery create() => SalesSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$salesSearchQueryHash() => r'bacf9c283c5d480628bb349d4f5ab4f480b52885';

abstract class _$SalesSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SalesDateRange)
final salesDateRangeProvider = SalesDateRangeProvider._();

final class SalesDateRangeProvider
    extends $NotifierProvider<SalesDateRange, DateTimeRange<DateTime>?> {
  SalesDateRangeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesDateRangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesDateRangeHash();

  @$internal
  @override
  SalesDateRange create() => SalesDateRange();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTimeRange<DateTime>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTimeRange<DateTime>?>(value),
    );
  }
}

String _$salesDateRangeHash() => r'32c063b63b8b2bbb01b5531ad2f1a06e0884ed01';

abstract class _$SalesDateRange extends $Notifier<DateTimeRange<DateTime>?> {
  DateTimeRange<DateTime>? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<DateTimeRange<DateTime>?, DateTimeRange<DateTime>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTimeRange<DateTime>?, DateTimeRange<DateTime>?>,
              DateTimeRange<DateTime>?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SalesPaymentMethod)
final salesPaymentMethodProvider = SalesPaymentMethodProvider._();

final class SalesPaymentMethodProvider
    extends $NotifierProvider<SalesPaymentMethod, String?> {
  SalesPaymentMethodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesPaymentMethodProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesPaymentMethodHash();

  @$internal
  @override
  SalesPaymentMethod create() => SalesPaymentMethod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$salesPaymentMethodHash() =>
    r'1cd446b6ff773db8ef570b37c34e403174c39e1f';

abstract class _$SalesPaymentMethod extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SalesSource)
final salesSourceProvider = SalesSourceProvider._();

final class SalesSourceProvider
    extends $NotifierProvider<SalesSource, String?> {
  SalesSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesSourceHash();

  @$internal
  @override
  SalesSource create() => SalesSource();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$salesSourceHash() => r'a999daadfe321152d7f121848ac976719331bb24';

abstract class _$SalesSource extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedSaleId)
final selectedSaleIdProvider = SelectedSaleIdProvider._();

final class SelectedSaleIdProvider
    extends $NotifierProvider<SelectedSaleId, String?> {
  SelectedSaleIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSaleIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSaleIdHash();

  @$internal
  @override
  SelectedSaleId create() => SelectedSaleId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedSaleIdHash() => r'3edc45d9634a545884e84523453f9b51e197e124';

abstract class _$SelectedSaleId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SalesUnpaidOnly)
final salesUnpaidOnlyProvider = SalesUnpaidOnlyProvider._();

final class SalesUnpaidOnlyProvider
    extends $NotifierProvider<SalesUnpaidOnly, bool> {
  SalesUnpaidOnlyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesUnpaidOnlyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesUnpaidOnlyHash();

  @$internal
  @override
  SalesUnpaidOnly create() => SalesUnpaidOnly();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$salesUnpaidOnlyHash() => r'cd95547d10d3ffbcaec83b36f1a9661fb05be5c4';

abstract class _$SalesUnpaidOnly extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(salesHistoryStream)
final salesHistoryStreamProvider = SalesHistoryStreamProvider._();

final class SalesHistoryStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Sale>>,
          List<Sale>,
          Stream<List<Sale>>
        >
    with $FutureModifier<List<Sale>>, $StreamProvider<List<Sale>> {
  SalesHistoryStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'salesHistoryStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$salesHistoryStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Sale>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Sale>> create(Ref ref) {
    return salesHistoryStream(ref);
  }
}

String _$salesHistoryStreamHash() =>
    r'2611498e8ad0d696e1104d7710fdcdd315305b2c';

@ProviderFor(saleDetail)
final saleDetailProvider = SaleDetailFamily._();

final class SaleDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  SaleDetailProvider._({
    required SaleDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'saleDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$saleDetailHash();

  @override
  String toString() {
    return r'saleDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as String;
    return saleDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SaleDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$saleDetailHash() => r'3f3467aaf0cbdde037253ffede2c8fd8d72bdc31';

final class SaleDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>>, String> {
  SaleDetailFamily._()
    : super(
        retry: null,
        name: r'saleDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SaleDetailProvider call(String saleId) =>
      SaleDetailProvider._(argument: saleId, from: this);

  @override
  String toString() => r'saleDetailProvider';
}
