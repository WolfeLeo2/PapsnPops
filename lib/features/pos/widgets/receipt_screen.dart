import 'package:flutter/material.dart';
import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';

class ReceiptScreen extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> items;

  const ReceiptScreen({
    super.key,
    required this.sale,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Receipt for Sale ID: ${sale.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
