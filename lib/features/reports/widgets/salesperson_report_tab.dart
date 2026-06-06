import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../reports_provider.dart';

class SalespersonReportTab extends ConsumerWidget {
  const SalespersonReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(salespersonReportProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Text('No salesperson data for this period.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sales by Floor Salesperson',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Salesperson')),
                      DataColumn(label: Text('Sales Count'), numeric: true),
                      DataColumn(label: Text('Revenue'), numeric: true),
                      DataColumn(label: Text('Avg Sale'), numeric: true),
                      DataColumn(label: Text('% of Total'), numeric: true),
                    ],
                    rows: rows.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              row.staffName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(row.salesCount.toString())),
                          DataCell(Text(CurrencyHelper.format(row.revenue))),
                          DataCell(
                            Text(CurrencyHelper.format(row.averageSale)),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${row.percentageOfTotal.toStringAsFixed(1)}%',
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 50,
                                  child: LinearProgressIndicator(
                                    value: row.percentageOfTotal / 100,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ],
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
