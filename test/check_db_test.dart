import 'package:flutter_test/flutter_test.dart';
import 'package:paps_n_pops/domain/models/product.dart';
import 'package:paps_n_pops/data/powersync/schema.dart';
import 'package:powersync/powersync.dart';
import 'dart:io';

void main() {
  test('Check SQLite values directly', () async {
    print('Reading schema for products table:');
    final productsTable = schema.tables.firstWhere((t) => t.name == 'products');
    for (var col in productsTable.columns) {
      print('Col: ${col.name} - ${col.type}');
    }
  });
}
