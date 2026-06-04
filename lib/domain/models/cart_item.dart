import 'product.dart';
import 'product_variant.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  final int quantity;
  final int discountAmount;

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
    this.discountAmount = 0,
  });

  int get subtotal => variant.sellingPrice * quantity;
  int get lineTotal => subtotal - discountAmount;

  CartItem copyWith({
    Product? product,
    ProductVariant? variant,
    int? quantity,
    int? discountAmount,
  }) {
    return CartItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
