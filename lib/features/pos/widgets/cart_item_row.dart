import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/models/cart_item.dart';
import '../../../core/utils/currency.dart';
import '../../../shared/widgets/qty_stepper.dart';
import '../pos_provider.dart';

class CartItemRow extends ConsumerWidget {
  final CartItem item;

  const CartItemRow({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Dismissible(
      key: Key('cart_item_${item.variant.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PhosphorIcon(
          PhosphorIconsRegular.trash,
          color: cs.onError,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        ref.read(cartProvider.notifier).removeFromCart(item.variant.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} removed from cart'),
            duration: Duration(milliseconds: 1000),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(cartProvider.notifier).addToCart(
                      item.product,
                      item.variant,
                      item.quantity,
                    );
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.variant.name,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              QtyStepper(
                quantity: item.quantity,
                onChanged: (newQty) {
                  ref
                      .read(cartProvider.notifier)
                      .updateQuantity(item.variant.id, newQty);
                },
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.discountAmount > 0) ...[
                    Text(
                      CurrencyHelper.format(item.subtotal),
                      style: tt.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    CurrencyHelper.format(item.lineTotal),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: item.discountAmount > 0 ? cs.primary : cs.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
