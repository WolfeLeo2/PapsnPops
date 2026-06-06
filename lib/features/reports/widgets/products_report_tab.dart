import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../reports_provider.dart';

class ProductsReportTab extends ConsumerStatefulWidget {
  const ProductsReportTab({super.key});

  @override
  ConsumerState<ProductsReportTab> createState() => _ProductsReportTabState();
}

class _ProductsReportTabState extends ConsumerState<ProductsReportTab> {
  bool _showTopSellers = true;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(productsReportProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('No product data for this period.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Products Report', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Top 10 Sellers')),
                      ButtonSegment(value: false, label: Text('All Products')),
                    ],
                    selected: {_showTopSellers},
                    onSelectionChanged: (set) =>
                        setState(() => _showTopSellers = set.first),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: cs.surfaceContainer,
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _showTopSellers
                        ? 3
                        : 0, // Simplified sorting
                    sortAscending: false,
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Units Sold'), numeric: true),
                      DataColumn(label: Text('Revenue'), numeric: true),
                      DataColumn(label: Text('Cost'), numeric: true),
                      DataColumn(label: Text('Profit'), numeric: true),
                      DataColumn(label: Text('Margin %'), numeric: true),
                    ],
                    rows: rows.take(_showTopSellers ? 10 : rows.length).map((
                      row,
                    ) {
                      final isLowMargin = row.marginPercent < 20.0;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              row.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(row.category)),
                          DataCell(
                            row.unitsSold == 0
                                ? Chip(
                                    label: const Text('Slow Mover'),
                                    backgroundColor: cs.errorContainer,
                                    labelStyle: TextStyle(
                                      color: cs.error,
                                      fontSize: 10,
                                    ),
                                    padding: EdgeInsets.zero,
                                  )
                                : Text(row.unitsSold.toString()),
                          ),
                          DataCell(Text(CurrencyHelper.format(row.revenue))),
                          DataCell(Text(CurrencyHelper.format(row.cost))),
                          DataCell(Text(CurrencyHelper.format(row.profit))),
                          DataCell(
                            Text(
                              '${row.marginPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isLowMargin ? cs.error : null,
                                fontWeight: isLowMargin
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
