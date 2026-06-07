import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../domain/models/sale.dart';
import '../../core/utils/currency.dart';
import '../../shared/widgets/empty_state.dart';
import 'sales_history_provider.dart';
import 'sale_detail_screen.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final salesAsync = ref.watch(salesHistoryStreamProvider);
    final selectedSaleId = ref.watch(selectedSaleIdProvider);
    final searchQuery = ref.watch(salesSearchQueryProvider);
    final paymentMethod = ref.watch(salesPaymentMethodProvider);
    final source = ref.watch(salesSourceProvider);
    final dateRange = ref.watch(salesDateRangeProvider);
    final isUnpaidOnly = ref.watch(salesUnpaidOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales & Invoices'
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: PhosphorIcon(isDesktop ? PhosphorIconsRegular.sidebar : PhosphorIconsRegular.list, size: 24),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: Search & Date Picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by ID, customer name/phone, or product...',
                          prefixIcon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, size: 20),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 18),
                                  onPressed: () => ref.read(salesSearchQueryProvider.notifier).set(''),
                                )
                              : null,
                          filled: true,
                          fillColor: cs.surfaceContainerHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (val) => ref.read(salesSearchQueryProvider.notifier).set(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date picker
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2025),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                            initialDateRange: dateRange,
                          );
                          ref.read(salesDateRangeProvider.notifier).set(range);
                        },
                        icon: const PhosphorIcon(PhosphorIconsRegular.calendar, size: 18),
                        label: Text(
                          dateRange == null
                              ? 'All Dates'
                              : '${DateFormat('dd/MM').format(dateRange.start)} - ${DateFormat('dd/MM').format(dateRange.end)}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: cs.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (dateRange != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const PhosphorIcon(PhosphorIconsRegular.xCircle, size: 20),
                        onPressed: () => ref.read(salesDateRangeProvider.notifier).set(null),
                      ),
                    ],
                  ],
                ),
              ),
                const SizedBox(height: 16),
                
                // Row 2: Payment Method chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('Payment:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: paymentMethod == null,
                        onSelected: (val) {
                          if (val) ref.read(salesPaymentMethodProvider.notifier).set(null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: paymentMethod == 'cash',
                        onSelected: (val) {
                          ref.read(salesPaymentMethodProvider.notifier).set(val ? 'cash' : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('M-Pesa'),
                        selected: paymentMethod == 'mpesa',
                        onSelected: (val) {
                          ref.read(salesPaymentMethodProvider.notifier).set(val ? 'mpesa' : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Card'),
                        selected: paymentMethod == 'card',
                        onSelected: (val) {
                          ref.read(salesPaymentMethodProvider.notifier).set(val ? 'card' : null);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Row 3: Source chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('Source:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: source == null,
                        onSelected: (val) {
                          if (val) ref.read(salesSourceProvider.notifier).set(null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('POS'),
                        selected: source == 'pos',
                        onSelected: (val) {
                          ref.read(salesSourceProvider.notifier).set(val ? 'pos' : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Tab'),
                        selected: source == 'tab',
                        onSelected: (val) {
                          ref.read(salesSourceProvider.notifier).set(val ? 'tab' : null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Invoice'),
                        selected: source == 'invoice',
                        onSelected: (val) {
                          ref.read(salesSourceProvider.notifier).set(val ? 'invoice' : null);
                        },
                      ),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 24, color: cs.outlineVariant),
                      const SizedBox(width: 16),
                      FilterChip(
                        label: const Text('Unpaid'),
                        selected: isUnpaidOnly,
                        onSelected: (val) {
                          ref.read(salesUnpaidOnlyProvider.notifier).toggle();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main list / Detail layout
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                // Handle selected sale defaults on desktop
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (sales.isEmpty) {
                    if (ref.read(selectedSaleIdProvider) != null) {
                      ref.read(selectedSaleIdProvider.notifier).select(null);
                    }
                  } else {
                    final current = ref.read(selectedSaleIdProvider);
                    if (current == null || !sales.any((s) => s.id == current)) {
                      ref.read(selectedSaleIdProvider.notifier).select(sales.first.id);
                    }
                  }
                });

                if (sales.isEmpty) {
                  return const EmptyState(
                    title: 'No sales records found',
                    message: 'Try adjusting your filters or search query.',
                    icon: PhosphorIconsDuotone.receipt,
                  );
                }

                if (isDesktop) {
                  return Row(
                    children: [
                      // List Panel
                      Expanded(
                        flex: 5,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: sales.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final sale = sales[index];
                            final isSelected = selectedSaleId == sale.id;
                            return _buildSaleRow(context, ref, sale, isSelected, cs, tt);
                          },
                        ),
                      ),
                      // Detail Panel
                      Expanded(
                        flex: 6,
                        child: selectedSaleId != null
                            ? SaleDetailScreen(
                                key: ValueKey(selectedSaleId),
                                saleId: selectedSaleId,
                              )
                            : Container(
                                color: cs.surfaceContainerLow,
                                child: Center(
                                  child: Text(
                                    'Select a sale to view details',
                                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                } else {
                  // Mobile list
                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: sales.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return _buildSaleRow(context, ref, sale, false, cs, tt);
                    },
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Error: $err', style: tt.bodyLarge?.copyWith(color: cs.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleRow(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    bool isSelected,
    ColorScheme cs,
    TextTheme tt,
  ) {
    IconData payIcon;
    switch (sale.paymentMethod) {
      case 'cash':
        payIcon = PhosphorIconsRegular.money;
        break;
      case 'mpesa':
        payIcon = PhosphorIconsRegular.phone;
        break;
      case 'card':
        payIcon = PhosphorIconsRegular.creditCard;
        break;
      default:
        payIcon = PhosphorIconsRegular.receipt;
    }

    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.08)
          : cs.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (isDesktop) {
            ref.read(selectedSaleIdProvider.notifier).select(sale.id);
          } else {
            // Push detail panel inside a scaffold
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Sale Detail'),
                  ),
                  body: SaleDetailScreen(
                    saleId: sale.id,
                    isMobile: true,
                  ),
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sale.isVoided
                      ? cs.errorContainer
                      : cs.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PhosphorIcon(
                  payIcon,
                  color: sale.isVoided ? cs.error : cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Time and ID
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    // Title and Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Sale #${sale.id.substring(0, 8).toUpperCase()}',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                decoration: sale.isVoided ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Source badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sale.source.toUpperCase(),
                                style: tt.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM, HH:mm').format(sale.createdAt.toLocal()),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Total
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyHelper.format(sale.total),
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: sale.isVoided ? cs.error : cs.primary,
                            decoration: sale.isVoided ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sale.isVoided)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VOIDED',
                              style: tt.labelSmall?.copyWith(
                                color: cs.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
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
        ),
      ),
    );
  }
}
