import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../domain/models/product_with_variants.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/stock_display.dart';
import '../../../shared/widgets/shimmer_skeletons.dart';
import '../../stock/stock_provider.dart' show categoriesProvider, productStockProvider;
import '../pos_provider.dart';
import 'variant_selection_sheet.dart';

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final filteredProductsAsync = ref.watch(filteredProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products by name, SKU, or barcode...',
              prefixIcon: const PhosphorIcon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 20,
              ),
              suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                  ? IconButton(
                      icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 18),
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).set('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).set(val);
            },
          ),
        ),

        // Categories horizontal list
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: categoriesAsync.when(
            data: (categories) {
              return SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final category = isAll ? null : categories[index - 1];
                    final isSelected = isAll
                        ? selectedCategoryId == null
                        : selectedCategoryId == category!.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: FilterChip(
                        label: Text(isAll ? 'All' : category!.name),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .set(isAll ? null : category!.id);
                        },
                        selectedColor: cs.primaryContainer,
                        checkmarkColor: cs.onPrimaryContainer,
                        labelStyle: tt.labelLarge?.copyWith(
                          color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: cs.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  5,
                  (index) => Shimmer.fromColors(
                    baseColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Error loading categories: $err',
                style: tt.bodySmall?.copyWith(color: cs.error),
              ),
            ),
          ),
        ),

        // Product Grid
        Expanded(
          child: filteredProductsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.magnifyingGlass,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: tt.titleMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    productWithVariants: products[index],
                  );
                },
              );
            },
            loading: () => const GridSkeleton(
              itemCount: 12,
              crossAxisExtent: 180,
              aspectRatio: 0.85,
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading products: $err',
                style: tt.bodyLarge?.copyWith(color: cs.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends ConsumerWidget {
  final ProductWithVariants productWithVariants;

  const ProductCard({
    super.key,
    required this.productWithVariants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final product = productWithVariants.product;
    final defaultVariant = productWithVariants.defaultVariant;
    final hasVariants = productWithVariants.hasVariants;

    // Get current stock level
    final stockLevel = ref.watch(productStockProvider(product.id));
    final stockQty = stockLevel?.quantity ?? 0;

    // Check quantity in cart
    final cart = ref.watch(cartProvider);
    final cartItemsForProduct = cart.where((item) => item.product.id == product.id).toList();
    final isInCart = cartItemsForProduct.isNotEmpty;
    final totalQtyInCart = cartItemsForProduct.fold<int>(0, (sum, item) => sum + item.quantity);

    // Is low stock
    final isLowStock = stockQty <= (product.reorderLevel > 0 ? product.reorderLevel : 5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!hasVariants || productWithVariants.variants.length == 1) {
            final success = ref.read(cartProvider.notifier).addToCart(product, defaultVariant, 1);
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insufficient stock for this item')),
              );
            }
          } else {
            VariantSelectionSheet.show(
              context: context,
              productWithVariants: productWithVariants,
              onVariantSelected: (variant) {
                final success = ref.read(cartProvider.notifier).addToCart(product, variant, 1);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient stock for this item')),
                  );
                }
              },
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isInCart ? cs.primary : cs.outline.withValues(alpha: 0.3),
              width: isInCart ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Expanded(
                      child: Text(
                        product.name,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Stock Level
                    Row(
                      children: [
                        PhosphorIcon(
                          isLowStock
                              ? PhosphorIconsFill.warningCircle
                              : PhosphorIconsFill.circle,
                          size: 10,
                          color: isLowStock ? cs.error : cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            StockDisplay.format(
                              product,
                              stockQty,
                              productWithVariants.variants,
                            ),
                            style: tt.bodySmall?.copyWith(
                              color: isLowStock ? cs.error : cs.onSurfaceVariant,
                              fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      CurrencyHelper.format(defaultVariant.sellingPrice),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isInCart)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalQtyInCart',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
