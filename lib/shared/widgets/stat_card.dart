import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:paps_n_pops/core/extensions/color_scheme_extensions.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double? trendPercentage;
  final bool? isPositiveTrend;
  final String? trendLabel;
  final List<double>? sparklineData;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.trendPercentage,
    this.isPositiveTrend,
    this.trendLabel,
    this.sparklineData,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color lineColor = cs.primary;
    Color? trendColor;
    IconData? trendIcon;
    String trendPrefix = '';

    if (isPositiveTrend != null) {
      trendColor = isPositiveTrend! ? cs.success : cs.error;
      lineColor = trendColor;
      trendIcon = isPositiveTrend!
          ? PhosphorIconsRegular.trendUp
          : PhosphorIconsRegular.trendDown;
      trendPrefix = isPositiveTrend! ? '+' : '-';
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.headlineMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trendPercentage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trendIcon != null) ...[
                  PhosphorIcon(trendIcon, color: trendColor, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$trendPrefix${trendPercentage!.toStringAsFixed(1)}%',
                  style: tt.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trendLabel != null) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trendLabel!,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (sparklineData != null && sparklineData!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (sparklineData!.length - 1).toDouble(),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sparklineData!
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withValues(alpha: 0.3),
                            lineColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
