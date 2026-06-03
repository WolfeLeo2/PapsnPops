import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paps_n_pops/features/dashboard/dashboard_screen.dart';
import 'package:paps_n_pops/features/dashboard/dashboard_provider.dart';
import 'package:paps_n_pops/shared/widgets/stat_card.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late DashboardMetrics mockMetrics;
    late List<RecentSale> mockRecentSales;
    late List<StockLevelItem> mockStockLevels;
    late List<OpenTabItem> mockOpenTabs;
    late List<LowStockAlertItem> mockLowStockAlerts;
    late List<TopProductItem> mockTopProducts;

    setUp(() {
      mockMetrics = DashboardMetrics(
        todayRevenue: 125000, // KES 1,250
        todaySalesCount: 15,
        expectedCash: 80000, // KES 800
        revenueTrend: [10.0, 20.0, 30.0, 40.0, 50.0, 60.0],
        salesCountTrend: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
        cashTrend: [5.0, 10.0, 15.0, 20.0, 25.0, 30.0],
      );

      mockRecentSales = [
        RecentSale(
          id: 'sale-1',
          totalAmount: 150000, // KES 1,500
          paymentMethod: 'mpesa',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          items: [
            RecentSaleItem(productName: 'Tusker Lager', quantity: 2),
            RecentSaleItem(productName: 'Guinness', quantity: 1),
          ],
        ),
      ];

      mockStockLevels = [
        StockLevelItem(
          productId: 'prod-1',
          name: 'Tusker Lager',
          category: 'beer',
          quantity: 45,
          reorderLevel: 20,
        ),
        StockLevelItem(
          productId: 'prod-2',
          name: 'White Cap',
          category: 'beer',
          quantity: 5,
          reorderLevel: 10,
        ),
      ];

      mockOpenTabs = [
        OpenTabItem(
          id: 'tab-1',
          name: 'Table 5',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          totalItems: 6,
        ),
      ];

      mockLowStockAlerts = [
        LowStockAlertItem(
          productId: 'prod-2',
          name: 'White Cap',
          quantity: 5,
          reorderLevel: 10,
        ),
        LowStockAlertItem(
          productId: 'prod-3',
          name: 'Gilbey\'s Gin',
          quantity: 0,
          reorderLevel: 5,
        ),
      ];

      mockTopProducts = [
        TopProductItem(
          productId: 'prod-1',
          name: 'Tusker Lager',
          unitsSold: 120,
        ),
      ];
    });

    testWidgets('renders all dashboard sections correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardMetricsProvider.overrideWithValue(mockMetrics),
            recentSalesProvider.overrideWith(
              (ref) => Stream.value(mockRecentSales),
            ),
            stockLevelsProvider.overrideWith(
              (ref) => Stream.value(mockStockLevels),
            ),
            openTabsProvider.overrideWith((ref) => Stream.value(mockOpenTabs)),
            lowStockAlertsProvider.overrideWith(
              (ref) => Stream.value(mockLowStockAlerts),
            ),
            topProductsProvider.overrideWith(
              (ref) => Stream.value(mockTopProducts),
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      // Wait for stream updates
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Dashboard'), findsOneWidget);

      // Verify 3 Stat Cards
      expect(find.byType(StatCard), findsNWidgets(3));
      expect(find.text('Revenue Today'), findsOneWidget);
      expect(find.text('KES 1,250'), findsOneWidget); // 125000 cents
      expect(find.text('Sales Count'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Expected Cash'), findsOneWidget);
      expect(find.text('KES 800'), findsOneWidget); // 80000 cents

      // Verify Cards by Title
      expect(find.text('Recent Sales'), findsOneWidget);
      expect(find.text('Stock Levels'), findsOneWidget);
      expect(find.text('Open Tabs'), findsOneWidget);
      expect(find.text('Low Stock Alerts'), findsOneWidget);
      expect(find.text('Top Products'), findsOneWidget);

      // Verify Recent Sales List details
      expect(find.text('Tusker Lager x2 (+1 more)'), findsOneWidget);
      expect(find.text('MPESA'), findsOneWidget);
      expect(find.text('KES 1,500'), findsOneWidget); // 150000 cents

      // Verify Stock Levels Details
      expect(find.text('White Cap'), findsNWidgets(2));
      expect(find.text('5 beer'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

      // Verify Open Tabs List details (Receipt icon, "Table 5", "Opened 45 min ago • 6 items")
      expect(find.text('Table 5'), findsOneWidget);
      expect(find.text('Opened 45 min ago • 6 items'), findsOneWidget);

      // Verify Low Stock Alerts details (no trailing count, status indicator check)
      expect(find.text('Gilbey\'s Gin'), findsOneWidget);

      // Verify Top Products details (rank, title, "120 units")
      expect(find.text('1'), findsOneWidget);
      expect(find.text('120 units'), findsOneWidget);
    });

    testWidgets('renders empty/loading states correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardMetricsProvider.overrideWithValue(
              DashboardMetrics(
                todayRevenue: 0,
                todaySalesCount: 0,
                expectedCash: 0,
                revenueTrend: const [0, 0, 0, 0, 0],
                salesCountTrend: const [0, 0, 0, 0, 0],
                cashTrend: const [0, 0, 0, 0, 0],
              ),
            ),
            recentSalesProvider.overrideWith((ref) => Stream.value([])),
            stockLevelsProvider.overrideWith((ref) => Stream.value([])),
            openTabsProvider.overrideWith((ref) => Stream.value([])),
            lowStockAlertsProvider.overrideWith((ref) => Stream.value([])),
            topProductsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No recent sales'), findsOneWidget);
      expect(find.text('No stock data'), findsOneWidget);
      expect(find.text('No open tabs'), findsOneWidget);
      expect(find.text('All stock levels are good'), findsOneWidget);
      expect(find.text('No sales records yet'), findsOneWidget);
    });
  });
}
