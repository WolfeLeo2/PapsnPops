class AdjustmentReason {
  final String id;
  final String name;
  final DateTime createdAt;

  AdjustmentReason({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory AdjustmentReason.fromRow(Map<String, dynamic> row) {
    return AdjustmentReason(
      id: row['id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {'id': id, 'name': name, 'created_at': createdAt.toIso8601String()};
  }
}
