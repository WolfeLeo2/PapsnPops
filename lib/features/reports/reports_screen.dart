import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'report_export.dart';
import 'reports_provider.dart';

import 'widgets/sales_summary_tab.dart';
import 'widgets/cashier_report_tab.dart';
import 'widgets/salesperson_report_tab.dart';
import 'widgets/products_report_tab.dart';
import 'widgets/stock_levels_tab.dart';
import 'widgets/reconciliation_tab.dart';
import 'widgets/invoices_report_tab.dart';

enum ReportTab {
  salesSummary('Sales Summary', PhosphorIconsRegular.chartLineUp),
  byCashier('By Cashier', PhosphorIconsRegular.user),
  bySalesperson('By Salesperson', PhosphorIconsRegular.users),
  products('Products', PhosphorIconsRegular.package),
  stockLevels('Stock Levels', PhosphorIconsRegular.stack),
  reconciliation('Reconciliation', PhosphorIconsRegular.money),
  invoices('Invoices', PhosphorIconsRegular.receipt);

  final String label;
  final IconData icon;
  const ReportTab(this.label, this.icon);
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final selectedIndex = ref.watch(selectedReportTabProvider);
    final selectedTab = ReportTab.values[selectedIndex];
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Capture outer scaffold BEFORE building the inner Scaffold
    // so openDrawer() targets the AppScaffold's drawer, not ours
    final outerScaffold = Scaffold.maybeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => outerScaffold?.openDrawer(),
              ),
        actions: [
          IconButton(
            tooltip: 'Export as PDF',
            icon: const PhosphorIcon(PhosphorIconsRegular.filePdf),
            onPressed: () =>
                exportReportAsPdf(context: context, ref: ref, tab: selectedTab),
          ),
          IconButton(
            tooltip: 'Export as CSV',
            icon: const PhosphorIcon(PhosphorIconsRegular.fileCsv),
            onPressed: () =>
                exportReportAsCsv(context: context, ref: ref, tab: selectedTab),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter Bar — edge to edge, no horizontal padding
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                bottom: BorderSide(color: cs.outline.withAlpha(80)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const DateFilterChips(),
            ),
          ),

          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      // Desktop nav rail (sidebar)
                      SizedBox(
                        width: 216,
                        child: Material(
                          color: cs.surfaceContainer,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            children: List.generate(ReportTab.values.length, (
                              i,
                            ) {
                              final tab = ReportTab.values[i];
                              final isSelected = selectedIndex == i;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: ListTile(
                                  leading: PhosphorIcon(
                                    isSelected ? tab.icon : tab.icon,
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  title: Text(
                                    tab.label,
                                    style: tt.labelLarge?.copyWith(
                                      color: isSelected
                                          ? cs.primary
                                          : cs.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedTileColor: cs.primaryContainer
                                      .withAlpha(100),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  dense: true,
                                  onTap: () => ref
                                      .read(selectedReportTabProvider.notifier)
                                      .select(i),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: cs.outline.withAlpha(80),
                      ),
                      // Main content
                      Expanded(child: _buildTabContent(selectedTab)),
                    ],
                  )
                : Column(
                    children: [
                      // Mobile: horizontal chip scroll
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: ReportTab.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final tab = ReportTab.values[i];
                            return ChoiceChip(
                              label: Text(tab.label),
                              selected: selectedIndex == i,
                              onSelected: (val) {
                                if (val) {
                                  ref
                                      .read(selectedReportTabProvider.notifier)
                                      .select(i);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      Expanded(child: _buildTabContent(selectedTab)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ReportTab tab) {
    return switch (tab) {
      ReportTab.salesSummary => const SalesSummaryTab(),
      ReportTab.byCashier => const CashierReportTab(),
      ReportTab.bySalesperson => const SalespersonReportTab(),
      ReportTab.products => const ProductsReportTab(),
      ReportTab.stockLevels => const StockLevelsTab(),
      ReportTab.reconciliation => const ReconciliationTab(),
      ReportTab.invoices => const InvoicesReportTab(),
    };
  }
}

// ── Date Filter Chips ──────────────────────────────────────────────────

class DateFilterChips extends ConsumerWidget {
  const DateFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedReportPeriodProvider);
    final customRange = ref.watch(customReportDateRangeProvider);

    return Row(
      children: [
        _chip(ref, 'Today', ReportPeriod.today, period),
        const SizedBox(width: 8),
        _chip(ref, 'Yesterday', ReportPeriod.yesterday, period),
        const SizedBox(width: 8),
        _chip(ref, 'This Week', ReportPeriod.thisWeek, period),
        const SizedBox(width: 8),
        _chip(ref, 'This Month', ReportPeriod.thisMonth, period),
        const SizedBox(width: 8),
        ActionChip(
          label: Text(
            period == ReportPeriod.custom && customRange != null
                ? "${DateFormat('MMM d').format(customRange.from)} – ${DateFormat('MMM d').format(customRange.to)}"
                : 'Custom Range',
          ),
          avatar: const Icon(Icons.date_range, size: 16),
          backgroundColor: period == ReportPeriod.custom
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 5),
              lastDate: now,
              initialDateRange: customRange != null
                  ? DateTimeRange(start: customRange.from, end: customRange.to)
                  : DateTimeRange(
                      start: now.subtract(const Duration(days: 7)),
                      end: now,
                    ),
            );
            if (picked != null) {
              ref
                  .read(customReportDateRangeProvider.notifier)
                  .set(
                    ReportDateRange(
                      from: DateTime(
                        picked.start.year,
                        picked.start.month,
                        picked.start.day,
                      ),
                      to: DateTime(
                        picked.end.year,
                        picked.end.month,
                        picked.end.day,
                        23,
                        59,
                        59,
                        999,
                      ),
                    ),
                  );
              ref
                  .read(selectedReportPeriodProvider.notifier)
                  .set(ReportPeriod.custom);
            }
          },
        ),
      ],
    );
  }

  Widget _chip(
    WidgetRef ref,
    String label,
    ReportPeriod value,
    ReportPeriod current,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: current == value,
      onSelected: (selected) {
        if (selected) {
          ref.read(selectedReportPeriodProvider.notifier).set(value);
        }
      },
    );
  }
}
