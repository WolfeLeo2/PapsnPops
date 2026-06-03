import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/currency.dart';
import '../../core/extensions/color_scheme_extensions.dart';
import '../../shared/widgets/stat_card.dart';
import 'dashboard_provider.dart';
import 'widgets/dashboard_card.dart';
import '../../core/utils/stock_display.dart';
import '../stock/stock_provider.dart';

import '../../shared/widgets/app_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final todayStr = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    // Watch providers
    final metrics = ref.watch(dashboardMetricsProvider);
    final recentSalesAsync = ref.watch(recentSalesProvider);
    final stockLevelsAsync = ref.watch(stockLevelsProvider);
    final openTabsAsync = ref.watch(openTabsProvider);
    final lowStockAlertsAsync = ref.watch(lowStockAlertsProvider);
    final topProductsAsync = ref.watch(topProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        leading: Builder(
          builder: (context) {
            final isDesktop = MediaQuery.of(context).size.width >= 600;
            return IconButton(
              icon: Icon(isDesktop ? Icons.menu_open : Icons.menu),
              onPressed: () {
                if (isDesktop) {
                  ref.read(railExpandedProvider.notifier).toggle();
                } else {
                  context
                      .findRootAncestorStateOfType<ScaffoldState>()
                      ?.openDrawer();
                }
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Header
            Text(
              todayStr,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Metrics Row (3 StatCards)
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final isWide = width > 700;

                final cards = [
                  StatCard(
                    title: 'Revenue Today',
                    value: CurrencyHelper.format(metrics.todayRevenue),
                    sparklineData: metrics.revenueTrend,
                  ),
                  StatCard(
                    title: 'Sales Count',
                    value: '${metrics.todaySalesCount}',
                    sparklineData: metrics.salesCountTrend,
                  ),
                  StatCard(
                    title: 'Expected Cash',
                    value: CurrencyHelper.format(metrics.expectedCash),
                    sparklineData: metrics.cashTrend,
                  ),
                ];

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[1]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[2]),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cards[0],
                      const SizedBox(height: 16),
                      cards[1],
                      const SizedBox(height: 16),
                      cards[2],
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Grid Layout (Left Column & Right Column)
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 600;

                final leftColumnWidgets = [
                  // Recent Sales
                  DashboardCard(
                    title: 'Recent Sales',
                    child: recentSalesAsync.when(
                      data: (sales) {
                        if (sales.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No recent sales'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sales.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sale = sales[index];
                            final title = sale.items.isNotEmpty
                                ? '${sale.items.first.productName} x${sale.items.first.quantity}${sale.items.length > 1 ? " (+${sale.items.length - 1} more)" : ""}'
                                : 'No products';
                            final time = DateFormat.jm().format(sale.createdAt);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: cs.primaryContainer,
                                child: Text(
                                  sale.items.isNotEmpty
                                      ? sale.items.first.productName
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'S',
                                  style: tt.titleSmall?.copyWith(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                title,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    time,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sale.paymentMethod.toUpperCase(),
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                CurrencyHelper.format(sale.totalAmount),
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stock Levels
                  DashboardCard(
                    title: 'Stock Levels',
                    child: stockLevelsAsync.when(
                      data: (levels) {
                        if (levels.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No stock data'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: levels.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final level = levels[index];
                            final isLow = level.quantity <= level.reorderLevel;
                            final progress = level.reorderLevel > 0
                                ? (level.quantity / (level.reorderLevel * 2.0))
                                      .clamp(0.0, 1.0)
                                : (level.quantity / 100.0).clamp(0.0, 1.0);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        level.name,
                                        style: tt.bodyMedium?.copyWith(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final productsAsync = ref.watch(
                                          productsProvider,
                                        );
                                        final products =
                                            productsAsync.value ?? [];
                                        final pv = products
                                            .where(
                                              (p) =>
                                                  p.product.id ==
                                                  level.productId,
                                            )
                                            .firstOrNull;
                                        final text = pv != null
                                            ? StockDisplay.format(
                                                pv.product,
                                                level.quantity,
                                                pv.variants,
                                              )
                                            : '${level.quantity} ${level.category}';

                                        return Text(
                                          text,
                                          style: tt.bodySmall?.copyWith(
                                            color: isLow
                                                ? cs.error
                                                : cs.onSurfaceVariant,
                                            fontWeight: isLow
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: cs.outline,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isLow ? cs.error : cs.success,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ];

                final rightColumnWidgets = [
                  // Open Tabs
                  DashboardCard(
                    title: 'Open Tabs',
                    child: openTabsAsync.when(
                      data: (tabs) {
                        if (tabs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No open tabs'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tabs.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tab = tabs[index];
                            final diff = DateTime.now().difference(
                              tab.createdAt,
                            );
                            final timeAgo = diff.inMinutes < 60
                                ? '${diff.inMinutes} min ago'
                                : diff.inHours < 24
                                ? '${diff.inHours} hr ago'
                                : '${diff.inDays} days ago';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                PhosphorIconsRegular.receipt,
                                color: cs.primary,
                                size: 24,
                              ),
                              title: Text(
                                tab.name,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Opened $timeAgo • ${tab.totalItems} items',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Low Stock Alerts
                  DashboardCard(
                    title: 'Low Stock Alerts',
                    child: lowStockAlertsAsync.when(
                      data: (alerts) {
                        if (alerts.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('All stock levels are good'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: alerts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final alert = alerts[index];
                            final color = alert.quantity == 0
                                ? cs.error
                                : cs.warning;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                alert.name,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Consumer(
                                builder: (context, ref, child) {
                                  final productsAsync = ref.watch(
                                    productsProvider,
                                  );
                                  final products = productsAsync.value ?? [];
                                  final pv = products
                                      .where(
                                        (p) => p.product.id == alert.productId,
                                      )
                                      .firstOrNull;
                                  final text = pv != null
                                      ? StockDisplay.format(
                                          pv.product,
                                          alert.quantity,
                                          pv.variants,
                                        )
                                      : '${alert.quantity} units left';

                                  return Text(
                                    text,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top Products
                  DashboardCard(
                    title: 'Top Products',
                    child: topProductsAsync.when(
                      data: (topProducts) {
                        if (topProducts.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No sales records yet'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProducts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = topProducts[index];
                            final rank = index + 1;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$rank',
                                  style: tt.labelMedium?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Consumer(
                                builder: (context, ref, child) {
                                  final productsAsync = ref.watch(
                                    productsProvider,
                                  );
                                  final products = productsAsync.value ?? [];
                                  final pv = products
                                      .where(
                                        (p) =>
                                            p.product.id == product.productId,
                                      )
                                      .firstOrNull;
                                  final text = pv != null
                                      ? StockDisplay.format(
                                          pv.product,
                                          product.unitsSold,
                                          pv.variants,
                                        )
                                      : '${product.unitsSold} units';

                                  return Text(
                                    text,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ];

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: leftColumnWidgets,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rightColumnWidgets,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...leftColumnWidgets,
                      const SizedBox(height: 24),
                      ...rightColumnWidgets,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
