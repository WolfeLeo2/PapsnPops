import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/open_tab.dart';
import '../../../domain/models/tab_item.dart';
import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';
import '../../../core/utils/currency.dart';
import '../../../data/repositories/tab_repository.dart';
import '../../../data/repositories/branch_provider.dart';
import '../../auth/auth_provider.dart';
import '../../stock/stock_provider.dart' show generateV4Uuid;
import '../../../data/powersync/powersync_client.dart';
import '../../pos/pos_provider.dart' show activeStaffProvider;
import '../../pos/widgets/receipt_screen.dart';
import '../../../shared/widgets/qty_stepper.dart';
import '../tabs_provider.dart';
import 'tab_add_item_sheet.dart';

class TabDetailPanel extends ConsumerStatefulWidget {
  final OpenTab tab;
  final bool isMobile;

  const TabDetailPanel({
    super.key,
    required this.tab,
    this.isMobile = false,
  });

  @override
  ConsumerState<TabDetailPanel> createState() => _TabDetailPanelState();
}

class _TabDetailPanelState extends ConsumerState<TabDetailPanel> {
  // Local list of staff for easy lookup of names
  Map<String, String> _staffNames = {};

  @override
  void initState() {
    super.initState();
    _loadStaffNames();
  }

  void _loadStaffNames() async {
    final staffAsync = ref.read(activeStaffProvider);
    staffAsync.whenData((staffList) {
      if (mounted) {
        setState(() {
          _staffNames = {
            for (final s in staffList) s['id'] as String: s['name'] as String
          };
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final itemsAsync = ref.watch(tabItemsProvider(widget.tab.id));
    final totalAsync = ref.watch(tabTotalProvider(widget.tab.id));

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(color: cs.outline, width: widget.isMobile ? 0 : 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tab.name,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (widget.tab.phone != null && widget.tab.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${widget.tab.phone}',
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Opened at ${DateFormat('dd MMM yyyy, HH:mm').format(widget.tab.createdAt.toLocal())}',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => TabAddItemSheet.show(
                    context: context,
                    tab: widget.tab,
                  ),
                  icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 16),
                  label: const Text('Add Items'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items list grouped by rounds
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.receipt,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This tab is empty',
                          style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => TabAddItemSheet.show(
                            context: context,
                            tab: widget.tab,
                          ),
                          child: const Text('Add some items now'),
                        ),
                      ],
                    ),
                  );
                }

                // Group tab items by rounds (timestamp within 2 minutes)
                final rounds = _groupTabItems(items);

                return ListView.separated(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: rounds.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final round = rounds[index];
                    final isNewest = index == 0;
                    final timeStr = DateFormat('HH:mm').format(round.timestamp.toLocal());
                    final staffName = round.items.first.addedBy != null
                        ? _staffNames[round.items.first.addedBy]
                        : null;

                    return Container(
                      decoration: BoxDecoration(
                        color: isNewest
                            ? cs.primaryContainer.withValues(alpha: 0.08)
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNewest ? cs.primary.withValues(alpha: 0.2) : cs.outline,
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Round Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isNewest ? 'Latest Round — $timeStr' : 'Round — $timeStr',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isNewest ? cs.primary : cs.onSurface,
                                ),
                              ),
                              if (staffName != null)
                                Text(
                                  'Served by $staffName',
                                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // Round Items
                          ...round.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.variantName,
                                          style: tt.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '${CurrencyHelper.format(item.unitPrice)} each',
                                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Qty stepper
                                  QtyStepper(
                                    quantity: item.quantity,
                                    minQuantity: 0,
                                    onChanged: (newQty) => _updateQuantity(item.id, newQty),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    CurrencyHelper.format(item.quantity * item.unitPrice),
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Error: $err', style: tt.bodyLarge?.copyWith(color: cs.error)),
              ),
            ),
          ),

          const Divider(height: 1),

          // Footer & Primary CTAs
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Outstanding',
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    totalAsync.when(
                      data: (total) => Text(
                        CurrencyHelper.format(total),
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                      loading: () => Text('...', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      error: (_, _) => Text('KES 0', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (ref.watch(authProvider.notifier).state?.userMetadata?['role'] == 'owner')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _voidTab,
                          icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 16),
                          label: const Text('Void Tab'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.error,
                            side: BorderSide(color: cs.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (ref.watch(authProvider.notifier).state?.userMetadata?['role'] == 'owner')
                      const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          itemsAsync.whenData((items) {
                            if (items.isNotEmpty) {
                              _showCheckoutDialog(items);
                            }
                          });
                        },
                        icon: const PhosphorIcon(PhosphorIconsRegular.checkCircle, size: 18),
                        label: const Text('Close & Charge'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String itemId, int newQty) async {
    final repo = ref.read(tabRepositoryProvider);
    if (newQty <= 0) {
      await repo.removeTabItem(itemId);
    } else {
      await repo.updateTabItemQuantity(itemId, newQty);
    }
  }

  void _voidTab() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Tab'),
        content: const Text('Are you sure you want to void this tab? All items will be deleted and this action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Void'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final scaffold = ScaffoldMessenger.of(context);
      try {
        // Void tab simply deletes items and sets tab to closed but without sale ID
        await db.writeTransaction((tx) async {
          final now = DateTime.now().toIso8601String();
          await tx.execute('UPDATE open_tabs SET is_open = 0, closed_at = ?, updated_at = ? WHERE id = ?', [now, now, widget.tab.id]);
          await tx.execute('DELETE FROM tab_items WHERE tab_id = ?', [widget.tab.id]);
        });
        scaffold.showSnackBar(
          const SnackBar(content: Text('Tab voided successfully')),
        );
        if (widget.isMobile && mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Error voiding tab: $e')),
        );
      }
    }
  }

  void _showCheckoutDialog(List<TabItem> items) async {
    String paymentMethod = 'cash';
    final refController = TextEditingController();
    String? staffId;
    
    final staffAsync = ref.read(activeStaffProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tab Checkout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment Method Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: paymentMethod == 'cash',
                      onSelected: (val) {
                        if (val) setDialogState(() => paymentMethod = 'cash');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('M-Pesa'),
                      selected: paymentMethod == 'mpesa',
                      onSelected: (val) {
                        if (val) setDialogState(() => paymentMethod = 'mpesa');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Card'),
                      selected: paymentMethod == 'card',
                      onSelected: (val) {
                        if (val) setDialogState(() => paymentMethod = 'card');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // M-Pesa Ref if M-Pesa selected
                if (paymentMethod == 'mpesa') ...[
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(
                      labelText: 'M-Pesa Reference',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                ],

                // Salesperson dropdown
                staffAsync.when(
                  data: (staffList) {
                    return DropdownButtonFormField<String>(
                      initialValue: staffId,
                      hint: const Text('Salesperson'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: staffList.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['id'] as String,
                          child: Text(s['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => staffId = val),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (paymentMethod == 'mpesa' && refController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter M-Pesa reference')),
                    );
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text('Charge'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      final scaffold = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final authState = ref.read(authProvider);
      final branchId = ref.read(currentBranchIdProvider);

      if (authState == null || branchId == null) return;

      final saleId = generateV4Uuid();
      final total = items.fold<int>(0, (sum, i) => sum + (i.quantity * i.unitPrice));

      final sale = Sale(
        id: saleId,
        branchId: branchId,
        cashierId: authState.id,
        staffId: staffId,
        customerId: widget.tab.customerId,
        paymentMethod: paymentMethod,
        paymentReference: paymentMethod == 'mpesa' ? refController.text.trim().toUpperCase() : null,
        subtotal: total,
        discountAmount: 0,
        total: total,
        isVoided: false,
        source: 'tab',
        tabId: widget.tab.id,
        createdAt: DateTime.now(),
      );

      final saleItems = items.map((i) {
        return SaleItem(
          id: generateV4Uuid(),
          saleId: saleId,
          productId: i.productId,
          variantId: i.variantId,
          variantName: i.variantName,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
          costPrice: 0, // Placeholder
          discountAmount: 0,
          lineTotal: i.quantity * i.unitPrice,
        );
      }).toList();

      try {
        await ref.read(tabRepositoryProvider).closeTab(widget.tab.id, sale, saleItems);
        scaffold.showSnackBar(const SnackBar(content: Text('Tab closed and charged successfully')));
        
        // Show receipt screen in modal or push
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => Dialog.fullscreen(
              child: ReceiptScreen(
                sale: sale,
                items: saleItems,
              ),
            ),
          );
        }
        
        if (widget.isMobile) {
          nav.pop();
        }
      } catch (e) {
        scaffold.showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    }
  }

  // Toast-inspired grouping of tab items added around the same time (within 2-min window)
  List<TabRound> _groupTabItems(List<TabItem> items) {
    if (items.isEmpty) return [];
    
    // Sort items by createdAt ASC so we process sequentially
    final sorted = List<TabItem>.from(items)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    final List<TabRound> rounds = [];
    for (final item in sorted) {
      if (rounds.isEmpty) {
        rounds.add(TabRound(timestamp: item.createdAt, items: [item]));
      } else {
        final lastRound = rounds.last;
        final diff = item.createdAt.difference(lastRound.timestamp).abs();
        if (diff.inMinutes <= 2) {
          lastRound.items.add(item);
        } else {
          rounds.add(TabRound(timestamp: item.createdAt, items: [item]));
        }
      }
    }
    // Return with newest rounds first
    return rounds.reversed.toList();
  }
}

class TabRound {
  final DateTime timestamp;
  final List<TabItem> items;

  TabRound({
    required this.timestamp,
    required this.items,
  });
}
