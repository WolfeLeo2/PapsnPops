import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../reports_provider.dart';

class StockLevelsTab extends ConsumerStatefulWidget {
  const StockLevelsTab({super.key});

  @override
  ConsumerState<StockLevelsTab> createState() => _StockLevelsTabState();
}

class _StockLevelsTabState extends ConsumerState<StockLevelsTab> {
  String _filter = 'All'; // All, Low, Out

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(stockLevelsReportProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rows) {
        int lowCount = 0;
        int outCount = 0;

        for (final row in rows) {
          if (row.quantity <= 0)
            outCount++;
          else if (row.quantity <= row.reorderLevel)
            lowCount++;
        }

        final filteredRows = rows.where((row) {
          if (_filter == 'Low')
            return row.quantity > 0 && row.quantity <= row.reorderLevel;
          if (_filter == 'Out') return row.quantity <= 0;
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Stock Levels', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(
                    context,
                    'All',
                    rows.length,
                    cs.primary,
                    'All',
                  ),
                  _buildStatusChip(
                    context,
                    'Low Stock',
                    lowCount,
                    cs.error,
                    'Low',
                  ),
                  _buildStatusChip(
                    context,
                    'Out of Stock',
                    outCount,
                    cs.error,
                    'Out',
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
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Quantity'), numeric: true),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Last Received')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: filteredRows.map((row) {
                      final isOut = row.quantity <= 0;
                      final isLow =
                          row.quantity > 0 && row.quantity <= row.reorderLevel;
                      final statusColor = isOut
                          ? cs.error
                          : (isLow ? cs.error : cs.primary);
                      final maxBar = (row.reorderLevel * 2).clamp(1, 9999);
                      final percent = (row.quantity / maxBar).clamp(0.0, 1.0);

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
                          DataCell(Text(row.quantity.toString())),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    color: statusColor,
                                    backgroundColor: cs.outlineVariant
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isOut)
                                  Text(
                                    'OUT',
                                    style: TextStyle(
                                      color: cs.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else if (isLow)
                                  Text(
                                    'LOW',
                                    style: TextStyle(
                                      color: cs.error,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else
                                  const Text(
                                    'OK',
                                    style: TextStyle(fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              row.lastReceivedAt != null
                                  ? DateFormat(
                                      'MMM d, yyyy',
                                    ).format(row.lastReceivedAt!)
                                  : '-',
                            ),
                          ),
                          DataCell(
                            TextButton(
                              onPressed: () {
                                // For now, just navigate to stock page.
                                // Ideally, we pass the product to pre-select it.
                                context.go('/pos/stock');
                              },
                              child: const Text('Receive'),
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

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    int count,
    Color color,
    String filterValue,
  ) {
    final isSelected = _filter == filterValue;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = filterValue);
      },
    );
  }
}
