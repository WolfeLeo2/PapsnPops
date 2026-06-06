import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../domain/models/product_with_variants.dart';
import '../../../domain/models/product_variant.dart';
import '../../../domain/models/tab_item.dart';
import '../../../domain/models/open_tab.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/stock_display.dart';
import '../../../shared/widgets/shimmer_skeletons.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/tab_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/branch_provider.dart';
import '../../stock/stock_provider.dart' show categoriesProvider, productStockProvider, generateV4Uuid;
import '../../pos/pos_provider.dart' show activeStaffProvider;
import '../../pos/widgets/variant_selection_sheet.dart';

class TabAddItemSheet extends ConsumerStatefulWidget {
  final OpenTab tab;

  const TabAddItemSheet({
    super.key,
    required this.tab,
  });

  static Future<void> show({
    required BuildContext context,
    required OpenTab tab,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            width: 600,
            height: 650,
            child: TabAddItemSheet(tab: tab),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: TabAddItemSheet(tab: tab),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<TabAddItemSheet> createState() => _TabAddItemSheetState();
}

class _TabAddItemSheetState extends ConsumerState<TabAddItemSheet> {
  String _searchQuery = '';
  String? _selectedCategoryId;

  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productRepositoryProvider).watchAllProducts();
    final staffAsync = ref.watch(activeStaffProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Items to Tab',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 24),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Search and Selectors
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products by name...',
                  prefixIcon: const PhosphorIcon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
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
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Qty picker
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const PhosphorIcon(PhosphorIconsRegular.minus, size: 16),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_quantity',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 16),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Categories List
        categoriesAsync.when(
          data: (categories) {
            return SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : categories[index - 1];
                  final isSelected = isAll
                      ? _selectedCategoryId == null
                      : _selectedCategoryId == category!.id;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: FilterChip(
                      label: Text(isAll ? 'All' : category!.name),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        _selectedCategoryId = isAll ? null : category!.id;
                      }),
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
          loading: () => const SizedBox(height: 52),
          error: (_, __) => const SizedBox(),
        ),

        // Product Grid
        Expanded(
          child: StreamBuilder<List<ProductWithVariants>>(
            stream: productsAsync,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const GridSkeleton(
                  itemCount: 8,
                  crossAxisExtent: 180,
                  aspectRatio: 0.85,
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: tt.bodyMedium?.copyWith(color: cs.error),
                  ),
                );
              }

              final products = snapshot.data ?? [];
              
              // Filter products locally
              final query = _searchQuery.toLowerCase().trim();
              final filtered = products.where((p) {
                final matchesCategory = _selectedCategoryId == null || p.product.categoryId == _selectedCategoryId;
                final matchesName = p.product.name.toLowerCase().contains(query);
                final matchesSku = p.variants.any((v) => v.sku?.toLowerCase().contains(query) ?? false);
                final matchesBarcode = p.variants.any((v) => v.barcode?.contains(query) ?? false);
                return matchesCategory && (matchesName || matchesSku || matchesBarcode);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.magnifyingGlass,
                        size: 40,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products found',
                        style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final pwv = filtered[index];
                  final product = pwv.product;
                  final defaultVariant = pwv.defaultVariant;
                  final hasVariants = pwv.hasVariants && pwv.variants.length > 1;

                  // Get current stock level
                  final stockLevel = ref.watch(productStockProvider(product.id));
                  final stockQty = stockLevel?.quantity ?? 0;
                  final isLowStock = stockQty <= (product.reorderLevel > 0 ? product.reorderLevel : 5);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (!hasVariants) {
                          _addVariantToTab(pwv, defaultVariant);
                        } else {
                          VariantSelectionSheet.show(
                            context: context,
                            productWithVariants: pwv,
                            onVariantSelected: (variant) {
                              _addVariantToTab(pwv, variant);
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
                            color: cs.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Row(
                              children: [
                                PhosphorIcon(
                                  isLowStock ? PhosphorIconsFill.warningCircle : PhosphorIconsFill.circle,
                                  size: 10,
                                  color: isLowStock ? cs.error : cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    StockDisplay.format(product, stockQty, pwv.variants),
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _addVariantToTab(ProductWithVariants pwv, ProductVariant variant) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final repo = ref.read(tabRepositoryProvider);
    final errorColor = Theme.of(context).colorScheme.error;

    final item = TabItem(
      id: generateV4Uuid(),
      tabId: widget.tab.id,
      productId: pwv.product.id,
      variantId: variant.id,
      variantName: variant.name,
      quantity: _quantity,
      unitPrice: variant.sellingPrice,
      addedBy: widget.tab.openedBy,
      createdAt: DateTime.now(),
    );

    try {
      await repo.addTabItem(item);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${pwv.product.name} (${variant.name}) added to tab'),
          duration: const Duration(milliseconds: 1000),
        ),
      );
      // Close sheet
      nav.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error adding item: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }
}
