import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain/models/product_with_variants.dart';
import '../../../domain/models/product_variant.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/stock_display.dart';
import '../../stock/stock_provider.dart';

/// A sleek bottom sheet (or dialog) that lists all variants for a product.
/// The user taps a variant to select it.
class VariantSelectionSheet extends ConsumerWidget {
  final ProductWithVariants productWithVariants;

  /// Called when the user taps a specific variant
  final ValueChanged<ProductVariant> onVariantSelected;

  const VariantSelectionSheet({
    super.key,
    required this.productWithVariants,
    required this.onVariantSelected,
  });

  /// Shows this widget as a responsive modal (BottomSheet on mobile, Dialog on desktop)
  static Future<void> show({
    required BuildContext context,
    required ProductWithVariants productWithVariants,
    required ValueChanged<ProductVariant> onVariantSelected,
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
            width: 400,
            child: VariantSelectionSheet(
              productWithVariants: productWithVariants,
              onVariantSelected: onVariantSelected,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: VariantSelectionSheet(
              productWithVariants: productWithVariants,
              onVariantSelected: onVariantSelected,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final product = productWithVariants.product;
    final variants = productWithVariants.variants;

    // Sort so the default variant is first
    final sortedVariants = List<ProductVariant>.from(variants)
      ..sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PhosphorIcon(
                  PhosphorIconsDuotone.package,
                  color: cs.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Select an option',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.x),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Variant List
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: sortedVariants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final variant = sortedVariants[index];
              // Currently stock levels are per-product, not per-variant.
              final stockLevel = ref.watch(productStockProvider(product.id));
              final quantity = stockLevel?.quantity ?? 0;
              final isLowStock =
                  quantity <=
                  (product.reorderLevel > 0 ? product.reorderLevel : 5);

              return Material(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onVariantSelected(variant);
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
                                    style: theme.textTheme.titleSmall?.copyWith(
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
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'DEFAULT',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: cs.onTertiaryContainer,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  PhosphorIcon(
                                    isLowStock
                                        ? PhosphorIconsFill.warningCircle
                                        : PhosphorIconsFill.circle,
                                    size: 12,
                                    color: isLowStock ? cs.error : cs.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    StockDisplay.formatVariantStock(
                                      quantity,
                                      variant,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isLowStock
                                          ? cs.error
                                          : cs.onSurfaceVariant,
                                      fontWeight: isLowStock
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyHelper.format(variant.sellingPrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        PhosphorIcon(
                          PhosphorIconsRegular.caretRight,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
