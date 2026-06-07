import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../features/auth/auth_provider.dart';

class LogPaymentDialog extends ConsumerStatefulWidget {
  final String invoiceId;
  final String branchId;
  final int balanceDue;

  const LogPaymentDialog({
    super.key,
    required this.invoiceId,
    required this.branchId,
    required this.balanceDue,
  });

  @override
  ConsumerState<LogPaymentDialog> createState() => _LogPaymentDialogState();
}

class _LogPaymentDialogState extends ConsumerState<LogPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _paymentMethod = 'mpesa';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = (widget.balanceDue / 100).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authUser = ref.read(authProvider);
    if (authUser == null) return;

    final amountDouble = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final amountInt = (amountDouble * 100).round();

    if (amountInt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(invoiceRepositoryProvider);
      await repo.logPayment(
        invoiceId: widget.invoiceId,
        branchId: widget.branchId,
        amount: amountInt,
        paymentMethod: _paymentMethod,
        paymentReference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        cashierId: authUser.id,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log payment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Payment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Balance Due: ${CurrencyHelper.format(widget.balanceDue)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (KES)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Required';
                final d = double.tryParse(val.trim());
                if (d == null || d <= 0) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _paymentMethod = val);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _refCtrl,
              decoration: InputDecoration(
                labelText: (_paymentMethod == 'mpesa' || _paymentMethod == 'card') 
                    ? '${_paymentMethod == 'mpesa' ? 'M-Pesa' : 'Card'} Reference (Required)' 
                    : 'Reference Number (Optional)',
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if ((_paymentMethod == 'mpesa' || _paymentMethod == 'card') && (val == null || val.trim().isEmpty)) {
                  return 'Reference is required for ${_paymentMethod == 'mpesa' ? 'M-Pesa' : 'Card'}';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
