import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paps_n_pops/features/pos/widgets/payment_method_selector.dart';
import 'package:paps_n_pops/features/pos/pos_provider.dart';

void main() {
  group('PaymentMethodSelector Widget Tests', () {
    testWidgets('renders all three payment methods (Cash, M-Pesa, Card)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentMethodSelector(),
            ),
          ),
        ),
      );

      // Verify all payment methods are rendered
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('M-Pesa'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('initial selection defaults to Cash', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentMethodSelector(),
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(PaymentMethodSelector));
      final container = ProviderScope.containerOf(context);

      // Verify that the default value is 'cash'
      expect(container.read(selectedPaymentMethodProvider), equals('cash'));
    });

    testWidgets('tapping M-Pesa updates the provider state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentMethodSelector(),
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(PaymentMethodSelector));
      final container = ProviderScope.containerOf(context);

      // Initial state should be cash
      expect(container.read(selectedPaymentMethodProvider), equals('cash'));

      // Tap on M-Pesa
      await tester.tap(find.text('M-Pesa'));
      await tester.pumpAndSettle();

      // State should be updated to mpesa
      expect(container.read(selectedPaymentMethodProvider), equals('mpesa'));

      // Tap on Card
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();

      // State should be updated to card
      expect(container.read(selectedPaymentMethodProvider), equals('card'));
    });
  });
}
