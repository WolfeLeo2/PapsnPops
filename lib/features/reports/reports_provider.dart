import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/powersync/powersync_client.dart';
import '../../data/repositories/branch_provider.dart';

part 'reports_provider.g.dart';

enum ReportPeriod { today, yesterday, thisWeek, thisMonth, custom }

// Tab navigation — mirrors ReportTab enum declared in reports_screen.dart
// We keep the state here so report widgets can read it too
@riverpod
class SelectedReportTab extends _$SelectedReportTab {
  @override
  int build() => 0; // index into ReportTab.values
  void select(int index) => state = index;
}

class ReportDateRange {
  final DateTime from;
  final DateTime to;
  ReportDateRange({required this.from, required this.to});
}

@riverpod
class SelectedReportPeriod extends _$SelectedReportPeriod {
  @override
  ReportPeriod build() => ReportPeriod.today;
  void set(ReportPeriod val) => state = val;
}

@riverpod
class CustomReportDateRange extends _$CustomReportDateRange {
  @override
  ReportDateRange? build() => null;
  void set(ReportDateRange? val) => state = val;
}

@riverpod
ReportDateRange activeDateRange(Ref ref) {
  final period = ref.watch(selectedReportPeriodProvider);
  final customRange = ref.watch(customReportDateRangeProvider);
  final now = DateTime.now();

  switch (period) {
    case ReportPeriod.today:
      return ReportDateRange(
        from: DateTime(now.year, now.month, now.day),
        to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
      );
    case ReportPeriod.yesterday:
      final yesterday = now.subtract(const Duration(days: 1));
      return ReportDateRange(
        from: DateTime(yesterday.year, yesterday.month, yesterday.day),
        to: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
          999,
        ),
      );
    case ReportPeriod.thisWeek:
      // Assuming week starts on Monday
      final daysSinceMonday = now.weekday - 1;
      final monday = now.subtract(Duration(days: daysSinceMonday));
      return ReportDateRange(
        from: DateTime(monday.year, monday.month, monday.day),
        to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
      );
    case ReportPeriod.thisMonth:
      return ReportDateRange(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
      );
    case ReportPeriod.custom:
      return customRange ??
          ReportDateRange(
            from: DateTime(now.year, now.month, now.day),
            to: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
          );
  }
}

// ── Models ─────────────────────────────────────────────────────────────

class SalesSummary {
  final int totalRevenue;
  final int totalSalesCount;
  final int grossProfit;
  final int averageSaleValue;
  final Map<String, int> revenueByPaymentMethod;
  final List<double> hourlyRevenue; // 24 slots

  SalesSummary({
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.grossProfit,
    required this.averageSaleValue,
    required this.revenueByPaymentMethod,
    required this.hourlyRevenue,
  });
}

class CashierReportRow {
  final String cashierName;
  final int salesCount;
  final int revenue;
  final int averageSale;
  final double percentageOfTotal;

  CashierReportRow({
    required this.cashierName,
    required this.salesCount,
    required this.revenue,
    required this.averageSale,
    required this.percentageOfTotal,
  });
}

class SalespersonReportRow {
  final String staffName;
  final int salesCount;
  final int revenue;
  final int averageSale;
  final double percentageOfTotal;

  SalespersonReportRow({
    required this.staffName,
    required this.salesCount,
    required this.revenue,
    required this.averageSale,
    required this.percentageOfTotal,
  });
}

class ProductReportRow {
  final String id;
  final String name;
  final String category;
  final int unitsSold;
  final int revenue;
  final int cost;
  final int profit;
  final double marginPercent;

  ProductReportRow({
    required this.id,
    required this.name,
    required this.category,
    required this.unitsSold,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPercent,
  });
}

// ── Providers ──────────────────────────────────────────────────────────

@riverpod
Stream<List<Map<String, dynamic>>> reportSales(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final range = ref.watch(activeDateRangeProvider);
  if (branchId == null) return Stream.value([]);

  final fromStr = range.from.toUtc().toIso8601String();
  final toStr = range.to.toUtc().toIso8601String();

  return db.watch(
    '''
    SELECT s.id, s.total, s.subtotal, s.payment_method, s.created_at, s.is_voided,
           si.quantity, si.line_total, si.cost_price
    FROM sales s
    LEFT JOIN sale_items si ON s.id = si.sale_id
    WHERE s.branch_id = ? 
      AND (s.is_voided = 0 OR s.is_voided IS NULL)
      AND s.created_at >= ? AND s.created_at <= ?
    ''',
    parameters: [branchId, fromStr, toStr],
  );
}

@riverpod
SalesSummary salesSummary(Ref ref) {
  final salesData = ref.watch(reportSalesProvider).value ?? [];

  int totalRevenue = 0;
  int totalCost = 0;
  final Set<String> saleIds = {};
  final Map<String, int> byMethod = {'cash': 0, 'mpesa': 0, 'card': 0};
  final List<double> hourly = List.filled(24, 0.0);

  for (final row in salesData) {
    final saleId = row['id'] as String;

    // Only count sale-level stats once per sale
    if (!saleIds.contains(saleId)) {
      saleIds.add(saleId);
      final total = row['total'] as int? ?? 0;
      totalRevenue += total;

      final pm = (row['payment_method'] as String? ?? 'cash').toLowerCase();
      byMethod[pm] = (byMethod[pm] ?? 0) + total;

      final createdAtStr = row['created_at'] as String?;
      if (createdAtStr != null) {
        final dt = DateTime.tryParse(createdAtStr)?.toLocal();
        if (dt != null) {
          hourly[dt.hour] += total.toDouble();
        }
      }
    }

    // Accumulate costs from items
    final qty = row['quantity'] as int? ?? 0;
    final costPrice = row['cost_price'] as int? ?? 0;
    totalCost += (qty * costPrice);
  }

  final grossProfit = totalRevenue - totalCost;
  final avg = saleIds.isEmpty ? 0 : (totalRevenue / saleIds.length).round();

  return SalesSummary(
    totalRevenue: totalRevenue,
    totalSalesCount: saleIds.length,
    grossProfit: grossProfit,
    averageSaleValue: avg,
    revenueByPaymentMethod: byMethod,
    hourlyRevenue: hourly,
  );
}

@riverpod
Stream<List<CashierReportRow>> cashierReport(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final range = ref.watch(activeDateRangeProvider);
  if (branchId == null) return Stream.value([]);

  final fromStr = range.from.toUtc().toIso8601String();
  final toStr = range.to.toUtc().toIso8601String();

  return db
      .watch(
        '''
    SELECT 
      up.full_name as cashier_name,
      COUNT(s.id) as sales_count,
      SUM(s.total) as revenue
    FROM sales s
    LEFT JOIN user_profiles up ON s.cashier_id = up.id
    WHERE s.branch_id = ? 
      AND (s.is_voided = 0 OR s.is_voided IS NULL)
      AND s.created_at >= ? AND s.created_at <= ?
    GROUP BY up.full_name
    ORDER BY revenue DESC
  ''',
        parameters: [branchId, fromStr, toStr],
      )
      .map((rows) {
        int grandTotal = 0;
        for (final row in rows) {
          grandTotal += (row['revenue'] as int? ?? 0);
        }

        return rows.map((row) {
          final revenue = row['revenue'] as int? ?? 0;
          final salesCount = row['sales_count'] as int? ?? 0;
          final avg = salesCount == 0 ? 0 : (revenue / salesCount).round();
          final percentage = grandTotal == 0
              ? 0.0
              : (revenue / grandTotal) * 100;

          return CashierReportRow(
            cashierName: row['cashier_name'] as String? ?? 'Unknown Cashier',
            salesCount: salesCount,
            revenue: revenue,
            averageSale: avg,
            percentageOfTotal: percentage,
          );
        }).toList();
      });
}

@riverpod
Stream<List<SalespersonReportRow>> salespersonReport(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final range = ref.watch(activeDateRangeProvider);
  if (branchId == null) return Stream.value([]);

  final fromStr = range.from.toUtc().toIso8601String();
  final toStr = range.to.toUtc().toIso8601String();

  return db
      .watch(
        '''
    SELECT 
      st.name as staff_name,
      COUNT(s.id) as sales_count,
      SUM(s.total) as revenue
    FROM sales s
    LEFT JOIN staff st ON s.staff_id = st.id
    WHERE s.branch_id = ? 
      AND (s.is_voided = 0 OR s.is_voided IS NULL)
      AND s.created_at >= ? AND s.created_at <= ?
    GROUP BY st.name
    ORDER BY revenue DESC
  ''',
        parameters: [branchId, fromStr, toStr],
      )
      .map((rows) {
        int grandTotal = 0;
        for (final row in rows) {
          grandTotal += (row['revenue'] as int? ?? 0);
        }

        return rows.map((row) {
          final revenue = row['revenue'] as int? ?? 0;
          final salesCount = row['sales_count'] as int? ?? 0;
          final avg = salesCount == 0 ? 0 : (revenue / salesCount).round();
          final percentage = grandTotal == 0
              ? 0.0
              : (revenue / grandTotal) * 100;

          return SalespersonReportRow(
            staffName:
                row['staff_name'] as String? ?? 'No Salesperson / Walk-in',
            salesCount: salesCount,
            revenue: revenue,
            averageSale: avg,
            percentageOfTotal: percentage,
          );
        }).toList();
      });
}

@riverpod
Stream<List<ProductReportRow>> productsReport(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final range = ref.watch(activeDateRangeProvider);
  if (branchId == null) return Stream.value([]);

  final fromStr = range.from.toUtc().toIso8601String();
  final toStr = range.to.toUtc().toIso8601String();

  return db
      .watch(
        '''
    SELECT 
      p.id as product_id,
      p.name as product_name,
      c.name as category_name,
      SUM(si.quantity) as units_sold,
      SUM(si.line_total) as revenue,
      SUM(si.quantity * si.cost_price) as cost
    FROM sale_items si
    JOIN sales s ON si.sale_id = s.id
    JOIN products p ON si.product_id = p.id
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE s.branch_id = ? 
      AND (s.is_voided = 0 OR s.is_voided IS NULL)
      AND s.created_at >= ? AND s.created_at <= ?
    GROUP BY p.id, p.name, c.name
    ORDER BY revenue DESC
  ''',
        parameters: [branchId, fromStr, toStr],
      )
      .map((rows) {
        return rows.map((row) {
          final revenue = row['revenue'] as int? ?? 0;
          final cost = row['cost'] as int? ?? 0;
          final profit = revenue - cost;
          final margin = revenue == 0 ? 0.0 : (profit / revenue) * 100;

          return ProductReportRow(
            id: row['product_id'] as String,
            name: row['product_name'] as String,
            category: row['category_name'] as String? ?? 'Uncategorized',
            unitsSold: (row['units_sold'] as num?)?.toInt() ?? 0,
            revenue: revenue,
            cost: cost,
            profit: profit,
            marginPercent: margin,
          );
        }).toList();
      });
}

class StockLevelReportRow {
  final String productId;
  final String name;
  final String category;
  final int quantity;
  final int reorderLevel;
  final DateTime? lastReceivedAt;

  StockLevelReportRow({
    required this.productId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    this.lastReceivedAt,
  });
}

@riverpod
Stream<List<StockLevelReportRow>> stockLevelsReport(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db
      .watch(
        '''
    SELECT 
      p.id as product_id, 
      p.name, 
      c.name as category, 
      sl.quantity, 
      p.reorder_level,
      (SELECT MAX(created_at) FROM stock_movements sm WHERE sm.product_id = p.id AND sm.branch_id = sl.branch_id AND sm.type = 'receive') as last_received_at
    FROM stock_levels sl
    JOIN products p ON sl.product_id = p.id
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE sl.branch_id = ?
    ORDER BY p.name ASC
  ''',
        parameters: [branchId],
      )
      .map((rows) {
        return rows.map((row) {
          return StockLevelReportRow(
            productId: row['product_id'] as String,
            name: row['name'] as String,
            category: row['category'] as String? ?? 'Uncategorized',
            quantity: row['quantity'] as int? ?? 0,
            reorderLevel: row['reorder_level'] as int? ?? 5,
            lastReceivedAt: row['last_received_at'] != null
                ? DateTime.tryParse(
                    row['last_received_at'] as String,
                  )?.toLocal()
                : null,
          );
        }).toList();
      });
}

class InvoiceReportRow {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String status;
  final int totalAmount;
  final DateTime createdAt;
  final DateTime? dueDate;

  InvoiceReportRow({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.dueDate,
  });
}

@riverpod
Stream<List<InvoiceReportRow>> invoicesReport(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final range = ref.watch(activeDateRangeProvider);
  if (branchId == null) return Stream.value([]);

  final fromStr = range.from.toUtc().toIso8601String();
  final toStr = range.to.toUtc().toIso8601String();

  return db
      .watch(
        '''
    SELECT 
      i.id,
      i.invoice_number,
      c.name as customer_name,
      i.status,
      s.total as total_amount,
      i.created_at,
      i.due_date
    FROM invoices i
    JOIN sales s ON i.sale_id = s.id
    JOIN customers c ON i.customer_id = c.id
    WHERE i.branch_id = ?
      AND i.created_at >= ? AND i.created_at <= ?
    ORDER BY i.created_at DESC
  ''',
        parameters: [branchId, fromStr, toStr],
      )
      .map((rows) {
        return rows.map((row) {
          return InvoiceReportRow(
            id: row['id'] as String,
            invoiceNumber: row['invoice_number'] as String,
            customerName: row['customer_name'] as String? ?? 'Unknown Customer',
            status: row['status'] as String? ?? 'unpaid',
            totalAmount: row['total_amount'] as int? ?? 0,
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            dueDate: row['due_date'] != null
                ? DateTime.tryParse(row['due_date'] as String)?.toLocal()
                : null,
          );
        }).toList();
      });
}

class ReconciliationReportRow {
  final String id;
  final String userName;
  final DateTime date; // Extracted from created_at or shift_start
  final int expectedCash;
  final int actualCash;
  final int discrepancy;

  ReconciliationReportRow({
    required this.id,
    required this.userName,
    required this.date,
    required this.expectedCash,
    required this.actualCash,
    required this.discrepancy,
  });
}

@riverpod
Stream<List<ReconciliationReportRow>> reconciliationsReport(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  final range = ref.watch(activeDateRangeProvider);
  if (branchId == null) return Stream.value([]);

  final fromStr = range.from.toUtc().toIso8601String();
  final toStr = range.to.toUtc().toIso8601String();

  return db
      .watch(
        '''
    SELECT 
      cr.id,
      up.full_name as user_name,
      cr.created_at,
      cr.expected_cash,
      cr.actual_cash,
      cr.difference as discrepancy
    FROM cash_reconciliations cr
    LEFT JOIN user_profiles up ON cr.user_id = up.id
    WHERE cr.branch_id = ?
      AND cr.created_at >= ? AND cr.created_at <= ?
    ORDER BY cr.created_at DESC
  ''',
        parameters: [branchId, fromStr, toStr],
      )
      .map((rows) {
        return rows.map((row) {
          return ReconciliationReportRow(
            id: row['id'] as String,
            userName: row['user_name'] as String? ?? 'Unknown User',
            date: DateTime.parse(row['created_at'] as String).toLocal(),
            expectedCash: row['expected_cash'] as int? ?? 0,
            actualCash: row['actual_cash'] as int? ?? 0,
            discrepancy: row['discrepancy'] as int? ?? 0,
          );
        }).toList();
      });
}
