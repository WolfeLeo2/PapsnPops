import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/product_with_variants.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/stock_display.dart';
import '../stock_provider.dart';

class ProductGridCard extends ConsumerWidget {
  final ProductWithVariants productWithVariants;
  final VoidCallback? onTap;

  const ProductGridCard({
    super.key,
    required this.productWithVariants,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final product = productWithVariants.product;
    final defaultVariant = productWithVariants.hasVariants
        ? productWithVariants.defaultVariant
        : null;

    final stockLevel = ref.watch(productStockProvider(product.id));
    final quantity = stockLevel?.quantity ?? 0;
    final isLowStock =
        quantity <= (product.reorderLevel > 0 ? product.reorderLevel : 5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: cs.surfaceContainerHighest,
                          child: Center(
                            child: PhosphorIcon(
                              PhosphorIconsDuotone.package,
                              size: 40,
                              color: cs.outlineVariant,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? cs.errorContainer.withValues(alpha: 0.9)
                                  : cs.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  isLowStock
                                      ? PhosphorIconsFill.warningCircle
                                      : PhosphorIconsFill.circle,
                                  size: 10,
                                  color: isLowStock ? cs.error : cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  StockDisplay.format(
                                    product,
                                    quantity,
                                    productWithVariants.variants,
                                  ),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isLowStock
                                        ? cs.onErrorContainer
                                        : cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (defaultVariant?.sku != null &&
                        defaultVariant!.sku!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${defaultVariant.sku}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (productWithVariants.variants.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${productWithVariants.variants.length} Options',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (defaultVariant != null)
                      Text(
                        CurrencyHelper.format(defaultVariant.sellingPrice),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
