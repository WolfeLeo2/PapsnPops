import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'stock_provider.dart';
import 'widgets/product_card.dart';
import 'add_product_screen.dart';
import '../../shared/widgets/empty_state.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;

  void _handleAddProduct() {
    AddProductScreen.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        leading: Builder(
          builder: (context) {
            final isDesktop = MediaQuery.of(context).size.width >= 600;
            return IconButton(
              icon: Icon(isDesktop ? Icons.menu_open : Icons.menu),
              onPressed: () {
                if (!isDesktop) {
                  context
                      .findRootAncestorStateOfType<ScaffoldState>()
                      ?.openDrawer();
                }
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Add Product"),
        icon: const PhosphorIcon(PhosphorIconsBold.plus),
        onPressed: _handleAddProduct,
        hoverColor: cs.primaryContainer.withValues(alpha: 0.15),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
                prefixIcon: const PhosphorIcon(
                  PhosphorIconsDuotone.magnifyingGlass,
                ),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cs.primary),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Filters
          Consumer(
            builder: (context, ref, child) {
              final categoriesAsync = ref.watch(categoriesProvider);
              return categoriesAsync.when(
                data: (categories) {
                  return SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            showCheckmark: false,
                            label: const Text('All Categories'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) =>
                                setState(() => _selectedCategoryId = null),
                          ),
                        ),
                        ...categories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              showCheckmark: false,
                              label: Text(cat.name),
                              selected: _selectedCategoryId == cat.id,
                              onSelected: (_) => setState(
                                () => _selectedCategoryId =
                                    _selectedCategoryId == cat.id
                                    ? null
                                    : cat.id,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 48),
                error: (err, stack) => const SizedBox(height: 48),
              );
            },
          ),

          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((pw) {
                  final name = pw.product.name.toLowerCase();
                  final skuMatch = pw.variants.any(
                    (v) =>
                        v.sku?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false,
                  );
                  final matchesSearch =
                      name.contains(_searchQuery.toLowerCase()) || skuMatch;
                  final matchesCategory =
                      _selectedCategoryId == null ||
                      pw.product.categoryId == _selectedCategoryId;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'No products found',
                    message: 'Try adjusting your search or add a new product.',
                    icon: PhosphorIconsDuotone.package,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 800
                        ? 4
                        : (constraints.maxWidth > 600 ? 3 : 2);
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final productWithVariants = filtered[index];
                        return ProductGridCard(
                          productWithVariants: productWithVariants,
                          onTap: () {
                            context.push(
                              '/products/${productWithVariants.product.id}',
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
