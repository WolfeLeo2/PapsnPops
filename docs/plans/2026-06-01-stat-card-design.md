# Phase 2 Task 2 Design: Reusable Stat Card & Sparkline Charts

## Overview
This design covers the implementation of the `StatCard` widget, a reusable dashboard component that displays key performance metrics (e.g., Revenue, Sale Volume, Active Tabs) along with dynamic trend indicators and a mini background/overlay sparkline representing recent performance trends.

## Components to Build

### 1. StatCard Widget (`lib/shared/widgets/stat_card.dart`)
- **Widget Interface**:
  ```dart
  class StatCard extends StatelessWidget {
    final String title;
    final String value;
    final double? trendPercentage; // e.g. 12.4
    final bool? isPositiveTrend;
    final String? trendLabel; // e.g. "vs yesterday"
    final List<double>? sparklineData; // list of coordinates to plot
    
    const StatCard({
      super.key,
      required this.title,
      required this.value,
      this.trendPercentage,
      this.isPositiveTrend,
      this.trendLabel,
      this.sparklineData,
    });
  }
  ```
- **Styling**:
  - Background: `Theme.of(context).colorScheme.surfaceContainer`
  - Border: Border.all with `Theme.of(context).colorScheme.outline`
  - Padding: Standard outer padding (e.g., 16px) to maintain a spacious layout
  - Layout: `Column` with crossAxisAlignment set to `CrossAxisAlignment.start`
  - Typography:
    - Title: `Theme.of(context).textTheme.labelMedium` or `bodyMedium` with `onSurfaceVariant`
    - Value: `Theme.of(context).textTheme.headlineMedium` or `headlineSmall`
    - Trend label: `Theme.of(context).textTheme.bodySmall`
- **Trend Indicator**:
  - Displays a row of:
    - Trend Icon: Upward diagonal arrow for positive (`PhosphorIconsRegular.trendUp`), downward diagonal for negative (`PhosphorIconsRegular.trendDown`).
    - Trend Percentage text (e.g. `+12.4%` or `-3.2%`).
    - Trend comparison label (e.g., `vs yesterday`).
  - Colors:
    - Positive trend: success color (`AppColors.success` / custom context success if resolved, or green).
    - Negative trend: error color (`Theme.of(context).colorScheme.error` or `AppColors.error`).
    - No trend specified: default text/icon style.
- **Sparkline Chart (`fl_chart` implementation)**:
  - Nested at the bottom of the card with a fixed height (e.g., 40px).
  - Component configuration for `LineChart`:
    - `gridData`: `const FlGridData(show: false)`
    - `titlesData`: `const FlTitlesData(show: false)`
    - `borderData`: `FlBorderData(show: false)`
    - `minX`, `maxX`, `minY`, `maxY` auto-computed from `sparklineData` points.
  - Data styling:
    - Curve: `isCurved: true`
    - Dots: `const FlDotData(show: false)`
    - Solid line color: Matches the trend. If `isPositiveTrend == true`, use green/success color. If `isPositiveTrend == false`, use red/error color. Else, use the primary theme color.
    - Below-bar gradient: `BarAreaData` with `show: true` and gradient fading from the line color with low opacity (e.g., 0.3) to transparent.

### 2. Widget Tests (`test/stat_card_test.dart`)
- Verify that `StatCard` renders correctly with various inputs:
  - Simple title and value.
  - Positive trend and label.
  - Negative trend and label.
  - With and without sparkline data.

## Verification
- Run `flutter test test/stat_card_test.dart` to verify successful rendering of widgets, texts, and icons.
- Run static analysis via `flutter analyze` to ensure there are no compilation errors or warnings.
