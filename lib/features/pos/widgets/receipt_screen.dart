import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';
import '../../../domain/models/invoice.dart';
import '../../../domain/models/customer.dart';
import '../../../core/utils/currency.dart';
import '../../../data/powersync/powersync_client.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final Sale sale;
  final List<SaleItem> items;
  final Invoice? invoice;

  const ReceiptScreen({
    super.key,
    required this.sale,
    required this.items,
    this.invoice,
  });

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  String? _branchName;
  String? _cashierName;
  String? _staffName;
  Customer? _customer;
  bool _isLoadingMetadata = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  void _loadMetadata() async {
    try {
      final branchRow = await db.getOptional(
        'SELECT name FROM branches WHERE id = ?',
        [widget.sale.branchId],
      );
      final cashierRow = await db.getOptional(
        'SELECT full_name FROM user_profiles WHERE id = ?',
        [widget.sale.cashierId],
      );
      
      String? staffName;
      if (widget.sale.staffId != null) {
        final staffRow = await db.getOptional(
          'SELECT name FROM staff WHERE id = ?',
          [widget.sale.staffId],
        );
        staffName = staffRow?['name'] as String?;
      }

      Customer? customer;
      if (widget.sale.customerId != null) {
        final custRow = await db.getOptional(
          'SELECT * FROM customers WHERE id = ?',
          [widget.sale.customerId],
        );
        if (custRow != null) {
          customer = Customer.fromRow(custRow);
        }
      }

      if (mounted) {
        setState(() {
          _branchName = branchRow?['name'] as String? ?? 'Liquor Till';
          _cashierName = cashierRow?['full_name'] as String? ?? 'Cashier';
          _staffName = staffName;
          _customer = customer;
          _isLoadingMetadata = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMetadata = false;
        });
      }
    }
  }

  Future<Uint8List> _generatePdf() async {
    return generateReceiptPdf(
      sale: widget.sale,
      items: widget.items,
      branchName: _branchName,
      cashierName: _cashierName,
      staffName: _staffName,
      invoice: widget.invoice,
      customer: _customer,
    );
  }

  void _handlePrint() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'receipt_${widget.sale.id.substring(0, 8)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print receipt: $e')),
        );
      }
    }
  }

  void _handleShare() async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'receipt_${widget.sale.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share receipt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Checkout Success'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.printer),
            tooltip: 'Print Receipt',
            onPressed: _handlePrint,
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.shareNetwork),
            tooltip: 'Share PDF',
            onPressed: _handleShare,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingMetadata
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Success Checkmark
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: PhosphorIcon(
                            PhosphorIconsRegular.check,
                            size: 48,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Transaction Complete',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyHelper.format(widget.sale.total),
                          style: tt.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Receipt Details Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
                          ),
                          color: cs.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Metadata list
                                _buildDetailRow(cs, tt, 'Branch', _branchName ?? ''),
                                _buildDetailRow(cs, tt, 'Cashier', _cashierName ?? ''),
                                if (_staffName != null)
                                  _buildDetailRow(cs, tt, 'Served By', _staffName!),
                                if (_customer != null)
                                  _buildDetailRow(cs, tt, 'Customer', _customer!.name),
                                if (widget.invoice != null) ...[
                                  _buildDetailRow(cs, tt, 'Invoice Number', widget.invoice!.invoiceNumber, isBold: true),
                                  _buildDetailRow(cs, tt, 'Due Date', widget.invoice!.dueDate != null 
                                      ? '${widget.invoice!.dueDate!.day}/${widget.invoice!.dueDate!.month}/${widget.invoice!.dueDate!.year}'
                                      : ''),
                                ],
                                _buildDetailRow(
                                  cs,
                                  tt,
                                  'Payment Method',
                                  widget.sale.paymentMethod.toUpperCase(),
                                ),
                                if (widget.sale.paymentReference != null)
                                  _buildDetailRow(cs, tt, 'M-Pesa Ref', widget.sale.paymentReference!, isBold: true),
                                _buildDetailRow(
                                  cs,
                                  tt,
                                  'Date & Time',
                                  widget.sale.createdAt.toLocal().toString().substring(0, 19),
                                ),
                                
                                const Divider(height: 24),
                                Text(
                                  'Items Purchased',
                                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),

                                // Items List
                                ...widget.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.variantName ?? 'Product',
                                                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              if (item.discountAmount > 0)
                                                Text(
                                                  'Promo Discount: -${CurrencyHelper.format(item.discountAmount)}',
                                                  style: tt.bodySmall?.copyWith(color: cs.primary),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity} × ${CurrencyHelper.format(item.unitPrice)}',
                                          style: tt.bodySmall,
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          CurrencyHelper.format(item.lineTotal),
                                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                const Divider(height: 24),

                                // Totals
                                _buildTotalRow(cs, tt, 'Subtotal', CurrencyHelper.format(widget.sale.subtotal)),
                                if (widget.sale.discountAmount > 0)
                                  _buildTotalRow(
                                    cs,
                                    tt,
                                    'Discounts',
                                    '-${CurrencyHelper.format(widget.sale.discountAmount)}',
                                    color: cs.primary,
                                  ),
                                const SizedBox(height: 8),
                                _buildTotalRow(
                                  cs,
                                  tt,
                                  'Grand Total',
                                  CurrencyHelper.format(widget.sale.total),
                                  isBold: true,
                                  fontSize: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky Action Bar
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('New Sale'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(ColorScheme cs, TextTheme tt, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
      ),
    );
  }

  Widget _buildTotalRow(
    ColorScheme cs,
    TextTheme tt,
    String label,
    String value, {
    bool isBold = false,
    double? fontSize,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color ?? cs.onSurface,
          ),
        ),
      ],
    );
  }
}

Future<Uint8List> generateReceiptPdf({
  required Sale sale,
  required List<SaleItem> items,
  String? branchName,
  String? cashierName,
  String? staffName,
  Invoice? invoice,
  Customer? customer,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.all(8),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'PAPs n POPs',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
            ),
            pw.Center(
              child: pw.Text(
                branchName ?? 'Liquor Till',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

            pw.Text('Date: ${sale.createdAt.toLocal().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 7)),
            pw.Text('Receipt #: ${sale.id.substring(0, 8).toUpperCase()}', style: const pw.TextStyle(fontSize: 7)),
            if (invoice != null)
              pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
            pw.Text('Cashier: ${cashierName ?? 'Staff'}', style: const pw.TextStyle(fontSize: 7)),
            if (staffName != null)
              pw.Text('Served By: $staffName', style: const pw.TextStyle(fontSize: 7)),
            if (customer != null) ...[
              pw.Text('Customer: ${customer.name}', style: const pw.TextStyle(fontSize: 7)),
              if (customer.companyName != null)
                pw.Text('Company: ${customer.companyName}', style: const pw.TextStyle(fontSize: 7)),
            ],
            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 4),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                pw.Container(width: 25, alignment: pw.Alignment.centerRight, child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                pw.Container(width: 35, alignment: pw.Alignment.centerRight, child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                pw.Container(width: 40, alignment: pw.Alignment.centerRight, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
              ],
            ),
            pw.Divider(thickness: 0.3),

            ...items.map((item) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.variantName ?? 'Product', style: const pw.TextStyle(fontSize: 7)),
                          if (item.discountAmount > 0)
                            pw.Text('  Discount: -KES ${(item.discountAmount / 100).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.Container(width: 25, alignment: pw.Alignment.centerRight, child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 7))),
                    pw.Container(width: 35, alignment: pw.Alignment.centerRight, child: pw.Text((item.unitPrice / 100).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 7))),
                    pw.Container(width: 40, alignment: pw.Alignment.centerRight, child: pw.Text((item.lineTotal / 100).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 7))),
                  ],
                ),
              );
            }),

            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
            pw.SizedBox(height: 3),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('KES ${(sale.subtotal / 100).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
            if (sale.discountAmount > 0) ...[
              pw.SizedBox(height: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Discounts:', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('-KES ${(sale.discountAmount / 100).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                pw.Text('KES ${(sale.total / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              ],
            ),

            pw.Divider(thickness: 0.3),
            pw.SizedBox(height: 1),
            pw.Text('Payment: ${sale.paymentMethod.toUpperCase()}', style: const pw.TextStyle(fontSize: 7)),
            if (sale.paymentReference != null)
              pw.Text('Ref: ${sale.paymentReference}', style: const pw.TextStyle(fontSize: 7)),

            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Thank you for shopping with us!',
                style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
