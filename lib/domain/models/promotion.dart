import 'dart:convert';

class Promotion {
  final String id;
  final String name;
  final String type; // 'percentage' or 'fixed'
  final int value;
  final String targetType; // 'all', 'category', 'product'
  final String? targetValue;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final bool isHappyHour;
  final String? happyHourStart;
  final String? happyHourEnd;
  final List<String> activeDays;
  final DateTime createdAt;

  Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.targetType,
    this.targetValue,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.isHappyHour,
    this.happyHourStart,
    this.happyHourEnd,
    required this.activeDays,
    required this.createdAt,
  });

  factory Promotion.fromRow(Map<String, dynamic> row) {
    List<String> activeDays = [];
    final activeDaysRaw = row['active_days'];
    if (activeDaysRaw is String) {
      try {
        final decoded = jsonDecode(activeDaysRaw);
        if (decoded is List) {
          activeDays = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Fallback for non-JSON string if any
        if (activeDaysRaw.isNotEmpty) {
          activeDays = activeDaysRaw.split(',').map((e) => e.trim()).toList();
        }
      }
    } else if (activeDaysRaw is List) {
      activeDays = activeDaysRaw.map((e) => e.toString()).toList();
    }

    final validFromRaw = row['valid_from'];
    final validUntilRaw = row['valid_until'];

    return Promotion(
      id: row['id'] as String,
      name: row['name'] as String,
      type: row['type'] as String,
      value: row['value'] as int? ?? 0,
      targetType: row['target_type'] as String,
      targetValue: row['target_value'] as String?,
      validFrom: validFromRaw != null && (validFromRaw as String).isNotEmpty
          ? DateTime.tryParse(validFromRaw)
          : null,
      validUntil: validUntilRaw != null && (validUntilRaw as String).isNotEmpty
          ? DateTime.tryParse(validUntilRaw)
          : null,
      isActive: (row['is_active'] as int? ?? 1) == 1,
      isHappyHour: (row['is_happy_hour'] as int? ?? 0) == 1,
      happyHourStart: row['happy_hour_start'] as String?,
      happyHourEnd: row['happy_hour_end'] as String?,
      activeDays: activeDays,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'target_type': targetType,
      'target_value': targetValue,
      'valid_from': validFrom?.toIso8601String().split('T').first,
      'valid_until': validUntil?.toIso8601String().split('T').first,
      'is_active': isActive ? 1 : 0,
      'is_happy_hour': isHappyHour ? 1 : 0,
      'happy_hour_start': happyHourStart,
      'happy_hour_end': happyHourEnd,
      'active_days': jsonEncode(activeDays),
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
