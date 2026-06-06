import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency.dart';
import '../../../data/powersync/powersync_client.dart';
import '../reports_provider.dart';

class InvoicesReportTab extends ConsumerWidget {
  const InvoicesReportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(invoicesReportProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rows) {
        int totalInvoiced = 0;
        int paid = 0;
        int outstanding = 0;
        int overdue = 0;

        for (final row in rows) {
          totalInvoiced += row.totalAmount;
          if (row.status == 'paid') {
            paid += row.totalAmount;
          } else if (row.status == 'overdue') {
            overdue += row.totalAmount;
          } else {
            outstanding += row.totalAmount;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Invoices Report', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              // KPI Chips
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    context,
                    'Total Invoiced',
                    totalInvoiced,
                    cs.primary,
                  ),
                  _buildMetricCard(context, 'Paid', paid, Colors.green),
                  _buildMetricCard(
                    context,
                    'Outstanding',
                    outstanding,
                    Colors.orange,
                  ),
                  _buildMetricCard(context, 'Overdue', overdue, cs.error),
                ],
              ),
              const SizedBox(height: 32),

              if (rows.isEmpty)
                const Center(child: Text('No invoices for this period.'))
              else
                Card(
                  elevation: 0,
                  color: cs.surfaceContainer,
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Invoice #')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Due Date')),
                        DataColumn(label: Text('Amount'), numeric: true),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: rows.map((row) {
                        Color statusColor;
                        if (row.status == 'paid') {
                          statusColor = Colors.green;
                        } else if (row.status == 'overdue')
                          statusColor = cs.error;
                        else
                          statusColor = Colors.orange;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                row.invoiceNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(row.customerName)),
                            DataCell(
                              Text(
                                DateFormat('MMM d, yyyy').format(row.createdAt),
                              ),
                            ),
                            DataCell(
                              Text(
                                row.dueDate != null
                                    ? DateFormat(
                                        'MMM d, yyyy',
                                      ).format(row.dueDate!)
                                    : '-',
                              ),
                            ),
                            DataCell(
                              Text(CurrencyHelper.format(row.totalAmount)),
                            ),
                            DataCell(
                              Chip(
                                label: Text(row.status.toUpperCase()),
                                backgroundColor: statusColor.withValues(alpha: 0.1),
                                labelStyle: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            DataCell(
                              row.status != 'paid'
                                  ? TextButton(
                                      onPressed: () =>
                                          _markAsPaid(context, row.id),
                                      child: const Text('Mark Paid'),
                                    )
                                  : const SizedBox.shrink(),
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

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    int amount,
    Color color,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context, String invoiceId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await db.execute(
      '''
      UPDATE invoices
      SET status = 'paid', paid_at = ?
      WHERE id = ?
    ''',
      [now, invoiceId],
    );

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice marked as paid.')));
    }
  }
}
