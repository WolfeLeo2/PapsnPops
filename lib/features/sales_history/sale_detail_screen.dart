import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'widgets/log_payment_dialog.dart';
import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/invoice.dart';
import '../../../core/utils/currency.dart';
import '../../../data/repositories/sale_repository.dart';
import '../auth/auth_provider.dart';
import '../../../data/powersync/powersync_client.dart';
import '../pos/widgets/receipt_screen.dart' show generateReceiptPdf;
import 'sales_history_provider.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String saleId;
  final bool isMobile;

  const SaleDetailScreen({
    super.key,
    required this.saleId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final detailAsync = ref.watch(saleDetailProvider(saleId));
    final currentUser = ref.watch(authProvider);
    final isOwner = currentUser?.userMetadata?['role'] == 'owner';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(color: cs.outline, width: isMobile ? 0 : 1),
        ),
      ),
      child: detailAsync.when(
        data: (data) {
          final sale = data['sale'] as Sale;
          final items = data['items'] as List<SaleItem>;
          final customer = data['customer'] as Customer?;
          final invoice = data['invoice'] as Invoice?;
          final totalPaid = data['totalPaid'] as int? ?? 0;
          final cashierName = data['cashierName'] as String;
          final staffName = data['staffName'] as String?;

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Detail Content Scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sale #${sale.id.substring(0, 8).toUpperCase()}',
                                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm:ss').format(sale.createdAt.toLocal()),
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sale.source.toUpperCase(),
                                  style: tt.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Metadata section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetaItem('Cashier', cashierName, cs, tt),
                              if (staffName != null)
                                _buildMetaItem('Salesperson', staffName, cs, tt),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Invoice B2B Details
                          if (invoice != null) ...[
                            _buildInvoiceSection(context, ref, sale, invoice, customer, totalPaid, cs, tt),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],

                          // Items Title
                          Text('Items Sold', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          // Table Header
                          Container(
                            color: cs.surfaceContainerLow,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('Product Option', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
                                Expanded(child: Text('Qty', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                Expanded(child: Text('Price', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                Expanded(child: Text('Total', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          
                          // Items Rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.variantName,
                                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          if (item.discountAmount > 0)
                                            Text(
                                              'Discount: -${CurrencyHelper.format(item.discountAmount)}',
                                              style: tt.bodySmall?.copyWith(color: cs.error),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}',
                                        style: tt.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        CurrencyHelper.format(item.unitPrice),
                                        style: tt.bodyMedium,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        CurrencyHelper.format(item.lineTotal),
                                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Totals Summary
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 300,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTotalRow('Subtotal', CurrencyHelper.format(sale.subtotal), cs, tt),
                                  if (sale.discountAmount > 0) ...[
                                    const SizedBox(height: 8),
                                    _buildTotalRow('Discounts', '-${CurrencyHelper.format(sale.discountAmount)}', cs, tt, valueColor: cs.error),
                                  ],
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  _buildTotalRow(
                                    'Grand Total',
                                    CurrencyHelper.format(sale.total),
                                    cs,
                                    tt,
                                    isBold: true,
                                    fontSize: 18,
                                    valueColor: cs.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Payment Details
                          Text('Payment Details', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outline),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow('Payment Method', sale.paymentMethod.toUpperCase(), cs, tt),
                                if (sale.paymentReference != null) ...[
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Transaction Reference', sale.paymentReference!, cs, tt, isBold: true),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Sticky bottom actions bar
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(top: BorderSide(color: cs.outline)),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        if (isOwner && !sale.isVoided)
                          OutlinedButton.icon(
                            onPressed: () => _voidSale(context, ref, sale.id),
                            icon: const PhosphorIcon(PhosphorIconsRegular.trash, size: 16),
                            label: const Text('Void Sale'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.error,
                              side: BorderSide(color: cs.error),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _shareReceipt(ref, sale, items, customer, invoice, cashierName, staffName),
                          icon: const PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 16),
                          label: const Text('Share Receipt'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _printReceipt(ref, sale, items, customer, invoice, cashierName, staffName),
                          icon: const PhosphorIcon(PhosphorIconsRegular.printer, size: 16),
                          label: const Text('Print Receipt'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Void watermark overlay
              if (sale.isVoided)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: cs.error.withValues(alpha: 0.05),
                      child: Center(
                        child: RotationTransition(
                          turns: const AlwaysStoppedAnimation(-15 / 360),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.error, width: 4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'VOIDED',
                                  style: tt.displayMedium?.copyWith(
                                    color: cs.error,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                if (sale.voidedAt != null)
                                  Text(
                                    'At ${DateFormat('dd/MM HH:mm').format(sale.voidedAt!.toLocal())}',
                                    style: tt.titleSmall?.copyWith(color: cs.error, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: tt.bodyLarge?.copyWith(color: cs.error)),
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, ColorScheme cs, TextTheme tt, {bool isBold = false, double? fontSize, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme cs, TextTheme tt, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection(
    BuildContext context,
    WidgetRef ref,
    Sale sale,
    Invoice invoice,
    Customer? customer,
    int totalPaid,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final isPaid = invoice.status == 'paid';
    final balance = sale.total - totalPaid;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'B2B Invoice Details',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE8EB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  invoice.status.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPaid ? const Color(0xFF166534) : const Color(0xFFCC1F35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Invoice Number', invoice.invoiceNumber, cs, tt),
          const SizedBox(height: 6),
          if (invoice.dueDate != null)
            _buildDetailRow('Due Date', DateFormat('dd MMM yyyy').format(invoice.dueDate!), cs, tt),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          
          _buildDetailRow('Total Paid', CurrencyHelper.format(totalPaid), cs, tt),
          const SizedBox(height: 4),
          _buildDetailRow('Balance Due', CurrencyHelper.format(balance), cs, tt, isBold: true),
          
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          
          // Customer details
          if (customer != null) ...[
            Text('Client Details', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildDetailRow('Client Name', customer.name, cs, tt),
            const SizedBox(height: 4),
            _buildDetailRow('Phone', customer.phone, cs, tt),
            if (customer.companyName != null && customer.companyName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildDetailRow('Company', customer.companyName!, cs, tt),
            ],
            if (customer.address != null && customer.address!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildDetailRow('Address', customer.address!, cs, tt),
            ],
          ],

          if (!isPaid) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _logPayment(context, ref, sale, invoice, balance),
              icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 16),
              label: const Text('Log Payment'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _logPayment(BuildContext context, WidgetRef ref, Sale sale, Invoice invoice, int balanceDue) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => LogPaymentDialog(
        invoiceId: invoice.id,
        branchId: sale.branchId,
        balanceDue: balanceDue,
      ),
    );

    if (result == true) {
      ref.invalidate(saleDetailProvider(sale.id));
    }
  }

  void _voidSale(BuildContext context, WidgetRef ref, String saleId) async {
    final scaffold = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Sale'),
        content: const Text('Are you sure you want to void this sale? Stock levels will be restored and this transaction will be reversed. This action cannot be undone.'),
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

    if (confirm == true) {
      final currentUser = ref.read(authProvider);
      if (currentUser == null) return;
      
      try {
        await ref.read(saleRepositoryProvider).voidSale(saleId, currentUser.id);
        scaffold.showSnackBar(const SnackBar(content: Text('Sale voided successfully')));
        
        // Refresh details and list
        ref.invalidate(saleDetailProvider(saleId));
        ref.invalidate(salesHistoryStreamProvider);
      } catch (e) {
        scaffold.showSnackBar(SnackBar(content: Text('Error voiding sale: $e')));
      }
    }
  }

  void _printReceipt(
    WidgetRef ref,
    Sale sale,
    List<SaleItem> items,
    Customer? customer,
    Invoice? invoice,
    String cashierName,
    String? staffName,
  ) async {
    final branchRow = await db.getOptional(
      'SELECT name FROM branches WHERE id = ?',
      [sale.branchId],
    );
    final branchName = branchRow?['name'] as String? ?? 'Liquor Till';

    final bytes = await generateReceiptPdf(
      sale: sale,
      items: items,
      branchName: branchName,
      cashierName: cashierName,
      staffName: staffName,
      invoice: invoice,
      customer: customer,
    );

    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  void _shareReceipt(
    WidgetRef ref,
    Sale sale,
    List<SaleItem> items,
    Customer? customer,
    Invoice? invoice,
    String cashierName,
    String? staffName,
  ) async {
    final branchRow = await db.getOptional(
      'SELECT name FROM branches WHERE id = ?',
      [sale.branchId],
    );
    final branchName = branchRow?['name'] as String? ?? 'Liquor Till';

    final bytes = await generateReceiptPdf(
      sale: sale,
      items: items,
      branchName: branchName,
      cashierName: cashierName,
      staffName: staffName,
      invoice: invoice,
      customer: customer,
    );

    await Printing.sharePdf(bytes: bytes, filename: 'receipt_${sale.id.substring(0, 8)}.pdf');
  }
}
