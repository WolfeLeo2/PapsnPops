import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:paps_n_pops/shared/widgets/stat_card.dart';

void main() {
  group('StatCard Basic Rendering', () {
    testWidgets('renders title and value correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(title: 'Revenue', value: 'KES 48,240'),
          ),
        ),
      );

      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('KES 48,240'), findsOneWidget);
    });

    testWidgets('renders positive trend indicator correctly', (
      WidgetTester tester,
    ) async {
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
      expect(find.byType(PhosphorIcon), findsOneWidget);
    });

    testWidgets('renders negative trend indicator correctly', (
      WidgetTester tester,
    ) async {
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
      expect(find.byType(PhosphorIcon), findsOneWidget);
    });

    testWidgets('renders sparkline chart when sparklineData is provided', (
      WidgetTester tester,
    ) async {
      // Small screen size to avoid fl_chart layout warnings if any
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Revenue',
              value: 'KES 48,240',
              sparklineData: [10.0, 15.0, 8.0, 20.0, 18.0, 25.0],
            ),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
