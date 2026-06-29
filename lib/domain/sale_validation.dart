import 'models/sale.dart';
import 'models/sale_item.dart';

/// Validates a sale against the server's constraints BEFORE it's written, so a
/// bad sale fails loudly at checkout instead of being silently dropped when the
/// upload is rejected (RLS/CHECK/FK) and dead-lettered. Returns a list of
/// human-readable problems; empty list = OK to save.
///
/// This mirrors the Postgres CHECK/NOT-NULL constraints on `sales`/`sale_items`.
/// It does NOT check foreign-key existence (variant/customer/staff) — those rows
/// live in the synced DB and FK failures are handled by the upload dead-letter +
/// Sentry path, not here.
const _paymentMethods = {'cash', 'mpesa', 'card'};
const _sources = {'pos', 'tab', 'invoice'};

List<String> validateSaleForUpload(Sale sale, List<SaleItem> items) {
  final errors = <String>[];

  if (sale.branchId.trim().isEmpty) errors.add('missing branch');
  if (sale.cashierId.trim().isEmpty) errors.add('missing cashier');
  if (!_paymentMethods.contains(sale.paymentMethod)) {
    errors.add('invalid payment method "${sale.paymentMethod}"');
  }
  if (!_sources.contains(sale.source)) {
    errors.add('invalid source "${sale.source}"');
  }
  if (sale.subtotal < 0) errors.add('negative subtotal');
  if (sale.discountAmount < 0) errors.add('negative discount');
  if (sale.total < 0) errors.add('negative total');

  if (items.isEmpty) errors.add('no items');
  for (final item in items) {
    if (item.variantId.trim().isEmpty) {
      errors.add('item "${item.variantName}" missing variant');
    }
    if (item.productId.trim().isEmpty) {
      errors.add('item "${item.variantName}" missing product');
    }
    if (item.quantity <= 0) {
      errors.add('item "${item.variantName}" has non-positive quantity');
    }
    if (item.unitPrice < 0 || item.costPrice < 0 || item.lineTotal < 0) {
      errors.add('item "${item.variantName}" has negative amount');
    }
  }

  return errors;
}

/// Throws with a clear message if the sale would be rejected by the server.
void assertSaleValid(Sale sale, List<SaleItem> items) {
  final errors = validateSaleForUpload(sale, items);
  if (errors.isNotEmpty) {
    throw Exception('Cannot save sale: ${errors.join('; ')}');
  }
}
