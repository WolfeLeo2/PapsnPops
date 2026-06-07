import 'package:flutter/material.dart';
import '../../../data/powersync/powersync_client.dart';
import '../../stock/stock_provider.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final id = generateV4Uuid();
      await db.execute('''
        INSERT INTO categories (id, name, created_at)
        VALUES (?, ?, ?)
      ''', [id, name, DateTime.now().toUtc().toIso8601String()]);
      
      if (mounted) {
        Navigator.of(context).pop(id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding category: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Category'),
      content: TextField(
        controller: _nameCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Category Name',
          hintText: 'e.g. Beers',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Add'),
        ),
      ],
    );
  }
}
