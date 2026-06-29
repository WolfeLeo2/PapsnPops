import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/domain/models/sale.dart';
import 'package:paps_n_pops/domain/models/sale_item.dart';
import 'package:paps_n_pops/domain/sale_validation.dart';

Sale _sale({
  String paymentMethod = 'cash',
  String source = 'pos',
  String branchId = 'branch-1',
  String cashierId = 'cashier-1',
  int subtotal = 200,
  int discountAmount = 0,
  int total = 200,
}) => Sale(
  id: 'sale-1',
  branchId: branchId,
  cashierId: cashierId,
  paymentMethod: paymentMethod,
  subtotal: subtotal,
  discountAmount: discountAmount,
  total: total,
  isVoided: false,
  source: source,
  createdAt: DateTime(2026, 1, 1),
);

SaleItem _item({
  String variantId = 'variant-1',
  String productId = 'product-1',
  int quantity = 2,
  int lineTotal = 200,
}) => SaleItem(
  id: 'item-1',
  saleId: 'sale-1',
  productId: productId,
  variantId: variantId,
  variantName: 'Club Soda 1L',
  quantity: quantity,
  unitPrice: 100,
  costPrice: 80,
  discountAmount: 0,
  lineTotal: lineTotal,
);

void main() {
  group('success', () {
    test('valid POS sale passes', () {
      expect(validateSaleForUpload(_sale(), [_item()]), isEmpty);
    });

    test('valid tab sale passes', () {
      expect(
        validateSaleForUpload(_sale(source: 'tab'), [_item()]),
        isEmpty,
      );
    });

    test('valid invoice sale passes', () {
      expect(
        validateSaleForUpload(_sale(source: 'invoice'), [_item()]),
        isEmpty,
      );
    });
  });

  group('failure', () {
    test('rejects invalid payment method', () {
      final errors = validateSaleForUpload(
        _sale(paymentMethod: 'credit'),
        [_item()],
      );
      expect(errors, contains(contains('payment method')));
    });

    test('rejects invalid source', () {
      final errors = validateSaleForUpload(
        _sale(source: 'wholesale'),
        [_item()],
      );
      expect(errors, contains(contains('source')));
    });

    test('rejects empty cart', () {
      expect(validateSaleForUpload(_sale(), []), contains('no items'));
    });

    test('rejects item with missing variant (the FK that caused lost sales)', () {
      final errors = validateSaleForUpload(_sale(), [_item(variantId: '')]);
      expect(errors, contains(contains('missing variant')));
    });

    test('rejects missing branch / cashier', () {
      final errors = validateSaleForUpload(
        _sale(branchId: '', cashierId: ''),
        [_item()],
      );
      expect(errors, containsAll(['missing branch', 'missing cashier']));
    });

    test('rejects negative total and non-positive quantity', () {
      final errors = validateSaleForUpload(
        _sale(total: -1),
        [_item(quantity: 0)],
      );
      expect(errors, contains('negative total'));
      expect(errors, contains(contains('non-positive quantity')));
    });

    test('assertSaleValid throws on a bad sale', () {
      expect(
        () => assertSaleValid(_sale(paymentMethod: 'credit'), [_item()]),
        throwsException,
      );
    });
  });
}
