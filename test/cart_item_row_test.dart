import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paps_n_pops/features/pos/widgets/cart_item_row.dart';
import 'package:paps_n_pops/domain/models/cart_item.dart';
import 'package:paps_n_pops/domain/models/product.dart';
import 'package:paps_n_pops/domain/models/product_variant.dart';
import 'package:paps_n_pops/core/utils/currency.dart';

void main() {
  group('CartItemRow Widget Tests', () {
    late Product mockProduct;
    late ProductVariant mockVariant;

    setUp(() {
      mockProduct = Product(
        id: 'p-1',
        name: 'Tusker Lager',
        categoryId: 'cat-beer',
        reorderLevel: 10,
        isActive: true,
        createdAt: DateTime.now(),
        baseUnit: 'bottle',
        containerSize: 1,
        containerName: 'Bottle',
      );

      mockVariant = ProductVariant(
        id: 'v-1',
        productId: 'p-1',
        name: 'Single Bottle',
        unitLabel: 'bottle',
        conversionFactor: 1,
        sellingPrice: 25000, // KES 250.00
        costPrice: 18000,
        isActive: true,
        isDefault: true,
        createdAt: DateTime.now(),
      );
    });

    testWidgets('renders product details and totals correctly without discount', (
      WidgetTester tester,
    ) async {
      final cartItem = CartItem(
        product: mockProduct,
        variant: mockVariant,
        quantity: 2,
        discountAmount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CartItemRow(item: cartItem),
            ),
          ),
        ),
      );

      // Verify product name and variant name
      expect(find.text('Tusker Lager'), findsOneWidget);
      expect(find.text('Single Bottle'), findsOneWidget);

      // Verify quantity stepper shows 2
      expect(find.text('2'), findsOneWidget);

      // Verify total price (KES 500)
      expect(find.text(CurrencyHelper.format(50000)), findsOneWidget);
    });

    testWidgets('renders line-through subtotal and promotional discount amount', (
      WidgetTester tester,
    ) async {
      final cartItem = CartItem(
        product: mockProduct,
        variant: mockVariant,
        quantity: 3,
        discountAmount: 5000, // KES 50.00 discount
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CartItemRow(item: cartItem),
            ),
          ),
        ),
      );

      // Subtotal before discount: 3 * 25000 = 75000 (KES 750)
      // Line total after discount: 75000 - 5000 = 70000 (KES 700)
      expect(find.text(CurrencyHelper.format(75000)), findsOneWidget);
      expect(find.text(CurrencyHelper.format(70000)), findsOneWidget);
    });
  });
}
