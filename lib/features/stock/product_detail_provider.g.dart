// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(productStockTrend)
final productStockTrendProvider = ProductStockTrendFamily._();

final class ProductStockTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<double>>,
          List<double>,
          Stream<List<double>>
        >
    with $FutureModifier<List<double>>, $StreamProvider<List<double>> {
  ProductStockTrendProvider._({
    required ProductStockTrendFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'productStockTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productStockTrendHash();

  @override
  String toString() {
    return r'productStockTrendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<double>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<double>> create(Ref ref) {
    final argument = this.argument as String;
    return productStockTrend(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductStockTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productStockTrendHash() => r'33caaffa6d7d8f416f7bae241d26c6acde5dddf5';

final class ProductStockTrendFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<double>>, String> {
  ProductStockTrendFamily._()
    : super(
        retry: null,
        name: r'productStockTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProductStockTrendProvider call(String productId) =>
      ProductStockTrendProvider._(argument: productId, from: this);

  @override
  String toString() => r'productStockTrendProvider';
}
