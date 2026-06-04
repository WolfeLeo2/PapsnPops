import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/core/utils/promotion_engine.dart';
import 'package:paps_n_pops/domain/models/cart_item.dart';
import 'package:paps_n_pops/domain/models/product.dart';
import 'package:paps_n_pops/domain/models/product_variant.dart';
import 'package:paps_n_pops/domain/models/promotion.dart';

void main() {
  group('PromotionEngine Tests', () {
    final now = DateTime(2026, 6, 4, 18, 0); // Thursday, 6:00 PM

    // Create shared helper models
    final productBeer = Product(
      id: 'prod-beer',
      name: 'Tusker Lager',
      categoryId: 'cat-beer',
      createdAt: DateTime.now(),
    );

    final variantBeer = ProductVariant(
      id: 'var-beer',
      productId: 'prod-beer',
      name: 'Bottle',
      unitLabel: 'btl',
      conversionFactor: 1,
      sellingPrice: 20000, // KES 200.00
      costPrice: 15000,
      createdAt: DateTime.now(),
    );

    test('Percentage Discount Promotion', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 2), // Subtotal: 40000
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-1',
          name: '10% Off Beer',
          type: 'percentage',
          value: 10,
          targetType: 'category',
          targetValue: 'cat-beer',
          isActive: true,
          isHappyHour: false,
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now,
      );

      expect(results.length, 1);
      expect(results[0].promotion.id, 'promo-1');
      expect(results[0].variantId, 'var-beer');
      expect(results[0].discountAmount, 4000); // 10% of 40000 = 4000
    });

    test('Fixed Discount Promotion', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 3), // Subtotal: 60000
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-2',
          name: 'KES 20 Off Per Beer',
          type: 'fixed',
          value: 2000, // KES 20.00
          targetType: 'product',
          targetValue: 'prod-beer',
          isActive: true,
          isHappyHour: false,
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now,
      );

      expect(results.length, 1);
      expect(results[0].promotion.id, 'promo-2');
      expect(results[0].variantId, 'var-beer');
      expect(results[0].discountAmount, 6000); // 2000 * 3 = 6000
    });

    test('Happy Hour Promotion - Active Time', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1), // Subtotal: 20000
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-happy',
          name: 'Happy Hour Beer',
          type: 'fixed',
          value: 5000,
          targetType: 'all',
          isActive: true,
          isHappyHour: true,
          happyHourStart: '17:00',
          happyHourEnd: '20:00',
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now, // 18:00 (inside range)
      );

      expect(results.length, 1);
      expect(results[0].discountAmount, 5000);
    });

    test('Happy Hour Promotion - Inactive Time', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1),
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-happy',
          name: 'Happy Hour Beer',
          type: 'fixed',
          value: 5000,
          targetType: 'all',
          isActive: true,
          isHappyHour: true,
          happyHourStart: '12:00',
          happyHourEnd: '15:00',
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now, // 18:00 (outside range)
      );

      expect(results.isEmpty, true);
    });

    test('Weekday Checks - Active Day', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1),
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-weekday',
          name: 'Thursday Discount',
          type: 'percentage',
          value: 10,
          targetType: 'all',
          isActive: true,
          isHappyHour: false,
          activeDays: ['thursday'],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now, // Thursday
      );

      expect(results.length, 1);
    });

    test('Weekday Checks - Inactive Day', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1),
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-weekday',
          name: 'Friday Discount',
          type: 'percentage',
          value: 10,
          targetType: 'all',
          isActive: true,
          isHappyHour: false,
          activeDays: ['friday'],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now, // Thursday
      );

      expect(results.isEmpty, true);
    });

    test('Date Range Checks - Active Dates', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1),
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-dates',
          name: 'June Promotion',
          type: 'percentage',
          value: 10,
          targetType: 'all',
          isActive: true,
          isHappyHour: false,
          validFrom: DateTime(2026, 6, 1),
          validUntil: DateTime(2026, 6, 30),
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now, // June 4, 2026
      );

      expect(results.length, 1);
    });

    test('Date Range Checks - Expired Date', () {
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1),
      ];

      final activePromotions = [
        Promotion(
          id: 'promo-dates',
          name: 'May Promotion',
          type: 'percentage',
          value: 10,
          targetType: 'all',
          isActive: true,
          isHappyHour: false,
          validFrom: DateTime(2026, 5, 1),
          validUntil: DateTime(2026, 5, 31),
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now, // June 4, 2026
      );

      expect(results.isEmpty, true);
    });

    test('Stacking and Capping Promotion Discounts', () {
      // 1 Tusker Beer: sellingPrice is 20000 (KES 200)
      final cartItems = [
        CartItem(product: productBeer, variant: variantBeer, quantity: 1),
      ];

      // Two promotions stack.
      // Promo 1: Fixed discount of KES 150 (15000)
      // Promo 2: Fixed discount of KES 80 (8000)
      // Total potential: 15000 + 8000 = 23000
      // Max possible discount is capped at subtotal: 20000
      final activePromotions = [
        Promotion(
          id: 'promo-heavy-1',
          name: 'Heavy Discount 1',
          type: 'fixed',
          value: 15000,
          targetType: 'all',
          isActive: true,
          isHappyHour: false,
          activeDays: [],
          createdAt: DateTime.now(),
        ),
        Promotion(
          id: 'promo-heavy-2',
          name: 'Heavy Discount 2',
          type: 'fixed',
          value: 8000,
          targetType: 'all',
          isActive: true,
          isHappyHour: false,
          activeDays: [],
          createdAt: DateTime.now(),
        ),
      ];

      final results = PromotionEngine.calculatePromotions(
        cartItems: cartItems,
        activePromotions: activePromotions,
        now: now,
      );

      expect(results.length, 2);
      expect(results[0].discountAmount, 15000);
      expect(results[1].discountAmount, 5000); // 20000 (subtotal) - 15000 = 5000 remaining
    });
  });
}
