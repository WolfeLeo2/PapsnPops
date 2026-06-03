import 'product.dart';
import 'product_variant.dart';

class ProductWithVariants {
  final Product product;
  final List<ProductVariant> variants;

  const ProductWithVariants({required this.product, required this.variants});

  /// The variant marked as default, or the first variant if none is marked.
  ProductVariant get defaultVariant {
    return variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => variants.first,
    );
  }

  /// Convenience: true if there are no variants yet (shouldn't happen in practice).
  bool get hasVariants => variants.isNotEmpty;
}
