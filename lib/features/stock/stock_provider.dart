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
import '../../core/utils/error_reporting.dart';

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

class ShowInactiveProductsNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool val) => state = val;
}

final showInactiveProductsProvider = NotifierProvider<ShowInactiveProductsNotifier, bool>(() => ShowInactiveProductsNotifier());

final productsProvider = StreamProvider<List<ProductWithVariants>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final includeInactive = ref.watch(showInactiveProductsProvider);
  return repo.watchAllProducts(includeInactive: includeInactive);
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
      final now = DateTime.now().toUtc().toIso8601String();

      for (final branchId in selectedBranches) {
        for (final item in items) {
          final productId = item.productId;
          final adjustmentQty = item.quantityDelta;
          final costPrice = item.costPrice;

          // 2. Upsert stock_levels to calculate stock_after
          final existing = await tx.getOptional(
            'SELECT id, quantity FROM stock_levels WHERE branch_id = ? AND product_id = ?',
            [branchId, productId],
          );

          int currentQty = 0;
          if (existing != null) {
            currentQty = existing['quantity'] as int? ?? 0;
          }
          final newQty = currentQty + adjustmentQty;

          // 1. Insert into stock_movements
          await tx.execute(
            '''
            INSERT INTO stock_movements (id, branch_id, product_id, type, reason, cost_price, quantity, stock_after, reference_id, user_id, created_at)
            VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              branchId,
              productId,
              type,
              reason,
              costPrice,
              adjustmentQty,
              newQty,
              reference,
              userId,
              now,
            ],
          );

          if (existing != null) {
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

  Future<void> revertAdjustment({
    required String movementId,
    required String branchId,
    required String productId,
    required int originalQuantityDelta,
    required String userId,
  }) async {
    await db.writeTransaction((tx) async {
      final now = DateTime.now().toUtc().toIso8601String();

      // Mark original as reverted
      await tx.execute(
        'UPDATE stock_movements SET is_reverted = 1, reverted_by = ?, reverted_at = ? WHERE id = ?',
        [userId, now, movementId],
      );

      // Fetch current stock
      final existing = await tx.getOptional(
        'SELECT id, quantity FROM stock_levels WHERE branch_id = ? AND product_id = ?',
        [branchId, productId],
      );

      int currentQty = 0;
      if (existing != null) {
        currentQty = existing['quantity'] as int? ?? 0;
      }
      
      // Reverse the delta
      final revertQty = -originalQuantityDelta;
      final newQty = currentQty + revertQty;

      // Add compensating movement
      await tx.execute(
        '''
        INSERT INTO stock_movements (id, branch_id, product_id, type, reason, quantity, stock_after, reference_id, user_id, created_at)
        VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          branchId,
          productId,
          'void',
          'Reverted Adjustment',
          revertQty,
          newQty,
          movementId, // reference_id must be a UUID, linking to original movement
          userId,
          now,
        ],
      );

      // Upsert stock_levels
      if (existing != null) {
        await tx.execute(
          'UPDATE stock_levels SET quantity = ?, updated_at = ? WHERE id = ?',
          [newQty, now, existing['id']],
        );
      } else {
        await tx.execute(
          'INSERT INTO stock_levels (id, branch_id, product_id, quantity, updated_at) VALUES (uuid(), ?, ?, ?, ?)',
          [branchId, productId, revertQty, now],
        );
      }
    });
  }

  Future<void> addAdjustmentReason(String name) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await db.execute(
      'INSERT INTO adjustment_reasons (id, name, created_at) VALUES (uuid(), ?, ?)',
      [name, now],
    );
  }

  Future<void> addCategory(String name) async {
    final now = DateTime.now().toUtc().toIso8601String();
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
  }) =>
      guardWrite(
        ErrorArea.stockWrite,
        'saveProduct',
        () => _saveProduct(
          name: name,
          categoryId: categoryId,
          reorderLevel: reorderLevel,
          organisationId: organisationId,
          baseUnit: baseUnit,
          containerSize: containerSize,
          containerName: containerName,
          variants: variants,
        ),
        tags: {'organisation_id': organisationId},
        data: {'product_name': name, 'variant_count': variants.length},
      );

  Future<void> _saveProduct({
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
    final now = DateTime.now().toUtc().toIso8601String();

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

class StockAdjustmentRecord {
  final String id;
  final String productId;
  final String productName;
  final int quantityDelta;
  final String reason;
  final String? referenceId;
  final DateTime createdAt;
  final String branchId;
  final String branchName;
  final String userId;
  final String userName;
  final int? stockAfter;
  final bool isReverted;

  StockAdjustmentRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityDelta,
    required this.reason,
    this.referenceId,
    required this.createdAt,
    required this.branchId,
    required this.branchName,
    required this.userId,
    required this.userName,
    this.stockAfter,
    this.isReverted = false,
  });

  factory StockAdjustmentRecord.fromRow(Map<String, dynamic> row) {
    return StockAdjustmentRecord(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      productName: row['product_name'] as String? ?? 'Unknown Product',
      quantityDelta: row['quantity'] as int,
      reason: row['reason'] as String? ?? 'Adjustment',
      referenceId: row['reference_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      branchId: row['branch_id'] as String,
      branchName: row['branch_name'] as String? ?? 'Unknown Branch',
      userId: row['user_id'] as String,
      userName: row['user_name'] as String? ?? 'Unknown User',
      stockAfter: row['stock_after'] as int?,
      isReverted: (row['is_reverted'] as int? ?? 0) == 1,
    );
  }
}

final stockAdjustmentsProvider = StreamProvider<List<StockAdjustmentRecord>>((ref) {
  return db.watch('''
    SELECT 
      sm.id,
      sm.product_id,
      p.name as product_name,
      sm.quantity,
      COALESCE(ar.name, sm.reason) as reason,
      sm.reference_id,
      sm.created_at,
      sm.branch_id,
      b.name as branch_name,
      sm.user_id,
      u.full_name as user_name,
      sm.stock_after,
      sm.is_reverted
    FROM stock_movements sm
    LEFT JOIN products p ON sm.product_id = p.id
    LEFT JOIN branches b ON sm.branch_id = b.id
    LEFT JOIN user_profiles u ON sm.user_id = u.id
    LEFT JOIN adjustment_reasons ar ON sm.reason = ar.id
    WHERE sm.type IN ('adjustment', 'receive')
    ORDER BY sm.created_at DESC
  ''').map((rows) {
    return rows.map((r) => StockAdjustmentRecord.fromRow(r)).toList();
  });
});
