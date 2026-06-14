class StockLevel {
  final String id;
  final String branchId;
  final String productId;
  final int quantity;
  final DateTime lastUpdated;

  StockLevel({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.quantity,
    required this.lastUpdated,
  });

  factory StockLevel.fromRow(Map<String, dynamic> row) {
    return StockLevel(
      id: row['id'] as String,
      branchId: row['branch_id'] as String,
      productId: row['product_id'] as String,
      quantity: row['quantity'] as int? ?? 0,
      lastUpdated: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  }
}
