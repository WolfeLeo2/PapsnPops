import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency.dart';
import '../../../data/powersync/powersync_client.dart';
import '../../../data/repositories/branch_provider.dart';
import '../../auth/auth_provider.dart';
import '../reports_provider.dart';

class ReconciliationTab extends ConsumerWidget {
  const ReconciliationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(reconciliationsReportProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (rows) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Text(
                    'Cash Reconciliation',
                    style: theme.textTheme.titleLarge,
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log Reconciliation'),
                    onPressed: () =>
                        _showReconciliationDialog(context, ref, isDesktop),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Center(
                  child: Text('No reconciliation records for this period.'),
                )
              else
                Card(
                  elevation: 0,
                  color: cs.surfaceContainer,
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Logged By')),
                        DataColumn(label: Text('Expected Cash'), numeric: true),
                        DataColumn(label: Text('Actual Cash'), numeric: true),
                        DataColumn(label: Text('Discrepancy'), numeric: true),
                      ],
                      rows: rows.map((row) {
                        final isNegative = row.discrepancy < 0;
                        final isPositive = row.discrepancy > 0;
                        Color? discrepancyColor;
                        if (isNegative)
                          discrepancyColor = cs.error;
                        else if (isPositive)
                          discrepancyColor = Colors.orange;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormat(
                                  'MMM d, yyyy HH:mm',
                                ).format(row.date),
                              ),
                            ),
                            DataCell(Text(row.userName)),
                            DataCell(
                              Text(CurrencyHelper.format(row.expectedCash)),
                            ),
                            DataCell(
                              Text(CurrencyHelper.format(row.actualCash)),
                            ),
                            DataCell(
                              Text(
                                CurrencyHelper.format(row.discrepancy),
                                style: TextStyle(
                                  color: discrepancyColor,
                                  fontWeight: discrepancyColor != null
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

  void _showReconciliationDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDesktop,
  ) async {
    final branchId = ref.read(currentBranchIdProvider);
    if (branchId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No branch selected.')));
      return;
    }

    // Compute expected cash for today. For a real app, this should only include sales since last reconciliation.
    // For simplicity per PRD, it's sum of today's cash sales.
    final today = DateTime.now();
    final todayStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).toUtc().toIso8601String();

    final sales = await db.getAll(
      '''
      SELECT SUM(total) as expected 
      FROM sales 
      WHERE branch_id = ? 
        AND payment_method = 'cash' 
        AND (is_voided = 0 OR is_voided IS NULL)
        AND created_at >= ?
    ''',
      [branchId, todayStart],
    );

    final expectedCash = (sales.firstOrNull?['expected'] as int?) ?? 0;

    if (context.mounted) {
      if (isDesktop) {
        showDialog(
          context: context,
          builder: (context) => _ReconciliationForm(expectedCash: expectedCash),
        );
      } else {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _ReconciliationForm(expectedCash: expectedCash),
          ),
        );
      }
    }
  }
}

class _ReconciliationForm extends ConsumerStatefulWidget {
  final int expectedCash;
  const _ReconciliationForm({required this.expectedCash});

  @override
  ConsumerState<_ReconciliationForm> createState() =>
      _ReconciliationFormState();
}

class _ReconciliationFormState extends ConsumerState<_ReconciliationForm> {
  final _actualCashCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _actualCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final branchId = ref.read(currentBranchIdProvider);
    final user = ref.read(authProvider);

    if (branchId == null || user?.id == null) return;

    final actualRaw = _actualCashCtrl.text.replaceAll(',', '');
    final actualCash = (int.tryParse(actualRaw) ?? 0) * 100;
    final now = DateTime.now().toUtc().toIso8601String();

    // In schema: user_id, shift_start, shift_end, expected_cash, actual_cash, difference, notes
    await db.execute(
      '''
      INSERT INTO cash_reconciliations 
        (id, branch_id, user_id, shift_start, shift_end, expected_cash, actual_cash, difference, notes, created_at)
      VALUES (uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        branchId,
        user!.id,
        now, // shift start
        now, // shift end
        widget.expectedCash,
        actualCash,
        actualCash - widget.expectedCash,
        _notesCtrl.text,
        now,
      ],
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconciliation logged successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Reconciliation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Expected Cash'),
              trailing: Text(
                CurrencyHelper.format(widget.expectedCash),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actualCashCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual Cash Counted',
                prefixText: 'KES ',
              ),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final actualRaw = _actualCashCtrl.text.replaceAll(',', '');
                final actualCash = (int.tryParse(actualRaw) ?? 0) * 100;
                final diff = actualCash - widget.expectedCash;

                return ListTile(
                  title: const Text('Discrepancy'),
                  trailing: Text(
                    CurrencyHelper.format(diff),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: diff < 0
                          ? Theme.of(context).colorScheme.error
                          : (diff > 0 ? Colors.orange : null),
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Confirm')),
      ],
    );
  }
}
