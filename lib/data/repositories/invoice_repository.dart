import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/invoice.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';
import '../powersync/powersync_client.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

class InvoiceRepository {
  Stream<List<Invoice>> watchInvoices(String branchId, {String? status}) {
    final List<dynamic> params = [branchId];
    String query = 'SELECT * FROM invoices WHERE branch_id = ?';

    if (status != null) {
      query += ' AND status = ?';
      params.add(status);
    }

    query += ' ORDER BY created_at DESC';

    return db.watch(query, parameters: params).map((rows) {
      return rows.map((row) => Invoice.fromRow(row)).toList();
    });
  }

  Future<void> createInvoice(
    Invoice invoice,
    Sale sale,
    List<SaleItem> items,
  ) async {
    await db.writeTransaction((tx) async {
      // 1. Insert sale using dynamically generated SQL from row map
      final saleRow = sale.toRow();
      final saleColumns = saleRow.keys.join(', ');
      final salePlaceholders = List.filled(saleRow.length, '?').join(', ');
      await tx.execute(
        'INSERT INTO sales ($saleColumns) VALUES ($salePlaceholders)',
        saleRow.values.toList(),
      );

      final now = DateTime.now().toIso8601String();

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
            sale.createdAt.toIso8601String(),
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

      // 3. Insert invoice
      final invoiceRow = invoice.toRow();
      final invoiceColumns = invoiceRow.keys.join(', ');
      final invoicePlaceholders = List.filled(invoiceRow.length, '?').join(', ');
      await tx.execute(
        'INSERT INTO invoices ($invoiceColumns) VALUES ($invoicePlaceholders)',
        invoiceRow.values.toList(),
      );
    });
  }

  Future<void> logPayment({
    required String invoiceId,
    required String branchId,
    required int amount,
    required String paymentMethod,
    String? paymentReference,
    required String cashierId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.writeTransaction((tx) async {
      await tx.execute('''
        INSERT INTO invoice_payments (id, invoice_id, branch_id, amount, payment_method, payment_reference, cashier_id, created_at)
        VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?)
      ''', [
        invoiceId,
        branchId,
        amount,
        paymentMethod,
        paymentReference,
        cashierId,
        now,
      ]);

      final result = await tx.getOptional('''
        SELECT SUM(amount) as total_paid
        FROM invoice_payments
        WHERE invoice_id = ?
      ''', [invoiceId]);
      
      final totalPaid = (result?['total_paid'] as int?) ?? 0;

      final invoiceRow = await tx.getOptional('''
        SELECT s.total 
        FROM invoices i
        JOIN sales s ON i.sale_id = s.id
        WHERE i.id = ?
      ''', [invoiceId]);

      final invoiceTotal = (invoiceRow?['total'] as int?) ?? 0;

      if (totalPaid >= invoiceTotal) {
        await tx.execute('''
          UPDATE invoices SET status = 'paid', paid_at = ? WHERE id = ?
        ''', [now, invoiceId]);
      }
    });
  }

  Future<String> getNextInvoiceNumber(String branchId) async {
    final result = await db.getOptional(
      'SELECT invoice_number FROM invoices WHERE branch_id = ? ORDER BY created_at DESC LIMIT 1',
      [branchId],
    );
    final prefix = (branchId.length >= 4 ? branchId.substring(0, 4) : branchId).toUpperCase();
    if (result == null) {
      return 'INV-$prefix-0001';
    }
    final latestNumber = result['invoice_number'] as String;
    final parts = latestNumber.split('-');
    int nextNum = 1;
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      final parsed = int.tryParse(lastPart);
      if (parsed != null) {
        nextNum = parsed + 1;
      }
    }
    final paddedNum = nextNum.toString().padLeft(4, '0');
    return 'INV-$prefix-$paddedNum';
  }
}
