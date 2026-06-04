import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';
import '../../../domain/models/open_tab.dart';
import '../../../domain/models/tab_item.dart';
import '../../../core/utils/currency.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/repositories/tab_repository.dart';
import '../../../data/repositories/branch_provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/stock/stock_provider.dart' show generateV4Uuid;
import '../pos_provider.dart';
import 'cart_item_row.dart';
import 'payment_method_selector.dart';
import 'invoice_sheet.dart';
import 'receipt_screen.dart';

class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _refController;

  @override
  void initState() {
    super.initState();
    _refController = TextEditingController(text: ref.read(paymentReferenceProvider));
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  void _handleCharge() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    if (paymentMethod == 'mpesa') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    final branchId = ref.read(currentBranchIdProvider);
    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No branch selected')),
      );
      return;
    }

    final authUser = ref.read(authProvider);
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Cashier not logged in')),
      );
      return;
    }

    try {
      final saleId = generateV4Uuid();
      final cartSubtotal = ref.read(cartProvider.notifier).subtotal;
      final cartDiscount = ref.read(cartProvider.notifier).discountAmount;
      final cartTotal = ref.read(cartProvider.notifier).total;
      final appliedPromos = ref.read(appliedPromotionsProvider);
      final selectedStaffId = ref.read(selectedStaffProvider);

      final sale = Sale(
        id: saleId,
        branchId: branchId,
        cashierId: authUser.id,
        staffId: selectedStaffId,
        customerId: null,
        paymentMethod: paymentMethod,
        paymentReference: paymentMethod == 'mpesa' ? _refController.text.trim() : null,
        subtotal: cartSubtotal,
        discountAmount: cartDiscount,
        total: cartTotal,
        promotionIds: appliedPromos.map((p) => p.promotion.id).toSet().toList(),
        isVoided: false,
        source: 'pos',
        createdAt: DateTime.now(),
      );

      final saleItems = cartItems.map((item) {
        return SaleItem(
          id: generateV4Uuid(),
          saleId: saleId,
          productId: item.product.id,
          variantId: item.variant.id,
          variantName: item.variant.name,
          quantity: item.quantity,
          unitPrice: item.variant.sellingPrice,
          costPrice: item.variant.costPrice,
          discountAmount: item.discountAmount,
          lineTotal: item.lineTotal,
        );
      }).toList();

      await ref.read(saleRepositoryProvider).createSale(sale, saleItems);

      // Clear state
      ref.read(cartProvider.notifier).clear();
      ref.read(selectedStaffProvider.notifier).set(null);
      ref.read(paymentReferenceProvider.notifier).set('');
      ref.read(selectedPaymentMethodProvider.notifier).set('cash');
      _refController.clear();

      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(sale: sale, items: saleItems),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sale: $e')),
        );
      }
    }
  }

  void _handleSaveAsTab() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final branchId = ref.read(currentBranchIdProvider);
    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No branch selected')),
      );
      return;
    }

    final authUser = ref.read(authProvider);

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final tabFormKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save as Tab'),
          content: Form(
            key: tabFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tab Name (e.g. Table 5, Brian)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Tab name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (tabFormKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) return;

    try {
      final tabId = generateV4Uuid();
      final tab = OpenTab(
        id: tabId,
        branchId: branchId,
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        openedBy: authUser?.id,
        isOpen: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(tabRepositoryProvider).createTab(tab);

      for (final item in cartItems) {
        final tabItem = TabItem(
          id: generateV4Uuid(),
          tabId: tabId,
          productId: item.product.id,
          variantId: item.variant.id,
          variantName: item.variant.name,
          quantity: item.quantity,
          unitPrice: item.variant.sellingPrice,
          addedBy: authUser?.id,
          createdAt: DateTime.now(),
        );
        await ref.read(tabRepositoryProvider).addTabItem(tabItem);
      }

      ref.read(cartProvider.notifier).clear();
      ref.read(selectedStaffProvider.notifier).set(null);
      ref.read(paymentReferenceProvider.notifier).set('');
      ref.read(selectedPaymentMethodProvider.notifier).set('cash');

      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      context.go('/tabs');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tab: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: PhosphorIcon(
                PhosphorIconsRegular.shoppingBagOpen,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select variants from the product grid to begin a transaction.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    if (cartItems.isEmpty) {
      return _buildEmptyState(theme, cs, tt);
    }

    final activeStaffAsync = ref.watch(activeStaffProvider);
    final paymentMethod = ref.watch(selectedPaymentMethodProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;
    final discountAmount = ref.watch(cartProvider.notifier).discountAmount;
    final total = ref.watch(cartProvider.notifier).total;
    final appliedPromos = ref.watch(appliedPromotionsProvider);

    // Group discounts by promotion name
    final groupedDiscounts = <String, int>{};
    for (final app in appliedPromos) {
      groupedDiscounts[app.promotion.name] = (groupedDiscounts[app.promotion.name] ?? 0) + app.discountAmount;
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'Cart',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ref.watch(cartProvider.notifier).itemCount} items',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const PhosphorIcon(PhosphorIconsRegular.dotsThreeVertical),
                  onSelected: (value) {
                    if (value == 'invoice') {
                      InvoiceSheet.show(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'invoice',
                      child: Row(
                        children: [
                          PhosphorIcon(PhosphorIconsRegular.fileText, size: 20),
                          SizedBox(width: 8),
                          Text('Save as Invoice'),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Cart Items List
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return CartItemRow(item: cartItems[index]);
              },
            ),
          ),
          const Divider(height: 1),

          // Checkout & Settings Panel
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Floor Salesperson Dropdown
                activeStaffAsync.when(
                  data: (staffList) {
                    final selectedStaff = ref.watch(selectedStaffProvider);
                    final hasSelectedStaffInList = staffList.any((s) => s['id'] == selectedStaff);
                    final dropdownValue = hasSelectedStaffInList ? selectedStaff : null;

                    return DropdownButtonFormField<String>(
                      initialValue: dropdownValue,
                      decoration: const InputDecoration(
                        labelText: 'Floor Salesperson',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...staffList.map((staff) {
                          return DropdownMenuItem<String>(
                            value: staff['id'] as String,
                            child: Text(staff['name'] as String),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        ref.read(selectedStaffProvider.notifier).set(val);
                      },
                    );
                  },
                  loading: () => Shimmer.fromColors(
                    baseColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  error: (err, stack) => Text(
                    'Failed to load staff: $err',
                    style: tt.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Method Selector
                const PaymentMethodSelector(),
                const SizedBox(height: 12),

                // Reference field if M-Pesa is selected
                if (paymentMethod == 'mpesa') ...[
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'M-Pesa Reference Code',
                      hintText: 'e.g. QX728HJ18A',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (val) {
                      ref.read(paymentReferenceProvider.notifier).set(val);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Reference code is required for M-Pesa';
                      }
                      if (value.trim().length < 5) {
                        return 'Enter a valid transaction reference';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Totals Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: tt.bodyMedium),
                          Text(CurrencyHelper.format(subtotal), style: tt.bodyMedium),
                        ],
                      ),
                      if (discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discounts',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '-${CurrencyHelper.format(discountAmount)}',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: groupedDiscounts.entries.map((entry) {
                              return Chip(
                                label: Text(
                                  '${entry.key}: -${CurrencyHelper.format(entry.value)}',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: cs.primaryContainer,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide.none,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total',
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            CurrencyHelper.format(total),
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // CTAs
                FilledButton(
                  onPressed: _handleCharge,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Charge ${CurrencyHelper.format(total)}',
                    style: tt.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _handleSaveAsTab,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: cs.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save as Tab',
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
