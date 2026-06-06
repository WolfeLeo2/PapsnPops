import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/promotion.dart';
import 'package:powersync/powersync.dart';
import '../supabase/supabase_client.dart';
import '../powersync/powersync_client.dart';

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository();
});

class PromotionRepository {
  Stream<List<Promotion>> watchActivePromotions() {
    return db
        .watch('SELECT * FROM promotions WHERE is_active = 1')
        .map((rows) => rows.map((row) => Promotion.fromRow(row)).toList());
  }

  Future<void> addPromotion({
    required String organisationId,
    required String name,
    required String type,
    required int value,
    required String targetType,
    required String? targetValue,
    required DateTime validFrom,
    required DateTime validUntil,
    required bool isHappyHour,
    String? happyHourStart,
    String? happyHourEnd,
    List<String>? activeDays,
  }) async {
    await supabase.from('promotions').insert({
      'organisation_id': organisationId,
      'name': name,
      'type': type,
      'value': value,
      'target_type': targetType,
      'target_value': targetValue,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'is_active': 1,
      'is_happy_hour': isHappyHour ? 1 : 0,
      'happy_hour_start': happyHourStart,
      'happy_hour_end': happyHourEnd,
      'active_days': activeDays,
    });
  }
}
