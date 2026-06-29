import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';
import '../powersync/powersync_client.dart';
import '../../core/utils/error_reporting.dart';
import '../../domain/sale_validation.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

class SaleRepository {
  Stream<List<Sale>> watchSales(
    String branchId, {
    DateTime? dateFrom,
    DateTime? dateTo,
    String? paymentMethod,
    String? cashierId,
  }) {
    final List<dynamic> params = [branchId];
    String query = 'SELECT * FROM sales WHERE branch_id = ?';

    if (dateFrom != null) {
      query += ' AND created_at >= ?';
      params.add(dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      query += ' AND created_at <= ?';
      params.add(dateTo.toIso8601String());
    }
    if (paymentMethod != null) {
      query += ' AND payment_method = ?';
      params.add(paymentMethod);
    }
    if (cashierId != null) {
      query += ' AND cashier_id = ?';
      params.add(cashierId);
    }

    query += ' ORDER BY created_at DESC';

    return db.watch(query, parameters: params).map((rows) {
      return rows.map((row) => Sale.fromRow(row)).toList();
    });
  }

  Future<(Sale, List<SaleItem>)> getSaleWithItems(String saleId) async {
    final saleRow = await db.getOptional('SELECT * FROM sales WHERE id = ?', [saleId]);
    if (saleRow == null) {
      throw Exception('Sale not found: $saleId');
    }
    final itemRows = await db.getAll('SELECT * FROM sale_items WHERE sale_id = ?', [saleId]);
    
    final sale = Sale.fromRow(saleRow);
    final items = itemRows.map((row) => SaleItem.fromRow(row)).toList();
    return (sale, items);
  }

  Future<void> createSale(Sale sale, List<SaleItem> items) => guardWrite(
        ErrorArea.saleWrite,
        'createSale',
        () => _createSale(sale, items),
        tags: {'branch_id': sale.branchId},
        data: {'sale_id': sale.id, 'item_count': items.length},
      );

  Future<void> _createSale(Sale sale, List<SaleItem> items) async {
    assertSaleValid(sale, items);
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
    });
  }

  Future<void> voidSale(String saleId, String voidedBy) => guardWrite(
        ErrorArea.saleWrite,
        'voidSale',
        () => _voidSale(saleId, voidedBy),
        tags: {'sale_id': saleId},
      );

  Future<void> _voidSale(String saleId, String voidedBy) async {
    await db.writeTransaction((tx) async {
      final saleRow = await tx.getOptional('SELECT * FROM sales WHERE id = ?', [saleId]);
      if (saleRow == null) {
        throw Exception('Sale not found: $saleId');
      }
      final sale = Sale.fromRow(saleRow);
      if (sale.isVoided) {
        return; // already voided
      }

      final itemRows = await tx.getAll('SELECT * FROM sale_items WHERE sale_id = ?', [saleId]);
      final items = itemRows.map((row) => SaleItem.fromRow(row)).toList();
      final now = DateTime.now().toUtc().toIso8601String();

      // Update sale
      await tx.execute(
        'UPDATE sales SET is_voided = 1, voided_by = ?, voided_at = ? WHERE id = ?',
        [voidedBy, now, saleId],
      );

      for (final item in items) {
        final variantRow = await tx.getOptional(
          'SELECT conversion_factor FROM product_variants WHERE id = ?',
          [item.variantId],
        );
        final factor = (variantRow?['conversion_factor'] as int?) ?? 1;
        final rawDelta = item.quantity * factor;

        // Insert stock movement
        await tx.execute(
          '''
          INSERT INTO stock_movements (id, branch_id, product_id, type, quantity, cost_price, reason, reference_id, user_id, created_at)
          VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            sale.branchId,
            item.productId,
            'void',
            rawDelta,
            item.costPrice,
            'Void Sale',
            saleId,
            voidedBy,
            now,
          ],
        );

        // Update stock levels
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
    });
  }
}
