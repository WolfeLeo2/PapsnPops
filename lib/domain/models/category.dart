class Category {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.createdAt,
  });

  factory Category.fromRow(Map<String, dynamic> row) {
    return Category(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String?,
      color: row['color'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
