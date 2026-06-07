import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';
import 'package:paps_n_pops/data/powersync/powersync_client.dart' as ps_client;
import 'package:paps_n_pops/data/powersync/schema.dart';
import 'package:paps_n_pops/data/repositories/sale_repository.dart';
import 'package:paps_n_pops/data/repositories/tab_repository.dart';
import 'package:paps_n_pops/data/repositories/invoice_repository.dart';
import 'package:paps_n_pops/data/repositories/customer_repository.dart';
import 'package:paps_n_pops/domain/models/sale.dart';
import 'package:paps_n_pops/domain/models/sale_item.dart';
import 'package:paps_n_pops/domain/models/open_tab.dart';
import 'package:paps_n_pops/domain/models/tab_item.dart';
import 'package:paps_n_pops/domain/models/customer.dart';
import 'package:paps_n_pops/domain/models/invoice.dart';
import 'dart:io';

void main() {
  late Directory tempDir;
  late PowerSyncDatabase testDb;
  late SaleRepository saleRepo;
  late TabRepository tabRepo;
  late InvoiceRepository invoiceRepo;
  late CustomerRepository customerRepo;

  setUpAll(() async {
    tempDir = Directory('test_db_temp');
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync();
    
    testDb = PowerSyncDatabase(schema: schema, path: '${tempDir.path}/test.db');
    await testDb.initialize();
    
    ps_client.db = testDb;

    saleRepo = SaleRepository();
    tabRepo = TabRepository();
    invoiceRepo = InvoiceRepository();
    customerRepo = CustomerRepository();
  });

  tearDownAll(() async {
    await testDb.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await testDb.writeTransaction((tx) async {
      await tx.execute('DELETE FROM sales');
      await tx.execute('DELETE FROM sale_items');
      await tx.execute('DELETE FROM stock_movements');
      await tx.execute('DELETE FROM stock_levels');
      await tx.execute('DELETE FROM open_tabs');
      await tx.execute('DELETE FROM tab_items');
      await tx.execute('DELETE FROM invoices');
      await tx.execute('DELETE FROM customers');
      await tx.execute('DELETE FROM product_variants');
      await tx.execute('DELETE FROM products');
      await tx.execute('DELETE FROM branches');
    });
  });

  group('CustomerRepository Tests', () {
    test('Create and search customer', () async {
      final customer = Customer(
        id: 'cust-1',
        organisationId: 'org-1',
        name: 'John Doe',
        phone: '0712345678',
        companyName: 'ACME Corp',
        createdAt: DateTime.now(),
      );

      await customerRepo.createCustomer(customer);

      final searchResults1 = await customerRepo.searchCustomers('John');
      expect(searchResults1.length, equals(1));
      expect(searchResults1.first.name, equals('John Doe'));

      final searchResults2 = await customerRepo.searchCustomers('ACME');
      expect(searchResults2.length, equals(1));
      expect(searchResults2.first.companyName, equals('ACME Corp'));

      final searchResults3 = await customerRepo.searchCustomers('0712');
      expect(searchResults3.length, equals(1));
      expect(searchResults3.first.phone, equals('0712345678'));
    });
  });

  group('SaleRepository Tests', () {
    setUp(() async {
      await testDb.writeTransaction((tx) async {
        // Insert a test branch
        await tx.execute(
          'INSERT INTO branches (id, name, location, phone, created_at) VALUES (?, ?, ?, ?, ?)',
          ['branch-1', 'Nairobi Till', 'Nairobi', '0712345678', DateTime.now().toIso8601String()],
        );
        // Insert a test product
        await tx.execute(
          'INSERT INTO products (id, name, category_id, reorder_level, is_active, base_unit, container_size, container_name, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          ['product-1', 'Jameson', 'cat-1', 5, 1, 'ml', 750, 'Bottle', DateTime.now().toIso8601String()],
        );
        // Insert variant with conversion factor = 25 (e.g. shot)
        await tx.execute(
          'INSERT INTO product_variants (id, product_id, name, unit_label, conversion_factor, selling_price, cost_price, is_active, is_default, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          ['variant-1', 'product-1', 'Jameson Shot', 'ml', 25, 250, 150, 1, 0, DateTime.now().toIso8601String()],
        );
        // Set initial stock level
        await tx.execute(
          'INSERT INTO stock_levels (id, branch_id, product_id, quantity, updated_at) VALUES (?, ?, ?, ?, ?)',
          ['stock-1', 'branch-1', 'product-1', 1000, DateTime.now().toIso8601String()],
        );
      });
    });

    test('Create Sale updates stock levels and inserts movements', () async {
      final sale = Sale(
        id: 'sale-1',
        branchId: 'branch-1',
        cashierId: 'cashier-1',
        paymentMethod: 'cash',
        subtotal: 500,
        discountAmount: 0,
        total: 500,
        isVoided: false,
        source: 'pos',
        createdAt: DateTime.now(),
      );

      final saleItem = SaleItem(
        id: 'item-1',
        saleId: 'sale-1',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 2,
        unitPrice: 250,
        costPrice: 150,
        discountAmount: 0,
        lineTotal: 500,
      );

      await saleRepo.createSale(sale, [saleItem]);

      // Check sales inserted
      final sales = await testDb.getAll('SELECT * FROM sales');
      expect(sales.length, equals(1));
      
      final saleItems = await testDb.getAll('SELECT * FROM sale_items');
      expect(saleItems.length, equals(1));

      // Check stock level decremented by quantity * conversion_factor: 2 * 25 = 50. New stock should be 1000 - 50 = 950.
      final stockLevels = await testDb.getAll('SELECT * FROM stock_levels WHERE product_id = ?', ['product-1']);
      expect(stockLevels.first['quantity'], equals(950));

      // Check stock movement inserted with correct quantity: -50
      final movements = await testDb.getAll('SELECT * FROM stock_movements WHERE product_id = ?', ['product-1']);
      expect(movements.length, equals(1));
      expect(movements.first['quantity'], equals(-50));
      expect(movements.first['type'], equals('sale'));
    });

    test('Void Sale restores stock levels and inserts void movement', () async {
      final sale = Sale(
        id: 'sale-2',
        branchId: 'branch-1',
        cashierId: 'cashier-1',
        paymentMethod: 'cash',
        subtotal: 250,
        discountAmount: 0,
        total: 250,
        isVoided: false,
        source: 'pos',
        createdAt: DateTime.now(),
      );

      final saleItem = SaleItem(
        id: 'item-2',
        saleId: 'sale-2',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 1,
        unitPrice: 250,
        costPrice: 150,
        discountAmount: 0,
        lineTotal: 250,
      );

      await saleRepo.createSale(sale, [saleItem]);

      // Check stock level updated: 1000 - 25 = 975
      var stockLevels = await testDb.getAll('SELECT * FROM stock_levels WHERE product_id = ?', ['product-1']);
      expect(stockLevels.first['quantity'], equals(975));

      // Now void the sale
      await saleRepo.voidSale('sale-2', 'cashier-1');

      // Check sale is_voided is 1 (true)
      final saleRows = await testDb.getAll('SELECT is_voided FROM sales WHERE id = ?', ['sale-2']);
      expect(saleRows.first['is_voided'], equals(1));

      // Check stock level restored to 1000
      stockLevels = await testDb.getAll('SELECT * FROM stock_levels WHERE product_id = ?', ['product-1']);
      expect(stockLevels.first['quantity'], equals(1000));

      // Check stock movements has 2 movements: 'sale' (-25) and 'void' (+25)
      final movements = await testDb.getAll(
        'SELECT * FROM stock_movements WHERE product_id = ? ORDER BY created_at ASC',
        ['product-1'],
      );
      expect(movements.length, equals(2));
      expect(movements[0]['quantity'], equals(-25));
      expect(movements[0]['type'], equals('sale'));
      expect(movements[1]['quantity'], equals(25));
      expect(movements[1]['type'], equals('void'));
    });
  });

  group('TabRepository Tests', () {
    setUp(() async {
      await testDb.writeTransaction((tx) async {
        await tx.execute(
          'INSERT INTO branches (id, name, location, phone, created_at) VALUES (?, ?, ?, ?, ?)',
          ['branch-1', 'Nairobi Till', 'Nairobi', '0712345678', DateTime.now().toIso8601String()],
        );
        await tx.execute(
          'INSERT INTO products (id, name, category_id, reorder_level, is_active, base_unit, container_size, container_name, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          ['product-1', 'Jameson', 'cat-1', 5, 1, 'ml', 750, 'Bottle', DateTime.now().toIso8601String()],
        );
        await tx.execute(
          'INSERT INTO product_variants (id, product_id, name, unit_label, conversion_factor, selling_price, cost_price, is_active, is_default, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          ['variant-1', 'product-1', 'Jameson Shot', 'ml', 25, 250, 150, 1, 0, DateTime.now().toIso8601String()],
        );
        await tx.execute(
          'INSERT INTO stock_levels (id, branch_id, product_id, quantity, updated_at) VALUES (?, ?, ?, ?, ?)',
          ['stock-1', 'branch-1', 'product-1', 1000, DateTime.now().toIso8601String()],
        );
      });
    });

    test('Add item to tab merges existing variant quantity', () async {
      final tab = OpenTab(
        id: 'tab-1',
        branchId: 'branch-1',
        name: 'Table 5',
        isOpen: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tabRepo.createTab(tab);

      final item1 = TabItem(
        id: 'ti-1',
        tabId: 'tab-1',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 2,
        unitPrice: 250,
        createdAt: DateTime.now(),
      );

      await tabRepo.addTabItem(item1);

      // Verify added
      var tabItems = await testDb.getAll('SELECT * FROM tab_items WHERE tab_id = ?', ['tab-1']);
      expect(tabItems.length, equals(1));
      expect(tabItems.first['quantity'], equals(2));

      // Add another of the same variant to check merge
      final item2 = TabItem(
        id: 'ti-2',
        tabId: 'tab-1',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 3,
        unitPrice: 250,
        createdAt: DateTime.now(),
      );

      await tabRepo.addTabItem(item2);

      // Verify merged to 5
      tabItems = await testDb.getAll('SELECT * FROM tab_items WHERE tab_id = ?', ['tab-1']);
      expect(tabItems.length, equals(1));
      expect(tabItems.first['quantity'], equals(5));
    });

    test('Close tab creates sale, closes tab and deletes tab items', () async {
      final tab = OpenTab(
        id: 'tab-2',
        branchId: 'branch-1',
        name: 'Table 6',
        isOpen: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tabRepo.createTab(tab);

      final tabItem = TabItem(
        id: 'ti-3',
        tabId: 'tab-2',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 3,
        unitPrice: 250,
        createdAt: DateTime.now(),
      );

      await tabRepo.addTabItem(tabItem);

      // Verify open
      final openTabsBefore = await testDb.getAll('SELECT * FROM open_tabs WHERE is_open = 1');
      expect(openTabsBefore.length, equals(1));

      // Prepare sale models
      final sale = Sale(
        id: 'sale-tab-1',
        branchId: 'branch-1',
        cashierId: 'cashier-1',
        paymentMethod: 'm-pesa',
        subtotal: 750,
        discountAmount: 0,
        total: 750,
        isVoided: false,
        source: 'tab',
        tabId: 'tab-2',
        createdAt: DateTime.now(),
      );

      final saleItem = SaleItem(
        id: 'si-tab-1',
        saleId: 'sale-tab-1',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 3,
        unitPrice: 250,
        costPrice: 150,
        discountAmount: 0,
        lineTotal: 750,
      );

      await tabRepo.closeTab('tab-2', sale, [saleItem]);

      // Verify tab is closed (is_open = 0)
      final openTabsAfter = await testDb.getAll('SELECT * FROM open_tabs WHERE is_open = 1');
      expect(openTabsAfter.length, equals(0));

      final tabRow = await testDb.getOptional('SELECT * FROM open_tabs WHERE id = ?', ['tab-2']);
      expect(tabRow?['is_open'], equals(0));
      expect(tabRow?['sale_id'], equals('sale-tab-1'));

      // Verify tab items deleted
      final remainingTabItems = await testDb.getAll('SELECT * FROM tab_items WHERE tab_id = ?', ['tab-2']);
      expect(remainingTabItems.length, equals(0));

      // Verify sale created
      final sales = await testDb.getAll('SELECT * FROM sales WHERE id = ?', ['sale-tab-1']);
      expect(sales.length, equals(1));

      // Verify stock level decremented: 1000 - 3 * 25 = 925
      final stockLevels = await testDb.getAll('SELECT * FROM stock_levels WHERE product_id = ?', ['product-1']);
      expect(stockLevels.first['quantity'], equals(925));
    });
  });

  group('InvoiceRepository Tests', () {
    setUp(() async {
      await testDb.writeTransaction((tx) async {
        await tx.execute(
          'INSERT INTO branches (id, name, location, phone, created_at) VALUES (?, ?, ?, ?, ?)',
          ['branch-1-nairobi', 'Nairobi Till', 'Nairobi', '0712345678', DateTime.now().toIso8601String()],
        );
        await tx.execute(
          'INSERT INTO products (id, name, category_id, reorder_level, is_active, base_unit, container_size, container_name, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          ['product-1', 'Jameson', 'cat-1', 5, 1, 'ml', 750, 'Bottle', DateTime.now().toIso8601String()],
        );
        await tx.execute(
          'INSERT INTO product_variants (id, product_id, name, unit_label, conversion_factor, selling_price, cost_price, is_active, is_default, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          ['variant-1', 'product-1', 'Jameson Shot', 'ml', 25, 250, 150, 1, 0, DateTime.now().toIso8601String()],
        );
        await tx.execute(
          'INSERT INTO stock_levels (id, branch_id, product_id, quantity, updated_at) VALUES (?, ?, ?, ?, ?)',
          ['stock-1', 'branch-1-nairobi', 'product-1', 1000, DateTime.now().toIso8601String()],
        );
      });
    });

    test('Invoice sequential numbering and creation', () async {
      // 1. Get next number when none exist (prefix = first 4 chars of branch-1-nairobi -> bran)
      final num1 = await invoiceRepo.getNextInvoiceNumber('branch-1-nairobi');
      expect(num1, equals('INV-BRAN-0001'));

      // 2. Create invoice
      final sale = Sale(
        id: 'sale-inv-1',
        branchId: 'branch-1-nairobi',
        cashierId: 'cashier-1',
        paymentMethod: 'invoice',
        subtotal: 500,
        discountAmount: 0,
        total: 500,
        isVoided: false,
        source: 'pos',
        createdAt: DateTime.now(),
      );

      final saleItem = SaleItem(
        id: 'si-inv-1',
        saleId: 'sale-inv-1',
        productId: 'product-1',
        variantId: 'variant-1',
        variantName: 'Jameson Shot',
        quantity: 2,
        unitPrice: 250,
        costPrice: 150,
        discountAmount: 0,
        lineTotal: 500,
      );

      final invoice = Invoice(
        id: 'inv-1',
        saleId: 'sale-inv-1',
        branchId: 'branch-1-nairobi',
        customerId: 'cust-1',
        invoiceNumber: num1,
        status: 'unpaid',
        createdAt: DateTime.now(),
      );

      await invoiceRepo.createInvoice(invoice, sale, [saleItem]);

      // Check invoice is created
      final invoices = await testDb.getAll('SELECT * FROM invoices WHERE id = ?', ['inv-1']);
      expect(invoices.length, equals(1));
      expect(invoices.first['status'], equals('unpaid'));

      // Check stock decremented
      final stockLevels = await testDb.getAll('SELECT * FROM stock_levels WHERE product_id = ?', ['product-1']);
      expect(stockLevels.first['quantity'], equals(950));

      // Check sequential invoice number increments
      final num2 = await invoiceRepo.getNextInvoiceNumber('branch-1-nairobi');
      expect(num2, equals('INV-BRAN-0002'));

      // Mark paid by logging full payment
      await invoiceRepo.logPayment(
        invoiceId: 'inv-1',
        branchId: 'branch-1-nairobi',
        amount: 500,
        paymentMethod: 'cash',
        cashierId: 'cashier-1',
      );

      final updatedInvoices = await testDb.getAll('SELECT * FROM invoices WHERE id = ?', ['inv-1']);
      expect(updatedInvoices.first['status'], equals('paid'));
      expect(updatedInvoices.first['paid_at'], isNotNull);
    });
  });
}
