import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/core/utils/stock_display.dart';
import 'package:paps_n_pops/domain/models/product.dart';
import 'package:paps_n_pops/domain/models/product_variant.dart';

void main() {
  test('Test StockDisplay logic with Jameson Test', () {
    final product = Product(
      id: '1',
      name: 'Jameson Test',
      categoryId: '1',
      reorderLevel: 3,
      isActive: true,
      createdAt: DateTime.now(),
      baseUnit: 'ml',
      containerSize: 750,
      containerName: 'Bottle',
    );

    final variants = [
      ProductVariant(
        id: '1',
        productId: '1',
        name: 'Full Bottle',
        unitLabel: 'ml',
        conversionFactor: 750,
        sellingPrice: 4500,
        costPrice: 3000,
        isActive: true,
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      ProductVariant(
        id: '2',
        productId: '1',
        name: 'Double',
        unitLabel: 'ml',
        conversionFactor: 60,
        sellingPrice: 450,
        costPrice: 300,
        isActive: true,
        isDefault: false,
        createdAt: DateTime.now(),
      ),
      ProductVariant(
        id: '3',
        productId: '1',
        name: 'Shot',
        unitLabel: 'ml',
        conversionFactor: 30,
        sellingPrice: 250,
        costPrice: 150,
        isActive: true,
        isDefault: false,
        createdAt: DateTime.now(),
      ),
    ];

    print('Quantity 2010 -> ${StockDisplay.format(product, 2010, variants)}');
  });
}
