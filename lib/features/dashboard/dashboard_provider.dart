import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/powersync/powersync_client.dart';
import '../../data/repositories/branch_provider.dart';

part 'dashboard_provider.g.dart';

class DashboardMetrics {
  final int todayRevenue;
  final int todaySalesCount;
  final int expectedCash;
  final List<double> revenueTrend;
  final List<double> salesCountTrend;
  final List<double> cashTrend;

  DashboardMetrics({
    required this.todayRevenue,
    required this.todaySalesCount,
    required this.expectedCash,
    required this.revenueTrend,
    required this.salesCountTrend,
    required this.cashTrend,
  });
}

class RecentSale {
  final String id;
  final int totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final List<RecentSaleItem> items;

  RecentSale({
    required this.id,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });
}

class RecentSaleItem {
  final String productName;
  final int quantity;

  RecentSaleItem({required this.productName, required this.quantity});
}

class StockLevelItem {
  final String productId;
  final String name;
  final String category;
  final int quantity;
  final int reorderLevel;

  StockLevelItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
  });
}

class OpenTabItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final int totalItems;

  OpenTabItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.totalItems,
  });
}

class LowStockAlertItem {
  final String productId;
  final String name;
  final int quantity;
  final int reorderLevel;

  LowStockAlertItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.reorderLevel,
  });
}

class TopProductItem {
  final String productId;
  final String name;
  final int unitsSold;

  TopProductItem({
    required this.productId,
    required this.name,
    required this.unitsSold,
  });
}

@riverpod
Stream<List<Map<String, dynamic>>> todaySales(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db.watch(
    '''
    SELECT total, payment_method, created_at 
    FROM sales 
    WHERE branch_id = ? 
      AND (is_voided = 0 OR is_voided IS NULL) 
      AND date(created_at, 'localtime') = date('now', 'localtime')
  ''',
    parameters: [branchId],
  );
}

@riverpod
Stream<List<Map<String, dynamic>>> activeReconciliations(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db.watch(
    '''
    SELECT expected_cash FROM cash_reconciliations
    WHERE branch_id = ? AND (shift_end IS NULL OR shift_end = '')
  ''',
    parameters: [branchId],
  );
}

@riverpod
DashboardMetrics dashboardMetrics(Ref ref) {
  final salesAsync = ref.watch(todaySalesProvider);
  final reconciliationsAsync = ref.watch(activeReconciliationsProvider);

  final sales = salesAsync.value ?? [];
  final reconciliations = reconciliationsAsync.value ?? [];

  int todayRevenue = 0;
  int todaySalesCount = sales.length;
  int expectedCash = 0;

  for (final sale in sales) {
    final amount = sale['total'] as int? ?? 0;
    todayRevenue += amount;

    final pm = (sale['payment_method'] as String? ?? '').toLowerCase();
    if (pm == 'cash') {
      expectedCash += amount;
    }
  }

  for (final rec in reconciliations) {
    expectedCash += rec['expected_cash'] as int? ?? 0;
  }

  // Generate segment trends (6 slots for the day)
  final revenueTrend = List<double>.filled(6, 0.0);
  final salesCountTrend = List<double>.filled(6, 0.0);
  final cashTrend = List<double>.filled(6, 0.0);

  for (final sale in sales) {
    final createdAtStr = sale['created_at'] as String?;
    if (createdAtStr == null) continue;
    final dateTime = DateTime.tryParse(createdAtStr)?.toLocal();
    if (dateTime == null) continue;

    final hour = dateTime.hour;
    final segmentIndex = (hour / 4).floor().clamp(0, 5);

    final amount = (sale['total'] as int? ?? 0).toDouble();
    revenueTrend[segmentIndex] += amount;
    salesCountTrend[segmentIndex] += 1.0;

    final pm = (sale['payment_method'] as String? ?? '').toLowerCase();
    if (pm == 'cash') {
      cashTrend[segmentIndex] += amount;
    }
  }

  // Fallback if there are no sales
  final fallbackRevenueTrend = revenueTrend.every((v) => v == 0)
      ? [0.0, 0.0, 0.0, 0.0, 0.0]
      : revenueTrend;
  final fallbackSalesCountTrend = salesCountTrend.every((v) => v == 0)
      ? [0.0, 0.0, 0.0, 0.0, 0.0]
      : salesCountTrend;
  final fallbackCashTrend = cashTrend.every((v) => v == 0)
      ? [0.0, 0.0, 0.0, 0.0, 0.0]
      : cashTrend;

  return DashboardMetrics(
    todayRevenue: todayRevenue,
    todaySalesCount: todaySalesCount,
    expectedCash: expectedCash,
    revenueTrend: fallbackRevenueTrend,
    salesCountTrend: fallbackSalesCountTrend,
    cashTrend: fallbackCashTrend,
  );
}

@riverpod
Stream<List<RecentSale>> recentSales(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db
      .watch(
        '''
    SELECT s.id as sale_id, s.total, s.payment_method, s.created_at,
           si.quantity, p.name as product_name
    FROM sales s
    LEFT JOIN sale_items si ON s.id = si.sale_id
    LEFT JOIN products p ON si.product_id = p.id
    WHERE s.branch_id = ? AND (s.is_voided = 0 OR s.is_voided IS NULL)
    ORDER BY s.created_at DESC
  ''',
        parameters: [branchId],
      )
      .map((rows) {
        final Map<String, RecentSale> salesMap = {};
        final List<String> orderedSaleIds = [];

        for (final row in rows) {
          final saleId = row['sale_id'] as String;
          if (!salesMap.containsKey(saleId)) {
            if (orderedSaleIds.length >= 5) continue;
            orderedSaleIds.add(saleId);
            salesMap[saleId] = RecentSale(
              id: saleId,
              totalAmount: row['total'] as int? ?? 0,
              paymentMethod: row['payment_method'] as String? ?? 'cash',
              createdAt:
                  DateTime.tryParse(
                    row['created_at'] as String? ?? '',
                  )?.toLocal() ??
                  DateTime.now(),
              items: [],
            );
          }

          final productName = row['product_name'] as String?;
          final qty = row['quantity'] as int?;
          if (productName != null && qty != null) {
            salesMap[saleId]!.items.add(
              RecentSaleItem(productName: productName, quantity: qty),
            );
          }
        }

        return orderedSaleIds.map((id) => salesMap[id]!).toList();
      });
}

@riverpod
Stream<List<StockLevelItem>> stockLevels(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db
      .watch(
        '''
    SELECT p.id as product_id, p.name, c.name as category, sl.quantity, p.reorder_level
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
          return StockLevelItem(
            productId: row['product_id'] as String,
            name: row['name'] as String,
            category: row['category'] as String? ?? 'Uncategorized',
            quantity: row['quantity'] as int? ?? 0,
            reorderLevel: row['reorder_level'] as int? ?? 10,
          );
        }).toList();
      });
}

@riverpod
Stream<List<OpenTabItem>> openTabs(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db
      .watch(
        '''
    SELECT ot.id, ot.name, ot.created_at, COALESCE(SUM(ti.quantity), 0) as total_items
    FROM open_tabs ot
    LEFT JOIN tab_items ti ON ot.id = ti.tab_id
    WHERE ot.branch_id = ? AND ot.is_open = 1
    GROUP BY ot.id
    ORDER BY ot.created_at DESC
  ''',
        parameters: [branchId],
      )
      .map((rows) {
        return rows.map((row) {
          return OpenTabItem(
            id: row['id'] as String,
            name: row['name'] as String,
            createdAt:
                DateTime.tryParse(
                  row['created_at'] as String? ?? '',
                )?.toLocal() ??
                DateTime.now(),
            totalItems: (row['total_items'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      });
}

@riverpod
Stream<List<LowStockAlertItem>> lowStockAlerts(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db
      .watch(
        '''
    SELECT p.id as product_id, p.name, sl.quantity, p.reorder_level
    FROM stock_levels sl
    JOIN products p ON sl.product_id = p.id
    WHERE sl.branch_id = ? AND sl.quantity <= COALESCE(p.reorder_level, 10)
    ORDER BY sl.quantity ASC
  ''',
        parameters: [branchId],
      )
      .map((rows) {
        return rows.map((row) {
          return LowStockAlertItem(
            productId: row['product_id'] as String,
            name: row['name'] as String,
            quantity: row['quantity'] as int? ?? 0,
            reorderLevel: row['reorder_level'] as int? ?? 10,
          );
        }).toList();
      });
}

@riverpod
Stream<List<TopProductItem>> topProducts(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db
      .watch(
        '''
    SELECT p.id as product_id, p.name, SUM(si.quantity) as units_sold
    FROM sale_items si
    JOIN sales s ON si.sale_id = s.id
    JOIN products p ON si.product_id = p.id
    WHERE s.branch_id = ? AND (s.is_voided = 0 OR s.is_voided IS NULL)
    GROUP BY p.id
    ORDER BY units_sold DESC
    LIMIT 5
  ''',
        parameters: [branchId],
      )
      .map((rows) {
        return rows.map((row) {
          return TopProductItem(
            productId: row['product_id'] as String,
            name: row['name'] as String,
            unitsSold: (row['units_sold'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      });
}
