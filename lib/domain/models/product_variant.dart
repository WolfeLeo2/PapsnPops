class ProductVariant {
  final String id;
  final String productId;
  final String name; // e.g. 'Bottle', 'Crate (24)'
  final String unitLabel; // e.g. 'btl', 'crte'
  final int conversionFactor; // how many base units (e.g. crate = 24 bottles)
  final int sellingPrice; // KES × 100
  final int costPrice; // KES × 100
  final int? wholesalePrice;
  final String? barcode;
  final String? sku;
  final bool isActive;
  final bool isDefault; // shown by default in POS
  final DateTime createdAt;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.unitLabel,
    required this.conversionFactor,
    required this.sellingPrice,
    required this.costPrice,
    this.wholesalePrice,
    this.barcode,
    this.sku,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
  });

  factory ProductVariant.fromRow(Map<String, dynamic> row) {
    return ProductVariant(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      name: row['name'] as String,
      unitLabel: row['unit_label'] as String? ?? 'unit',
      conversionFactor: row['conversion_factor'] as int? ?? 1,
      sellingPrice: row['selling_price'] as int? ?? 0,
      costPrice: row['cost_price'] as int? ?? 0,
      wholesalePrice: row['wholesale_price'] as int?,
      barcode: row['barcode'] as String?,
      sku: row['sku'] as String?,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      isDefault: (row['is_default'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'unit_label': unitLabel,
      'conversion_factor': conversionFactor,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'wholesale_price': wholesalePrice,
      'barcode': barcode,
      'sku': sku,
      'is_active': isActive ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
