import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_variant.dart';
import '../../domain/models/promotion.dart';
import '../../domain/models/applied_promotion.dart';
import '../../core/utils/promotion_engine.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/promotion_repository.dart';
import '../../domain/models/product_with_variants.dart';
import '../../data/powersync/powersync_client.dart';
import '../../data/repositories/branch_provider.dart';
import '../stock/stock_provider.dart';

part 'pos_provider.g.dart';

@riverpod
Stream<List<Map<String, dynamic>>> activeStaff(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) {
    return Stream.value([]);
  }
  return db.watch(
    'SELECT id, name FROM staff WHERE branch_id = ? AND is_active = 1 ORDER BY name ASC',
    parameters: [branchId],
  );
}

@riverpod
List<AppliedPromotion> appliedPromotions(Ref ref) {
  final cartItems = ref.watch(cartProvider);
  final activePromotions = ref.watch(promotionsProvider).value ?? [];
  return PromotionEngine.calculatePromotions(
    cartItems: cartItems,
    activePromotions: activePromotions,
    now: DateTime.now(),
  );
}

@riverpod
Stream<List<Promotion>> promotions(Ref ref) {
  final repo = ref.watch(promotionRepositoryProvider);
  return repo.watchActivePromotions();
}

@riverpod
class Cart extends _$Cart {
  final List<CartItem> _rawItems = [];

  @override
  List<CartItem> build() {
    final promotionsAsync = ref.watch(promotionsProvider);
    final activePromotions = promotionsAsync.value ?? [];
    return _recalculate(activePromotions);
  }

  List<CartItem> _recalculate(List<Promotion> promotions) {
    if (_rawItems.isEmpty) return [];

    final applied = PromotionEngine.calculatePromotions(
      cartItems: _rawItems,
      activePromotions: promotions,
      now: DateTime.now(),
    );

    final discounts = <String, int>{};
    for (final app in applied) {
      discounts[app.variantId] = (discounts[app.variantId] ?? 0) + app.discountAmount;
    }

    return _rawItems.map((item) {
      final discount = discounts[item.variant.id] ?? 0;
      return item.copyWith(discountAmount: discount);
    }).toList();
  }

  void _updateState() {
    final activePromotions = ref.read(promotionsProvider).value ?? [];
    state = _recalculate(activePromotions);
  }

  bool addToCart(Product product, ProductVariant variant, int qty) {
    final stockLevel = ref.read(productStockProvider(product.id));
    final currentStock = stockLevel?.quantity ?? 0;
    
    final addedBaseUnits = qty * variant.conversionFactor;
    int existingBaseUnits = 0;
    for (final item in _rawItems) {
      if (item.product.id == product.id) {
        existingBaseUnits += item.quantity * item.variant.conversionFactor;
      }
    }
    
    if (existingBaseUnits + addedBaseUnits > currentStock) {
      return false; // Insufficient stock
    }

    final index = _rawItems.indexWhere((item) => item.variant.id == variant.id);
    if (index >= 0) {
      final existing = _rawItems[index];
      _rawItems[index] = existing.copyWith(
        quantity: existing.quantity + qty,
        discountAmount: 0,
      );
    } else {
      _rawItems.add(
        CartItem(
          product: product,
          variant: variant,
          quantity: qty,
          discountAmount: 0,
        ),
      );
    }
    _updateState();
    return true;
  }

  void removeFromCart(String variantId) {
    _rawItems.removeWhere((item) => item.variant.id == variantId);
    _updateState();
  }

  bool updateQuantity(String variantId, int newQty) {
    if (newQty <= 0) {
      removeFromCart(variantId);
      return true;
    }
    final index = _rawItems.indexWhere((item) => item.variant.id == variantId);
    if (index >= 0) {
      final existingItem = _rawItems[index];
      if (newQty > existingItem.quantity) {
        final diff = newQty - existingItem.quantity;
        final stockLevel = ref.read(productStockProvider(existingItem.product.id));
        final currentStock = stockLevel?.quantity ?? 0;
        
        final addedBaseUnits = diff * existingItem.variant.conversionFactor;
        int existingBaseUnits = 0;
        for (final item in _rawItems) {
          if (item.product.id == existingItem.product.id) {
            existingBaseUnits += item.quantity * item.variant.conversionFactor;
          }
        }
        
        if (existingBaseUnits + addedBaseUnits > currentStock) {
          return false; // Insufficient stock
        }
      }

      _rawItems[index] = _rawItems[index].copyWith(
        quantity: newQty,
        discountAmount: 0,
      );
      _updateState();
    }
    return true;
  }

  void clear() {
    _rawItems.clear();
    state = [];
  }

  int get subtotal => state.fold(0, (sum, item) => sum + item.subtotal);
  int get discountAmount => state.fold(0, (sum, item) => sum + item.discountAmount);
  int get total => subtotal - discountAmount;
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
  void set(String val) => state = val;
}

@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

@riverpod
class SelectedStaff extends _$SelectedStaff {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

@riverpod
class SelectedPaymentMethod extends _$SelectedPaymentMethod {
  @override
  String build() => 'cash';
  void set(String val) => state = val;
}

@riverpod
class PaymentReference extends _$PaymentReference {
  @override
  String build() => '';
  void set(String val) => state = val;
}

@riverpod
Stream<List<ProductWithVariants>> filteredProducts(Ref ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final categoryId = ref.watch(selectedCategoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);

  return productRepo.watchAllProducts().map((products) {
    return products.where((p) {
      // Filter by category
      if (categoryId != null && p.product.categoryId != categoryId) {
        return false;
      }
      // Filter by search query
      if (query.isNotEmpty) {
        final matchesName = p.product.name.toLowerCase().contains(query);
        final matchesSku = p.variants.any((v) => v.sku?.toLowerCase().contains(query) ?? false);
        final matchesBarcode = p.variants.any((v) => v.barcode?.contains(query) ?? false);
        return matchesName || matchesSku || matchesBarcode;
      }
      return true;
    }).toList();
  });
}

extension CartListExtension on List<CartItem> {
  int get subtotal => fold(0, (sum, item) => sum + item.subtotal);
  int get discountAmount => fold(0, (sum, item) => sum + item.discountAmount);
  int get total => subtotal - discountAmount;
  int get itemCount => fold(0, (sum, item) => sum + item.quantity);
}
