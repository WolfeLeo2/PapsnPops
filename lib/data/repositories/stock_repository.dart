import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/stock_level.dart';
import '../powersync/powersync_client.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository();
});

class StockRepository {
  Stream<List<StockLevel>> watchStockLevels(String branchId) {
    return db
        .watch(
          'SELECT * FROM stock_levels WHERE branch_id = ?',
          parameters: [branchId],
        )
        .map((rows) => rows.map((row) => StockLevel.fromRow(row)).toList());
  }
}
