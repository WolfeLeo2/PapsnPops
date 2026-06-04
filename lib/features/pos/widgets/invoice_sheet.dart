import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/models/customer.dart';
import '../../../domain/models/sale.dart';
import '../../../domain/models/sale_item.dart';
import '../../../domain/models/invoice.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/branch_provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/stock/stock_provider.dart' show generateV4Uuid;
import '../pos_provider.dart';
import 'receipt_screen.dart';

class InvoiceSheet extends ConsumerStatefulWidget {
  const InvoiceSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const SafeArea(
          child: InvoiceSheet(),
        ),
      ),
    );
  }

  @override
  ConsumerState<InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends ConsumerState<InvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedCustomerId;
  List<Customer> _suggestions = [];
  bool _showSuggestions = false;

  int _dueDays = 7;
  DateTime? _customDueDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedCustomerId = null;
      });
      return;
    }

    final repo = ref.read(customerRepositoryProvider);
    final results = await repo.searchCustomers(query);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomerId = customer.id;
      _nameCtrl.text = customer.name;
      _phoneCtrl.text = customer.phone;
      _companyCtrl.text = customer.companyName ?? '';
      _addressCtrl.text = customer.address ?? '';
      _emailCtrl.text = customer.email ?? '';
      _showSuggestions = false;
    });
  }

  DateTime get _calculatedDueDate {
    if (_dueDays == 0 && _customDueDate != null) {
      return _customDueDate!;
    }
    return DateTime.now().add(Duration(days: _dueDays));
  }

  void _selectCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDays = 0;
        _customDueDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final branchId = ref.read(currentBranchIdProvider);
    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No branch selected')),
      );
      return;
    }

    final authUser = ref.read(authProvider);
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Cashier not logged in')),
      );
      return;
    }

    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final invoiceRepo = ref.read(invoiceRepositoryProvider);

      String customerId = _selectedCustomerId ?? generateV4Uuid();

      if (_selectedCustomerId == null) {
        // Create new customer
        final customer = Customer(
          id: customerId,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          companyName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          createdAt: DateTime.now(),
        );
        await customerRepo.createCustomer(customer);
      }

      final saleId = generateV4Uuid();
      final subtotal = ref.read(cartProvider.notifier).subtotal;
      final discount = ref.read(cartProvider.notifier).discountAmount;
      final total = ref.read(cartProvider.notifier).total;
      final appliedPromos = ref.read(appliedPromotionsProvider);
      final selectedStaffId = ref.read(selectedStaffProvider);

      final sale = Sale(
        id: saleId,
        branchId: branchId,
        cashierId: authUser.id,
        staffId: selectedStaffId,
        customerId: customerId,
        paymentMethod: 'card', // Standard fallback since it's an invoice
        paymentReference: null,
        subtotal: subtotal,
        discountAmount: discount,
        total: total,
        promotionIds: appliedPromos.map((p) => p.promotion.id).toSet().toList(),
        isVoided: false,
        source: 'invoice',
        createdAt: DateTime.now(),
      );

      final saleItems = cartItems.map((item) {
        return SaleItem(
          id: generateV4Uuid(),
          saleId: saleId,
          productId: item.product.id,
          variantId: item.variant.id,
          variantName: item.variant.name,
          quantity: item.quantity,
          unitPrice: item.variant.sellingPrice,
          costPrice: item.variant.costPrice,
          discountAmount: item.discountAmount,
          lineTotal: item.lineTotal,
        );
      }).toList();

      final invoiceNumber = await invoiceRepo.getNextInvoiceNumber(branchId);
      final invoice = Invoice(
        id: generateV4Uuid(),
        saleId: saleId,
        branchId: branchId,
        customerId: customerId,
        invoiceNumber: invoiceNumber,
        status: 'unpaid',
        dueDate: _calculatedDueDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await invoiceRepo.createInvoice(invoice, sale, saleItems);

      // Clear state
      ref.read(cartProvider.notifier).clear();
      ref.read(selectedStaffProvider.notifier).set(null);
      ref.read(paymentReferenceProvider.notifier).set('');
      ref.read(selectedPaymentMethodProvider.notifier).set('cash');

      if (!mounted) return;
      
      // Close invoice sheet
      Navigator.of(context).pop();
      
      // Close mobile cart panel if open
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }

      // Navigate to receipt
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(sale: sale, items: saleItems, invoice: invoice),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating invoice: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Save as Invoice',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const PhosphorIcon(PhosphorIconsRegular.x, size: 24),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Customer Name field with suggestions
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: _onNameChanged,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Customer name is required';
                  }
                  return null;
                },
              ),
              if (_showSuggestions) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final c = _suggestions[index];
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text('${c.phone}${c.companyName != null ? ' • ${c.companyName}' : ''}'),
                        onTap: () => _selectCustomer(c),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Customer Phone
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Company Name (Optional)
              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name (Optional)',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Customer Address
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Billing Address (Optional)',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Customer Email
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email Address (Optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Due Date Selector
              Text('Due Date', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('7 Days'),
                    selected: _dueDays == 7,
                    onSelected: (val) => setState(() => _dueDays = 7),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('14 Days'),
                    selected: _dueDays == 14,
                    onSelected: (val) => setState(() => _dueDays = 14),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('30 Days'),
                    selected: _dueDays == 30,
                    onSelected: (val) => setState(() => _dueDays = 30),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      _dueDays == 0 && _customDueDate != null
                          ? '${_customDueDate!.day}/${_customDueDate!.month}/${_customDueDate!.year}'
                          : 'Custom',
                    ),
                    selected: _dueDays == 0,
                    onSelected: (val) {
                      if (val) _selectCustomDate();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Invoice Notes / Terms (Optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Submit Button
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Create Invoice',
                  style: tt.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
