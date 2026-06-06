import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/currency.dart';
import '../../data/repositories/branch_provider.dart';
import 'reports_provider.dart';
import 'reports_screen.dart'; // for ReportTab enum

// ── PDF Export ────────────────────────────────────────────────────────────────

Future<void> exportReportAsPdf({
  required BuildContext context,
  required WidgetRef ref,
  required ReportTab tab,
}) async {
  final branchName = ref.read(currentBranchProvider)?.name ?? 'Branch';
  final dateRange = ref.read(activeDateRangeProvider);
  final fromStr = DateFormat('MMM d, yyyy').format(dateRange.from);
  final toStr = DateFormat('MMM d, yyyy').format(dateRange.to);
  final generatedAt = DateFormat('MMM d, yyyy HH:mm').format(DateTime.now());

  final pdf = pw.Document();

  // Build content based on tab
  final content = await _buildPdfContent(ref, tab);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                branchName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated: $generatedAt',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${tab.label} Report  •  $fromStr – $toStr',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 8),
        ],
      ),
      build: (_) => content,
    ),
  );

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: '${tab.label.replaceAll(' ', '_')}_$fromStr.pdf',
  );
}

Future<List<pw.Widget>> _buildPdfContent(WidgetRef ref, ReportTab tab) async {
  switch (tab) {
    case ReportTab.salesSummary:
      final summary = ref.read(salesSummaryProvider);
      return [
        _pdfKpiRow([
          ('Total Revenue', CurrencyHelper.format(summary.totalRevenue)),
          ('Sales Count', summary.totalSalesCount.toString()),
          ('Gross Profit', CurrencyHelper.format(summary.grossProfit)),
          ('Avg Sale', CurrencyHelper.format(summary.averageSaleValue)),
        ]),
        pw.SizedBox(height: 16),
        pw.Text(
          'Revenue by Payment Method',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        _pdfTable(
          headers: ['Method', 'Amount', 'Share %'],
          rows: summary.revenueByPaymentMethod.entries.map((e) {
            final pct = summary.totalRevenue == 0
                ? 0.0
                : (e.value / summary.totalRevenue) * 100;
            return [
              e.key.toUpperCase(),
              CurrencyHelper.format(e.value),
              '${pct.toStringAsFixed(1)}%',
            ];
          }).toList(),
        ),
      ];

    case ReportTab.byCashier:
      final rows = ref.read(cashierReportProvider).value ?? [];
      return [
        _pdfTable(
          headers: ['Cashier', 'Sales', 'Revenue', 'Avg Sale', '% of Total'],
          rows: rows
              .map(
                (r) => [
                  r.cashierName,
                  r.salesCount.toString(),
                  CurrencyHelper.format(r.revenue),
                  CurrencyHelper.format(r.averageSale),
                  '${r.percentageOfTotal.toStringAsFixed(1)}%',
                ],
              )
              .toList(),
        ),
      ];

    case ReportTab.bySalesperson:
      final rows = ref.read(salespersonReportProvider).value ?? [];
      return [
        _pdfTable(
          headers: [
            'Salesperson',
            'Sales',
            'Revenue',
            'Avg Sale',
            '% of Total',
          ],
          rows: rows
              .map(
                (r) => [
                  r.staffName,
                  r.salesCount.toString(),
                  CurrencyHelper.format(r.revenue),
                  CurrencyHelper.format(r.averageSale),
                  '${r.percentageOfTotal.toStringAsFixed(1)}%',
                ],
              )
              .toList(),
        ),
      ];

    case ReportTab.products:
      final rows = ref.read(productsReportProvider).value ?? [];
      return [
        _pdfTable(
          headers: [
            'Product',
            'Category',
            'Units',
            'Revenue',
            'Cost',
            'Profit',
            'Margin%',
          ],
          rows: rows
              .map(
                (r) => [
                  r.name,
                  r.category,
                  r.unitsSold.toString(),
                  CurrencyHelper.format(r.revenue),
                  CurrencyHelper.format(r.cost),
                  CurrencyHelper.format(r.profit),
                  '${r.marginPercent.toStringAsFixed(1)}%',
                ],
              )
              .toList(),
        ),
      ];

    case ReportTab.stockLevels:
      final rows = ref.read(stockLevelsReportProvider).value ?? [];
      return [
        _pdfTable(
          headers: ['Product', 'Category', 'Qty', 'Status'],
          rows: rows
              .map(
                (r) => [
                  r.name,
                  r.category,
                  r.quantity.toString(),
                  r.quantity <= 0
                      ? 'OUT'
                      : r.quantity <= r.reorderLevel
                      ? 'LOW'
                      : 'OK',
                ],
              )
              .toList(),
        ),
      ];

    case ReportTab.reconciliation:
      final rows = ref.read(reconciliationsReportProvider).value ?? [];
      return [
        _pdfTable(
          headers: ['Date', 'Logged By', 'Expected', 'Actual', 'Discrepancy'],
          rows: rows
              .map(
                (r) => [
                  DateFormat('MMM d, yyyy HH:mm').format(r.date),
                  r.userName,
                  CurrencyHelper.format(r.expectedCash),
                  CurrencyHelper.format(r.actualCash),
                  CurrencyHelper.format(r.discrepancy),
                ],
              )
              .toList(),
        ),
      ];

    case ReportTab.invoices:
      final rows = ref.read(invoicesReportProvider).value ?? [];
      return [
        _pdfTable(
          headers: ['Invoice #', 'Customer', 'Amount', 'Status', 'Due Date'],
          rows: rows
              .map(
                (r) => [
                  r.invoiceNumber,
                  r.customerName,
                  CurrencyHelper.format(r.totalAmount),
                  r.status.toUpperCase(),
                  r.dueDate != null
                      ? DateFormat('MMM d, yyyy').format(r.dueDate!)
                      : '–',
                ],
              )
              .toList(),
        ),
      ];
  }
}

pw.Widget _pdfKpiRow(List<(String, String)> items) {
  return pw.Row(
    children: items
        .map(
          (kv) => pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(right: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    kv.$1,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    kv.$2,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}

pw.Widget _pdfTable({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    cellStyle: const pw.TextStyle(fontSize: 9),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    cellHeight: 24,
    columnWidths: {
      for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
    },
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
  );
}

// ── CSV Export ────────────────────────────────────────────────────────────────

Future<void> exportReportAsCsv({
  required BuildContext context,
  required WidgetRef ref,
  required ReportTab tab,
}) async {
  final dateRange = ref.read(activeDateRangeProvider);
  final fromStr = DateFormat('yyyy-MM-dd').format(dateRange.from);

  final csv = _buildCsv(ref, tab);
  if (csv == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export.')));
    }
    return;
  }

  final dir = await getTemporaryDirectory();
  final fileName = '${tab.label.replaceAll(' ', '_')}_$fromStr.csv';
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csv);

  await Share.shareXFiles([
    XFile(file.path, mimeType: 'text/csv'),
  ], subject: '${tab.label} Report – $fromStr');
}

String? _buildCsv(WidgetRef ref, ReportTab tab) {
  final buf = StringBuffer();

  void row(List<String> cells) {
    buf.writeln(cells.map(_csvCell).join(','));
  }

  switch (tab) {
    case ReportTab.salesSummary:
      final s = ref.read(salesSummaryProvider);
      row(['Metric', 'Value']);
      row(['Total Revenue', CurrencyHelper.format(s.totalRevenue)]);
      row(['Sales Count', s.totalSalesCount.toString()]);
      row(['Gross Profit', CurrencyHelper.format(s.grossProfit)]);
      row(['Avg Sale', CurrencyHelper.format(s.averageSaleValue)]);
      row([]);
      row(['Payment Method', 'Amount']);
      for (final e in s.revenueByPaymentMethod.entries) {
        row([e.key, CurrencyHelper.format(e.value)]);
      }

    case ReportTab.byCashier:
      final rows = ref.read(cashierReportProvider).value ?? [];
      if (rows.isEmpty) return null;
      row(['Cashier', 'Sales Count', 'Revenue', 'Avg Sale', '% of Total']);
      for (final r in rows) {
        row([
          r.cashierName,
          r.salesCount.toString(),
          CurrencyHelper.format(r.revenue),
          CurrencyHelper.format(r.averageSale),
          '${r.percentageOfTotal.toStringAsFixed(1)}%',
        ]);
      }

    case ReportTab.bySalesperson:
      final rows = ref.read(salespersonReportProvider).value ?? [];
      if (rows.isEmpty) return null;
      row(['Salesperson', 'Sales Count', 'Revenue', 'Avg Sale', '% of Total']);
      for (final r in rows) {
        row([
          r.staffName,
          r.salesCount.toString(),
          CurrencyHelper.format(r.revenue),
          CurrencyHelper.format(r.averageSale),
          '${r.percentageOfTotal.toStringAsFixed(1)}%',
        ]);
      }

    case ReportTab.products:
      final rows = ref.read(productsReportProvider).value ?? [];
      if (rows.isEmpty) return null;
      row([
        'Product',
        'Category',
        'Units Sold',
        'Revenue',
        'Cost',
        'Profit',
        'Margin %',
      ]);
      for (final r in rows) {
        row([
          r.name,
          r.category,
          r.unitsSold.toString(),
          CurrencyHelper.format(r.revenue),
          CurrencyHelper.format(r.cost),
          CurrencyHelper.format(r.profit),
          '${r.marginPercent.toStringAsFixed(1)}%',
        ]);
      }

    case ReportTab.stockLevels:
      final rows = ref.read(stockLevelsReportProvider).value ?? [];
      if (rows.isEmpty) return null;
      row(['Product', 'Category', 'Quantity', 'Status']);
      for (final r in rows) {
        final status = r.quantity <= 0
            ? 'OUT'
            : r.quantity <= r.reorderLevel
            ? 'LOW'
            : 'OK';
        row([r.name, r.category, r.quantity.toString(), status]);
      }

    case ReportTab.reconciliation:
      final rows = ref.read(reconciliationsReportProvider).value ?? [];
      if (rows.isEmpty) return null;
      row(['Date', 'Logged By', 'Expected Cash', 'Actual Cash', 'Discrepancy']);
      for (final r in rows) {
        row([
          DateFormat('yyyy-MM-dd HH:mm').format(r.date),
          r.userName,
          CurrencyHelper.format(r.expectedCash),
          CurrencyHelper.format(r.actualCash),
          CurrencyHelper.format(r.discrepancy),
        ]);
      }

    case ReportTab.invoices:
      final rows = ref.read(invoicesReportProvider).value ?? [];
      if (rows.isEmpty) return null;
      row(['Invoice #', 'Customer', 'Amount', 'Status', 'Due Date']);
      for (final r in rows) {
        row([
          r.invoiceNumber,
          r.customerName,
          CurrencyHelper.format(r.totalAmount),
          r.status,
          r.dueDate != null ? DateFormat('yyyy-MM-dd').format(r.dueDate!) : '',
        ]);
      }
  }

  return buf.toString();
}

String _csvCell(String value) {
  // Escape commas and quotes per RFC 4180
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
