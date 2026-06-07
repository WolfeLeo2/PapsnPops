import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/utils/currency.dart';
import '../../core/utils/stock_display.dart';
import '../../domain/models/product_variant.dart';
import '../../shared/widgets/stat_card.dart';
import 'product_detail_provider.dart';
import 'stock_provider.dart';
import 'widgets/edit_variant_sheet.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final productsAsync = ref.watch(productsProvider);
    final stockTrendAsync = ref.watch(productStockTrendProvider(productId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('Product Details'),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple),
            onPressed: () {
              // Edit product metadata
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          final pv = products
              .where((p) => p.product.id == productId)
              .firstOrNull;
          if (pv == null) {
            return const Center(child: Text('Product not found'));
          }

          final product = pv.product;
          final variants = List<ProductVariant>.from(pv.variants)
            ..sort((a, b) => b.conversionFactor.compareTo(a.conversionFactor));

          final stockLevel = ref.watch(productStockProvider(productId));
          final quantity = stockLevel?.quantity ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Header Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PhosphorIcon(
                        PhosphorIconsDuotone.package,
                        color: cs.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.baseUnit == 'piece'
                                      ? 'Piece'
                                      : 'Volume',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reorder at ${product.reorderLevel}',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Total Stock & Sparkline
                LayoutBuilder(
                  builder: (context, constraints) {
                    final trendData = stockTrendAsync.value ?? [];
                    final isPositive =
                        trendData.isNotEmpty &&
                        trendData.last >= trendData.first;

                    return StatCard(
                      title: 'Total In Stock',
                      value: StockDisplay.format(product, quantity, variants),
                      trendPercentage:
                          null, // Don't have % easily, just sparkline
                      isPositiveTrend: isPositive,
                      trendLabel: 'last 30 movements',
                      sparklineData: trendData.isEmpty ? null : trendData,
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  'Variants',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // Variants List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: variants.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    return Material(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          EditVariantSheet.show(context, variant);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          variant.name,
                                          style: tt.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        if (variant.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'DEFAULT',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        cs.onTertiaryContainer,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 9,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      StockDisplay.formatVariantStock(
                                        quantity,
                                        variant,
                                      ),
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyHelper.format(variant.sellingPrice),
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: cs.primary,
                                    ),
                                  ),
                                  Text(
                                    'Cost: ${CurrencyHelper.format(variant.costPrice)}',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
