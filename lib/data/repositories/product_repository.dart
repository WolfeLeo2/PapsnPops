import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_variant.dart';
import '../../domain/models/product_with_variants.dart';
import '../powersync/powersync_client.dart';
import '../supabase/supabase_client.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductRepository {
  /// Streams all products joined with their variants, ordered by product name.
  Stream<List<ProductWithVariants>> watchAllProducts({bool includeInactive = false}) {
    // Watch the products table — any change (product or variant) triggers a new emit.
    final activeFilter = includeInactive ? '' : 'WHERE p.is_active = 1 AND (pv.is_active = 1 OR pv.id IS NULL)';
    
    return db
        .watch('''
      SELECT
        p.id,
        p.name,
        p.category_id,
        p.reorder_level,
        p.is_active,
        p.base_unit,
        p.container_size,
        p.container_name,
        p.created_at,
        pv.id         AS variant_id,
        pv.name       AS variant_name,
        pv.unit_label,
        pv.conversion_factor,
        pv.selling_price,
        pv.cost_price,
        pv.wholesale_price,
        pv.barcode,
        pv.sku,
        pv.is_active  AS variant_is_active,
        pv.is_default,
        pv.created_at AS variant_created_at
      FROM products p
      LEFT JOIN product_variants pv ON pv.product_id = p.id
      $activeFilter
      ORDER BY p.name ASC, pv.is_default DESC, pv.name ASC
    ''')
        .map((rows) => _groupRows(rows));
  }

  Future<void> updateProductActiveStatus(String productId, bool isActive) async {
    await supabase.from('products').update({'is_active': isActive}).eq('id', productId);
  }

  Future<void> updateVariantActiveStatus(String variantId, bool isActive) async {
    await supabase.from('product_variants').update({'is_active': isActive}).eq('id', variantId);
  }

  Future<void> hardDeleteProduct(String productId) async {
    try {
      await supabase.from('products').delete().eq('id', productId);
    } catch (e) {
      if (e.toString().contains('foreign key constraint') || e.toString().contains('23503')) {
        throw Exception('Cannot delete product with transaction history');
      }
      rethrow;
    }
  }

  Future<void> updateProductName(String productId, String newName) async {
    await supabase.from('products').update({'name': newName}).eq('id', productId);
  }

  List<ProductWithVariants> _groupRows(List<Map<String, dynamic>> rows) {
    final Map<String, Product> productMap = {};
    final Map<String, List<ProductVariant>> variantsMap = {};
    final List<String> orderedIds = [];

    for (final row in rows) {
      final productId = row['id'] as String;

      if (!productMap.containsKey(productId)) {
        orderedIds.add(productId);
        productMap[productId] = Product.fromRow(row);
        variantsMap[productId] = [];
      }

      // A product may have no variants yet (LEFT JOIN returns nulls)
      if (row['variant_id'] != null) {
        variantsMap[productId]!.add(
          ProductVariant.fromRow({
            'id': row['variant_id'],
            'product_id': productId,
            'name': row['variant_name'],
            'unit_label': row['unit_label'],
            'conversion_factor': row['conversion_factor'],
            'selling_price': row['selling_price'],
            'cost_price': row['cost_price'],
            'wholesale_price': row['wholesale_price'],
            'barcode': row['barcode'],
            'sku': row['sku'],
            'is_active': row['variant_is_active'],
            'is_default': row['is_default'],
            'created_at': row['variant_created_at'],
          }),
        );
      }
    }

    return orderedIds
        .map(
          (id) => ProductWithVariants(
            product: productMap[id]!,
            variants: variantsMap[id]!,
          ),
        )
        .toList();
  }
}
