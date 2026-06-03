import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../domain/models/product_with_variants.dart';
import '../../domain/models/stock_level.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../../data/repositories/branch_provider.dart';
import '../../data/powersync/powersync_client.dart';
import '../../domain/models/category.dart';
import '../../domain/models/adjustment_reason.dart';

// ── UUID helper (no external package needed) ──────────────────────────────────
String generateV4Uuid() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final productsProvider = StreamProvider<List<ProductWithVariants>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchAllProducts();
});

final branchStockProvider = StreamProvider<List<StockLevel>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  final branchId = ref.watch(currentBranchIdProvider);

  if (branchId == null) {
    return Stream.value([]);
  }

  return repo.watchStockLevels(branchId);
});

final productStockProvider = Provider.family<StockLevel?, String>((
  ref,
  productId,
) {
  final stockLevels = ref.watch(branchStockProvider).value ?? [];
  return stockLevels.where((s) => s.productId == productId).firstOrNull;
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return db.watch('SELECT * FROM categories ORDER BY name ASC').map((rows) {
    return rows.map((r) => Category.fromRow(r)).toList();
  });
});

final adjustmentReasonsProvider = StreamProvider<List<AdjustmentReason>>((ref) {
  return db.watch('SELECT * FROM adjustment_reasons ORDER BY name ASC').map((
    rows,
  ) {
    return rows.map((r) => AdjustmentReason.fromRow(r)).toList();
  });
});

final stockAdjustmentControllerProvider = Provider<StockAdjustmentController>((
  ref,
) {
  return StockAdjustmentController();
});

class StockMovementInput {
  final String productId;
  final int quantityDelta;
  final int? costPrice;
  StockMovementInput({
    required this.productId,
    required this.quantityDelta,
    this.costPrice,
  });
}

class StockAdjustmentController {
  Future<void> confirmAdjustment({
    required List<StockMovementInput> items,
    required Set<String> selectedBranches,
    required String reason,
    required String reference,
    required String userId,
    required String type,
  }) async {
    // We will execute a write transaction.

    await db.writeTransaction((tx) async {
      final now = DateTime.now().toIso8601String();

      for (final branchId in selectedBranches) {
        for (final item in items) {
          final productId = item.productId;
          final adjustmentQty = item.quantityDelta;
          final costPrice = item.costPrice;

          // 1. Insert into stock_movements

          await tx.execute(
            '''
            INSERT INTO stock_movements (id, branch_id, product_id, type, reason, cost_price, quantity, reference_id, user_id, created_at)
            VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              branchId,
              productId,
              type,
              reason,
              costPrice,
              adjustmentQty,
              reference,
              userId,
              now,
            ],
          );

          // 2. Upsert stock_levels (SELECT then UPDATE or INSERT because we might not have a UNIQUE constraint in local SQLite)
          final existing = await tx.getOptional(
            'SELECT id, quantity FROM stock_levels WHERE branch_id = ? AND product_id = ?',
            [branchId, productId],
          );

          if (existing != null) {
            final currentQty = existing['quantity'] as int? ?? 0;
            final newQty = currentQty + adjustmentQty;
            await tx.execute(
              'UPDATE stock_levels SET quantity = ?, updated_at = ? WHERE id = ?',
              [newQty, now, existing['id']],
            );
          } else {
            await tx.execute(
              'INSERT INTO stock_levels (id, branch_id, product_id, quantity, updated_at) VALUES (uuid(), ?, ?, ?, ?)',
              [branchId, productId, adjustmentQty, now],
            );
          }
        }
      }
    });
  }

  Future<void> addAdjustmentReason(String name) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'INSERT INTO adjustment_reasons (id, name, created_at) VALUES (uuid(), ?, ?)',
      [name, now],
    );
  }

  Future<void> addCategory(String name) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'INSERT INTO categories (id, name, created_at) VALUES (uuid(), ?, ?)',
      [name, now],
    );
  }
}

// ── Product Controller ────────────────────────────────────────────────────────

final productControllerProvider = Provider<ProductController>((ref) {
  return ProductController();
});

class VariantInput {
  final String name;
  final String unitLabel;
  final int conversionFactor;
  final int sellingPrice; // KES × 100
  final int? costPrice; // KES × 100
  final int? wholesalePrice;
  final String? barcode;
  final String? sku;
  final bool isDefault;

  const VariantInput({
    required this.name,
    required this.unitLabel,
    required this.conversionFactor,
    required this.sellingPrice,
    this.costPrice,
    this.wholesalePrice,
    this.barcode,
    this.sku,
    required this.isDefault,
  });
}

class ProductController {
  Future<void> saveProduct({
    required String name,
    required String? categoryId,
    required int reorderLevel,
    required String organisationId,
    required String baseUnit,
    int? containerSize,
    String? containerName,
    required List<VariantInput> variants,
  }) async {
    final productId = generateV4Uuid();
    final now = DateTime.now().toIso8601String();

    await db.writeTransaction((tx) async {
      await tx.execute(
        'INSERT INTO products (id, name, category_id, reorder_level, base_unit, container_size, container_name, is_active, created_at, organisation_id) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)',
        [
          productId,
          name,
          categoryId,
          reorderLevel,
          baseUnit,
          containerSize,
          containerName,
          now,
          organisationId,
        ],
      );

      for (final v in variants) {
        await tx.execute(
          'INSERT INTO product_variants '
          '(id, product_id, name, unit_label, conversion_factor, '
          'selling_price, cost_price, wholesale_price, barcode, sku, '
          'is_active, is_default, created_at) '
          'VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)',
          [
            productId,
            v.name,
            v.unitLabel,
            v.conversionFactor,
            v.sellingPrice,
            v.costPrice,
            v.wholesalePrice,
            v.barcode?.isEmpty == true ? null : v.barcode,
            v.sku?.isEmpty == true ? null : v.sku,
            v.isDefault ? 1 : 0,
            now,
          ],
        );
      }
    });
  }

  Future<void> updateVariant({
    required String variantId,
    required int sellingPrice,
    int? costPrice,
    String? barcode,
    String? sku,
  }) async {
    await db.execute(
      '''
      UPDATE product_variants
      SET selling_price = ?, cost_price = ?, barcode = ?, sku = ?
      WHERE id = ?
    ''',
      [
        sellingPrice,
        costPrice,
        barcode?.isEmpty == true ? null : barcode,
        sku?.isEmpty == true ? null : sku,
        variantId,
      ],
    );
  }
}
