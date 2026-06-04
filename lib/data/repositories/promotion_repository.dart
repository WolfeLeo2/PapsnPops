import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/promotion.dart';
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
}
