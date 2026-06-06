import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency.dart';
import '../../../shared/widgets/stat_card.dart';
import '../reports_provider.dart';

class SalesSummaryTab extends ConsumerWidget {
  const SalesSummaryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(salesSummaryProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── KPI Grid ──────────────────────────────────────────────────
          _KpiGrid(summary: summary, isDesktop: isDesktop),

          const SizedBox(height: 24),

          // ── Revenue by Payment Method ─────────────────────────────────
          Text('Revenue by Payment Method', style: tt.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _PaymentBar(
                  label: 'Cash',
                  amount: summary.revenueByPaymentMethod['cash'] ?? 0,
                  total: summary.totalRevenue,
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(height: 14),
                _PaymentBar(
                  label: 'M-Pesa',
                  amount: summary.revenueByPaymentMethod['mpesa'] ?? 0,
                  total: summary.totalRevenue,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 14),
                _PaymentBar(
                  label: 'Card',
                  amount: summary.revenueByPaymentMethod['card'] ?? 0,
                  total: summary.totalRevenue,
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Hourly Revenue Chart ───────────────────────────────────────
          Text('Hourly Revenue', style: tt.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _HourlyChart(
              data: summary.hourlyRevenue,
              barColor: cs.primary,
              gridColor: cs.outline.withAlpha(60),
              isDesktop: isDesktop,
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final SalesSummary summary;
  final bool isDesktop;

  const _KpiGrid({required this.summary, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        title: 'Total Revenue',
        value: CurrencyHelper.format(summary.totalRevenue),
      ),
      StatCard(title: 'Sales Count', value: summary.totalSalesCount.toString()),
      StatCard(
        title: 'Gross Profit',
        value: CurrencyHelper.format(summary.grossProfit),
      ),
      StatCard(
        title: 'Avg Sale Value',
        value: CurrencyHelper.format(summary.averageSaleValue),
      ),
    ];

    if (isDesktop) {
      return Row(
        children:
            cards
                .map((c) => Expanded(child: c))
                .expand((w) => [w, const SizedBox(width: 12)])
                .toList()
              ..removeLast(),
      );
    }

    // 2×2 grid on mobile
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }
}

// ── Payment Method Bar ────────────────────────────────────────────────────

class _PaymentBar extends StatelessWidget {
  final String label;
  final int amount;
  final int total;
  final Color color;

  const _PaymentBar({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final percent = total == 0 ? 0.0 : amount / total;
    final pctStr = (percent * 100).toStringAsFixed(1);
    final amtStr = CurrencyHelper.format(amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: tt.labelLarge),
            Text(
              '$amtStr  ($pctStr%)',
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            color: color,
            backgroundColor: cs.outline.withAlpha(50),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ── Hourly Bar Chart ──────────────────────────────────────────────────────

class _HourlyChart extends StatelessWidget {
  final List<double> data;
  final Color barColor;
  final Color gridColor;
  final bool isDesktop;

  const _HourlyChart({
    required this.data,
    required this.barColor,
    required this.gridColor,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxY == 0 ? 1000.0 : maxY * 1.25;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: effectiveMax,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x;
              final suffix = hour < 12 ? 'AM' : 'PM';
              final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
              final amtStr = CurrencyHelper.format(rod.toY.toInt());
              return BarTooltipItem(
                '$h:00 $suffix\n$amtStr',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                // Show labels every 4 hours: 0, 4, 8, 12, 16, 20
                if (hour % 4 != 0) return const SizedBox.shrink();
                final suffix = hour < 12 ? 'AM' : 'PM';
                final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$h$suffix', style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        barGroups: List.generate(24, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: data[i] > 0 ? barColor : Colors.transparent,
                width: isDesktop ? 14 : 6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
