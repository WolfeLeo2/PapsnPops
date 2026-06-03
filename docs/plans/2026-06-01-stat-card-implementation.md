# Reusable Stat Card Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a beautiful, reusable `StatCard` widget that displays metric titles, values, trend indicators (up/down arrow, percentage, comparison label), and a minimalist background/overlay sparkline representing performance trend data.

**Architecture:** The card is built as a Material 3 container using dynamic theme values (`surfaceContainer` background, `outline` border). It uses `Column` to align content vertically, with the sparkline chart positioned cleanly at the bottom using a fixed height to prevent text overlaps.

**Tech Stack:** Flutter, `fl_chart`, `phosphor_flutter`.

---

### Task 1: Render Title and Value

**Files:**
- Create: `lib/shared/widgets/stat_card.dart`
- Create: `test/stat_card_test.dart`

**Step 1: Write the failing test**
Create `test/stat_card_test.dart` with a test that attempts to render `StatCard` with a title and value, and expects to find them on screen:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/shared/widgets/stat_card.dart';

void main() {
  group('StatCard Basic Rendering', () {
    testWidgets('renders title and value correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: 'KES 48,240',
            ),
          ),
        ),
      );

      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('KES 48,240'), findsOneWidget);
    });
  });
}
```

**Step 2: Run test to verify it fails**
Run: `flutter test test/stat_card_test.dart`
Expected: Compilation failure because `StatCard` does not exist.

**Step 3: Write minimal implementation**
Create `lib/shared/widgets/stat_card.dart` with the minimal widget declaration:
```dart
import 'package:flutter/material.dart';

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
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.headlineMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**
Run: `flutter test test/stat_card_test.dart`
Expected: PASS

**Step 5: Commit**
Run:
```bash
git add lib/shared/widgets/stat_card.dart test/stat_card_test.dart
git commit -m "feat(shared): implement basic StatCard title and value rendering"
```

---

### Task 2: Render Trend Indicators

**Files:**
- Modify: `test/stat_card_test.dart`
- Modify: `lib/shared/widgets/stat_card.dart`

**Step 1: Write the failing test**
Add tests to verify trend indicator rendering (percentage, trend label, up/down icons):
```dart
    testWidgets('renders positive trend indicator correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: 'KES 48,240',
              trendPercentage: 12.4,
              isPositiveTrend: true,
              trendLabel: 'vs yesterday',
            ),
          ),
        ),
      );

      expect(find.text('+12.4%'), findsOneWidget);
      expect(find.text('vs yesterday'), findsOneWidget);
      
      // Verification of trend up icon
      final iconFinder = find.byType(PhosphorIcon);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('renders negative trend indicator correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: 'KES 48,240',
              trendPercentage: 3.2,
              isPositiveTrend: false,
              trendLabel: 'vs yesterday',
            ),
          ),
        ),
      );

      expect(find.text('-3.2%'), findsOneWidget);
      expect(find.text('vs yesterday'), findsOneWidget);
    });
```

**Step 2: Run test to verify it fails**
Run: `flutter test test/stat_card_test.dart`
Expected: FAIL because trend indicators are not implemented (finds 0 widgets instead of 1).

**Step 3: Write minimal implementation**
Modify `lib/shared/widgets/stat_card.dart` to add the trend indicator logic using `PhosphorIcon` from `package:phosphor_flutter`.
Use the `AppColors.success` color for positive trends, and `cs.error` (or `AppColors.error`) for negative trends.
```dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:paps_n_pops/core/theme/app_colors.dart';

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

    Color? trendColor;
    IconData? trendIcon;
    String trendPrefix = '';

    if (isPositiveTrend != null) {
      trendColor = isPositiveTrend! ? AppColors.success : cs.error;
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
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
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
                  PhosphorIcon(
                    trendIcon,
                    color: trendColor,
                    size: 16,
                  ),
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
                  Text(
                    trendLabel!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**
Run: `flutter test test/stat_card_test.dart`
Expected: PASS

**Step 5: Commit**
Run:
```bash
git add lib/shared/widgets/stat_card.dart test/stat_card_test.dart
git commit -m "feat(shared): implement trend indicator rendering in StatCard"
```

---

### Task 3: Render Sparkline Chart

**Files:**
- Modify: `test/stat_card_test.dart`
- Modify: `lib/shared/widgets/stat_card.dart`

**Step 1: Write the failing test**
Add a test verifying that `LineChart` is rendered when `sparklineData` is passed:
```dart
    testWidgets('renders sparkline chart when sparklineData is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: 'KES 48,240',
              sparklineData: [10, 15, 8, 20, 18, 25],
            ),
          ),
        ),
      );

      // Verify that LineChart is rendered
      expect(find.byType(LineChart), findsOneWidget);
    });
```

**Step 2: Run test to verify it fails**
Run: `flutter test test/stat_card_test.dart`
Expected: Compilation error due to missing `LineChart` import or FAIL because `LineChart` widget is not found.

**Step 3: Write minimal implementation**
Modify `lib/shared/widgets/stat_card.dart` to implement the sparkline at the bottom using `LineChart` from `fl_chart`. Make sure it uses:
- Curved line (`isCurved: true`)
- No visible dots (`show: false` in `FlDotData`)
- Compact height (40px)
- Dynamic colors: primary (accent) for default, or success/error based on `isPositiveTrend`.
- Fading gradient under the line.
```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:paps_n_pops/core/theme/app_colors.dart';

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
      trendColor = isPositiveTrend! ? AppColors.success : cs.error;
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
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
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
                  PhosphorIcon(
                    trendIcon,
                    color: trendColor,
                    size: 16,
                  ),
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
                  Text(
                    trendLabel!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
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
                            lineColor.withOpacity(0.3),
                            lineColor.withOpacity(0.0),
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
```

**Step 4: Run test to verify it passes**
Run: `flutter test test/stat_card_test.dart`
Expected: PASS

**Step 5: Commit**
Run:
```bash
git add lib/shared/widgets/stat_card.dart test/stat_card_test.dart
git commit -m "feat(shared): implement sparkline chart in StatCard using fl_chart"
```
