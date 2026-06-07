import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/product_variant.dart';
import '../../../data/repositories/product_repository.dart';
import '../stock_provider.dart';

class EditVariantSheet extends ConsumerStatefulWidget {
  final ProductVariant variant;

  const EditVariantSheet({super.key, required this.variant});

  static Future<void> show(BuildContext context, ProductVariant variant) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditVariantSheet(variant: variant),
      ),
    );
  }

  @override
  ConsumerState<EditVariantSheet> createState() => _EditVariantSheetState();
}

class _EditVariantSheetState extends ConsumerState<EditVariantSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _skuController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sellingPriceController = TextEditingController(
      text: (widget.variant.sellingPrice / 100).toStringAsFixed(2),
    );
    _costPriceController = TextEditingController(
      text: (widget.variant.costPrice / 100).toStringAsFixed(2),
    );
    _barcodeController = TextEditingController(
      text: widget.variant.barcode ?? '',
    );
    _skuController = TextEditingController(text: widget.variant.sku ?? '');
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final selling = (double.parse(_sellingPriceController.text) * 100)
          .round();
      final costStr = _costPriceController.text.trim();
      final cost = costStr.isNotEmpty
          ? (double.parse(costStr) * 100).round()
          : null;

      await ref
          .read(productControllerProvider)
          .updateVariant(
            variantId: widget.variant.id,
            sellingPrice: selling,
            costPrice: cost!,
            barcode: _barcodeController.text.trim(),
            sku: _skuController.text.trim(),
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Variant updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleToggleActive() async {
    final isActive = widget.variant.isActive;
    
    if (isActive) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate Variant'),
          content: Text('Are you sure you want to deactivate "${widget.variant.name}"?\n\nIt will be hidden from the POS but kept in reports.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(productRepositoryProvider).updateVariantActiveStatus(widget.variant.id, !isActive);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isActive ? 'Variant deactivated' : 'Variant reactivated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit ${widget.variant.name}',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _sellingPriceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price (KES)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costPriceController,
              decoration: const InputDecoration(
                labelText: 'Buying Price (KES)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode - Optional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'SKU - Optional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleToggleActive,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                        color: widget.variant.isActive ? cs.error : cs.primary,
                      ),
                      foregroundColor: widget.variant.isActive ? cs.error : cs.primary,
                    ),
                    child: Text(widget.variant.isActive ? 'Deactivate' : 'Reactivate'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
