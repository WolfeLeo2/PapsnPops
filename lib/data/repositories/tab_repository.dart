import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/open_tab.dart';
import '../../domain/models/tab_item.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';
import '../powersync/powersync_client.dart';

final tabRepositoryProvider = Provider<TabRepository>((ref) {
  return TabRepository();
});

class TabRepository {
  Stream<List<OpenTab>> watchOpenTabs(String branchId) {
    return db
        .watch(
          'SELECT * FROM open_tabs WHERE branch_id = ? AND is_open = 1 ORDER BY created_at DESC',
          parameters: [branchId],
        )
        .map((rows) => rows.map((row) => OpenTab.fromRow(row)).toList());
  }

  Stream<List<TabItem>> watchTabItems(String tabId) {
    return db
        .watch(
          'SELECT * FROM tab_items WHERE tab_id = ? ORDER BY created_at ASC',
          parameters: [tabId],
        )
        .map((rows) => rows.map((row) => TabItem.fromRow(row)).toList());
  }

  Future<void> createTab(OpenTab tab) async {
    final row = tab.toRow();
    final columns = row.keys.join(', ');
    final placeholders = List.filled(row.length, '?').join(', ');
    await db.execute(
      'INSERT INTO open_tabs ($columns) VALUES ($placeholders)',
      row.values.toList(),
    );
  }

  Future<void> addTabItem(TabItem item) async {
    await db.writeTransaction((tx) async {
      final existing = await tx.getOptional(
        'SELECT id, quantity FROM tab_items WHERE tab_id = ? AND variant_id = ?',
        [item.tabId, item.variantId],
      );

      if (existing != null) {
        final currentQty = (existing['quantity'] as int?) ?? 0;
        final newQty = currentQty + item.quantity;
        await tx.execute(
          'UPDATE tab_items SET quantity = ? WHERE id = ?',
          [newQty, existing['id']],
        );
      } else {
        final row = item.toRow();
        final columns = row.keys.join(', ');
        final placeholders = List.filled(row.length, '?').join(', ');
        await tx.execute(
          'INSERT INTO tab_items ($columns) VALUES ($placeholders)',
          row.values.toList(),
        );
      }
    });
  }

  Future<void> removeTabItem(String tabItemId) async {
    await db.execute('DELETE FROM tab_items WHERE id = ?', [tabItemId]);
  }

  Future<void> updateTabItemQuantity(String tabItemId, int quantity) async {
    await db.execute(
      'UPDATE tab_items SET quantity = ? WHERE id = ?',
      [quantity, tabItemId],
    );
  }

  Future<void> closeTab(String tabId, Sale sale, List<SaleItem> items) async {
    await db.writeTransaction((tx) async {
      // 1. Insert sale using dynamically generated SQL from row map
      final saleRow = sale.toRow();
      final saleColumns = saleRow.keys.join(', ');
      final salePlaceholders = List.filled(saleRow.length, '?').join(', ');
      await tx.execute(
        'INSERT INTO sales ($saleColumns) VALUES ($salePlaceholders)',
        saleRow.values.toList(),
      );

      final now = DateTime.now().toUtc().toIso8601String();

      // 2. For each SaleItem in items
      for (final item in items) {
        // Insert sale item
        final itemRow = item.toRow();
        final itemColumns = itemRow.keys.join(', ');
        final itemPlaceholders = List.filled(itemRow.length, '?').join(', ');
        await tx.execute(
          'INSERT INTO sale_items ($itemColumns) VALUES ($itemPlaceholders)',
          itemRow.values.toList(),
        );

        // Fetch conversion factor
        final variantRow = await tx.getOptional(
          'SELECT conversion_factor FROM product_variants WHERE id = ?',
          [item.variantId],
        );
        final factor = (variantRow?['conversion_factor'] as int?) ?? 1;
        final rawDelta = -item.quantity * factor;

        // Insert stock movement
        await tx.execute(
          '''
          INSERT INTO stock_movements (id, branch_id, product_id, type, quantity, cost_price, reason, reference_id, user_id, created_at)
          VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            sale.branchId,
            item.productId,
            'sale',
            rawDelta,
            item.costPrice,
            'Sale',
            sale.id,
            sale.cashierId,
            sale.createdAt.toUtc().toIso8601String(),
          ],
        );

        // Update stock levels locally
        final stockLevelRow = await tx.getOptional(
          'SELECT id, quantity FROM stock_levels WHERE branch_id = ? AND product_id = ?',
          [sale.branchId, item.productId],
        );

        if (stockLevelRow != null) {
          final currentQty = (stockLevelRow['quantity'] as int?) ?? 0;
          await tx.execute(
            'UPDATE stock_levels SET quantity = ?, updated_at = ? WHERE id = ?',
            [currentQty + rawDelta, now, stockLevelRow['id']],
          );
        } else {
          await tx.execute(
            'INSERT INTO stock_levels (id, branch_id, product_id, quantity, updated_at) VALUES (uuid(), ?, ?, ?, ?)',
            [sale.branchId, item.productId, rawDelta, now],
          );
        }
      }

      // 3. Update open_tab status
      await tx.execute(
        'UPDATE open_tabs SET is_open = 0, closed_at = ?, sale_id = ?, updated_at = ? WHERE id = ?',
        [now, sale.id, now, tabId],
      );

      // 4. Delete items from tab_items
      await tx.execute(
        'DELETE FROM tab_items WHERE tab_id = ?',
        [tabId],
      );
    });
  }
}
