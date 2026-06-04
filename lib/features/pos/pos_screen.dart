import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'pos_provider.dart';
import 'widgets/cart_panel.dart';
import 'widgets/product_grid.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final cartItems = ref.watch(cartProvider);
    final itemCount = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: PhosphorIcon(
                isDesktop ? PhosphorIconsRegular.sidebar : PhosphorIconsRegular.list,
              ),
              onPressed: () {
                if (isDesktop) {
                  ref.read(railExpandedProvider.notifier).toggle();
                } else {
                  context
                      .findRootAncestorStateOfType<ScaffoldState>()
                      ?.openDrawer();
                }
              },
            );
          },
        ),
      ),
      body: isDesktop
          ? Row(
              children: [
                const Expanded(
                  flex: 6,
                  child: ProductGrid(),
                ),
                VerticalDivider(width: 1, color: cs.outline.withValues(alpha: 0.5)),
                const Expanded(
                  flex: 4,
                  child: CartPanel(),
                ),
              ],
            )
          : const ProductGrid(),
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: const SafeArea(
                        child: CartPanel(),
                      ),
                    );
                  },
                );
              },
              icon: Badge.count(
                count: itemCount,
                isLabelVisible: itemCount > 0,
                child: const PhosphorIcon(PhosphorIconsRegular.shoppingBag),
              ),
              label: const Text('View Cart'),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            )
          : null,
    );
  }
}
