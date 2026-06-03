class Product {
  final String id;
  final String name;
  final String? categoryId;
  final int reorderLevel;
  final bool isActive;
  final String baseUnit;
  final int? containerSize;
  final String? containerName;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.categoryId,
    this.reorderLevel = 10,
    this.isActive = true,
    this.baseUnit = 'piece',
    this.containerSize,
    this.containerName,
    required this.createdAt,
  });

  factory Product.fromRow(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String?,
      reorderLevel: row['reorder_level'] as int? ?? 10,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      baseUnit: row['base_unit'] as String? ?? 'piece',
      containerSize: row['container_size'] as int?,
      containerName: row['container_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'reorder_level': reorderLevel,
      'is_active': isActive ? 1 : 0,
      'base_unit': baseUnit,
      'container_size': containerSize,
      'container_name': containerName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
