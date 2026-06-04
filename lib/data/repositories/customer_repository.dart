import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/customer.dart';
import '../powersync/powersync_client.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerRepository {
  Stream<List<Customer>> watchCustomers() {
    return db
        .watch('SELECT * FROM customers ORDER BY name ASC')
        .map((rows) => rows.map((row) => Customer.fromRow(row)).toList());
  }

  Future<void> createCustomer(Customer customer) async {
    final row = customer.toRow();
    final columns = row.keys.join(', ');
    final placeholders = List.filled(row.length, '?').join(', ');
    await db.execute(
      'INSERT INTO customers ($columns) VALUES ($placeholders)',
      row.values.toList(),
    );
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final wildcardQuery = '%$query%';
    final results = await db.getAll(
      '''
      SELECT * FROM customers 
      WHERE name LIKE ? 
         OR phone LIKE ? 
         OR company_name LIKE ? 
      ORDER BY name ASC
      ''',
      [wildcardQuery, wildcardQuery, wildcardQuery],
    );
    return results.map((row) => Customer.fromRow(row)).toList();
  }
}
