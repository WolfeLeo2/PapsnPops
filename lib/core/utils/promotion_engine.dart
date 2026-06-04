import 'dart:math';
import '../../domain/models/cart_item.dart';
import '../../domain/models/promotion.dart';
import '../../domain/models/applied_promotion.dart';

class PromotionEngine {
  static List<AppliedPromotion> calculatePromotions({
    required List<CartItem> cartItems,
    required List<Promotion> activePromotions,
    required DateTime now,
  }) {
    final List<AppliedPromotion> appliedPromotions = [];
    final Map<String, int> accumulatedDiscounts = {}; // variantId -> accumulatedDiscountAmount

    // Helper to check if a promotion is currently active
    bool isPromotionActive(Promotion promotion, DateTime now) {
      if (!promotion.isActive) return false;

      // 1. Date range check
      final nowDate = DateTime(now.year, now.month, now.day);
      if (promotion.validFrom != null) {
        final fromDate = DateTime(
          promotion.validFrom!.year,
          promotion.validFrom!.month,
          promotion.validFrom!.day,
        );
        if (nowDate.isBefore(fromDate)) return false;
      }
      if (promotion.validUntil != null) {
        final untilDate = DateTime(
          promotion.validUntil!.year,
          promotion.validUntil!.month,
          promotion.validUntil!.day,
        );
        if (nowDate.isAfter(untilDate)) return false;
      }

      // 2. Weekday check
      if (promotion.activeDays.isNotEmpty) {
        final weekdaysMap = {
          1: ['monday', 'mon'],
          2: ['tuesday', 'tue'],
          3: ['wednesday', 'wed'],
          4: ['thursday', 'thu'],
          5: ['friday', 'fri'],
          6: ['saturday', 'sat'],
          7: ['sunday', 'sun'],
        };
        final todayStrings = weekdaysMap[now.weekday] ?? [];
        final hasDay = promotion.activeDays.any(
          (day) => todayStrings.contains(day.trim().toLowerCase()),
        );
        if (!hasDay) return false;
      }

      // 3. Happy Hour check
      if (promotion.isHappyHour) {
        int? timeStringToMinutes(String? timeStr) {
          if (timeStr == null || timeStr.isEmpty) return null;
          final parts = timeStr.split(':');
          if (parts.isEmpty) return null;
          final hour = int.tryParse(parts[0]);
          if (hour == null) return null;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          return hour * 60 + minute;
        }

        final startMinutes = timeStringToMinutes(promotion.happyHourStart);
        final endMinutes = timeStringToMinutes(promotion.happyHourEnd);
        if (startMinutes != null && endMinutes != null) {
          final nowMinutes = now.hour * 60 + now.minute;
          if (startMinutes <= endMinutes) {
            if (nowMinutes < startMinutes || nowMinutes > endMinutes) {
              return false;
            }
          } else {
            // Overnight range
            if (nowMinutes < startMinutes && nowMinutes > endMinutes) {
              return false;
            }
          }
        }
      }

      return true;
    }

    // Helper to check if a cart item matches the promotion targets
    bool isItemTargeted(CartItem item, Promotion promotion) {
      final targetType = promotion.targetType.toLowerCase();
      if (targetType == 'all') {
        return true;
      } else if (targetType == 'category') {
        return item.product.categoryId == promotion.targetValue;
      } else if (targetType == 'product') {
        return item.product.id == promotion.targetValue ||
            item.variant.productId == promotion.targetValue;
      }
      return false;
    }

    // Evaluate promotions
    for (final promo in activePromotions) {
      if (!isPromotionActive(promo, now)) continue;

      for (final item in cartItems) {
        if (!isItemTargeted(item, promo)) continue;

        // Calculate potential discount
        int potentialDiscount = 0;
        if (promo.type == 'percentage') {
          potentialDiscount = (item.subtotal * promo.value) ~/ 100;
        } else if (promo.type == 'fixed') {
          potentialDiscount = promo.value * item.quantity;
        }

        if (potentialDiscount <= 0) continue;

        final variantId = item.variant.id;
        final currentAccumulated = accumulatedDiscounts[variantId] ?? 0;
        final remainingSubtotal = item.subtotal - currentAccumulated;

        if (remainingSubtotal <= 0) continue;

        final actualDiscount = min(potentialDiscount, remainingSubtotal);
        if (actualDiscount > 0) {
          appliedPromotions.add(
            AppliedPromotion(
              promotion: promo,
              variantId: variantId,
              discountAmount: actualDiscount,
            ),
          );
          accumulatedDiscounts[variantId] = currentAccumulated + actualDiscount;
        }
      }
    }

    return appliedPromotions;
  }
}
