import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../domain/models/sale.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/invoice.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/repositories/branch_provider.dart';
import '../../../data/powersync/powersync_client.dart';

part 'sales_history_provider.g.dart';

@riverpod
class SalesSearchQuery extends _$SalesSearchQuery {
  @override
  String build() => '';
  void set(String val) => state = val;
}

@riverpod
class SalesDateRange extends _$SalesDateRange {
  @override
  DateTimeRange? build() => null;
  void set(DateTimeRange? val) => state = val;
}

@riverpod
class SalesPaymentMethod extends _$SalesPaymentMethod {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

@riverpod
class SalesSource extends _$SalesSource {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

@riverpod
class SelectedSaleId extends _$SelectedSaleId {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

@riverpod
class SalesUnpaidOnly extends _$SalesUnpaidOnly {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

@riverpod
Stream<List<Sale>> salesHistoryStream(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  final query = ref.watch(salesSearchQueryProvider).trim();
  final dateRange = ref.watch(salesDateRangeProvider);
  final paymentMethod = ref.watch(salesPaymentMethodProvider);
  final source = ref.watch(salesSourceProvider);
  final isUnpaidOnly = ref.watch(salesUnpaidOnlyProvider);

  String sql = 'SELECT DISTINCT s.* FROM sales s';
  final List<dynamic> params = [];

  if (isUnpaidOnly) {
    sql += ' INNER JOIN invoices inv ON s.id = inv.sale_id AND inv.status != \'paid\'';
  }

  // Joins if searching
  if (query.isNotEmpty) {
    sql += ' LEFT JOIN customers c ON s.customer_id = c.id';
    sql += ' LEFT JOIN sale_items si ON s.id = si.sale_id';
  }

  sql += ' WHERE s.branch_id = ?';
  params.add(branchId);

  if (dateRange != null) {
    sql += ' AND s.created_at >= ? AND s.created_at <= ?';
    params.add(dateRange.start.toIso8601String());
    // Include the entire end day
    final endDay = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
    params.add(endDay.toIso8601String());
  }

  if (paymentMethod != null) {
    sql += ' AND s.payment_method = ?';
    params.add(paymentMethod);
  }

  if (source != null) {
    sql += ' AND s.source = ?';
    params.add(source);
  }

  if (query.isNotEmpty) {
    sql += ' AND (s.id LIKE ? OR s.payment_reference LIKE ? OR c.name LIKE ? OR c.phone LIKE ? OR si.variant_name LIKE ?)';
    final wildcardQuery = '%$query%';
    params.addAll([
      wildcardQuery,
      wildcardQuery,
      wildcardQuery,
      wildcardQuery,
      wildcardQuery,
    ]);
  }

  sql += ' ORDER BY s.created_at DESC';

  return db.watch(sql, parameters: params).map((rows) {
    return rows.map((row) => Sale.fromRow(row)).toList();
  });
}

@riverpod
Future<Map<String, dynamic>> saleDetail(Ref ref, String saleId) async {
  final (sale, items) = await ref.read(saleRepositoryProvider).getSaleWithItems(saleId);
  
  Customer? customer;
  if (sale.customerId != null) {
    final custRow = await db.getOptional('SELECT * FROM customers WHERE id = ?', [sale.customerId]);
    if (custRow != null) {
      customer = Customer.fromRow(custRow);
    }
  }

  Invoice? invoice;
  int totalPaid = 0;
  if (sale.source == 'invoice') {
    final invRow = await db.getOptional('SELECT * FROM invoices WHERE sale_id = ?', [sale.id]);
    if (invRow != null) {
      invoice = Invoice.fromRow(invRow);
      final paidRow = await db.getOptional('SELECT SUM(amount) as total_paid FROM invoice_payments WHERE invoice_id = ?', [invoice.id]);
      totalPaid = (paidRow?['total_paid'] as int?) ?? 0;
    }
  }

  // Fetch cashier and salesperson name
  final cashierRow = await db.getOptional('SELECT full_name FROM user_profiles WHERE id = ?', [sale.cashierId]);
  final cashierName = cashierRow?['full_name'] as String? ?? 'Cashier';

  String? staffName;
  if (sale.staffId != null) {
    final staffRow = await db.getOptional('SELECT name FROM staff WHERE id = ?', [sale.staffId]);
    staffName = staffRow?['name'] as String?;
  }

  return {
    'sale': sale,
    'items': items,
    'customer': customer,
    'invoice': invoice,
    'totalPaid': totalPaid,
    'cashierName': cashierName,
    'staffName': staffName,
  };
}
