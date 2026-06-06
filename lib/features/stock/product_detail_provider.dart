import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/powersync/powersync_client.dart';
import '../../data/repositories/branch_provider.dart';

part 'product_detail_provider.g.dart';

@riverpod
Stream<List<double>> productStockTrend(Ref ref, String productId) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([0.0, 0.0, 0.0, 0.0, 0.0]);

  return db
      .watch(
        '''
    SELECT 
      (SELECT quantity FROM stock_levels WHERE product_id = ? AND branch_id = ?) as current_stock,
      quantity, created_at
    FROM stock_movements
    WHERE branch_id = ? AND product_id = ?
    ORDER BY created_at DESC
    LIMIT 30
  ''',
        parameters: [productId, branchId, branchId, productId],
      )
      .map((rows) {
        if (rows.isEmpty) {
          // Return a flat line of current stock
          return [0.0, 0.0, 0.0, 0.0, 0.0];
        }

        final currentStock = rows.first['current_stock'] as int? ?? 0;

        List<double> points = [currentStock.toDouble()];
        int running = currentStock;
        for (var row in rows) {
          final movement = row['quantity'] as int? ?? 0;
          running = running - movement;
          points.add(running.toDouble());
        }

        return points.reversed.toList();
      });
}
