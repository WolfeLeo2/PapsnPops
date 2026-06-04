class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String variantId;
  final String variantName;
  final int quantity;
  final int unitPrice;
  final int costPrice;
  final int discountAmount;
  final int lineTotal;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.variantId,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.discountAmount,
    required this.lineTotal,
  });

  factory SaleItem.fromRow(Map<String, dynamic> row) {
    return SaleItem(
      id: row['id'] as String,
      saleId: row['sale_id'] as String,
      productId: row['product_id'] as String,
      variantId: row['variant_id'] as String,
      variantName: row['variant_name'] as String,
      quantity: row['quantity'] as int? ?? 0,
      unitPrice: row['unit_price'] as int? ?? 0,
      costPrice: row['cost_price'] as int? ?? 0,
      discountAmount: row['discount_amount'] as int? ?? 0,
      lineTotal: row['line_total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'variant_id': variantId,
      'variant_name': variantName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount_amount': discountAmount,
      'line_total': lineTotal,
    };
  }
}
