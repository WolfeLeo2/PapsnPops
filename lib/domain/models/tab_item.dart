class TabItem {
  final String id;
  final String tabId;
  final String productId;
  final String variantId;
  final String variantName;
  final int quantity;
  final int unitPrice;
  final String? addedBy;
  final DateTime createdAt;

  TabItem({
    required this.id,
    required this.tabId,
    required this.productId,
    required this.variantId,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    this.addedBy,
    required this.createdAt,
  });

  factory TabItem.fromRow(Map<String, dynamic> row) {
    return TabItem(
      id: row['id'] as String,
      tabId: row['tab_id'] as String,
      productId: row['product_id'] as String,
      variantId: row['variant_id'] as String,
      variantName: row['variant_name'] as String,
      quantity: row['quantity'] as int? ?? 0,
      unitPrice: row['unit_price'] as int? ?? 0,
      addedBy: row['added_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'tab_id': tabId,
      'product_id': productId,
      'variant_id': variantId,
      'variant_name': variantName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'added_by': addedBy?.isEmpty == true ? null : addedBy,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
