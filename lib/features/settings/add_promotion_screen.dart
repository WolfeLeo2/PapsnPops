import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/promotion_repository.dart';
import '../auth/auth_provider.dart';

class AddPromotionScreen extends ConsumerStatefulWidget {
  const AddPromotionScreen({super.key});

  @override
  ConsumerState<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends ConsumerState<AddPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _type = 'percentage';
  int _value = 0;
  String _targetType = 'all';
  String? _targetValue;
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isHappyHour = false;
  TimeOfDay? _happyHourStart;
  TimeOfDay? _happyHourEnd;
  final List<String> _activeDays = [];
  bool _isLoading = false;

  final _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _validFrom : _validUntil,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _validFrom = picked;
          if (_validUntil.isBefore(_validFrom)) {
            _validUntil = _validFrom.add(const Duration(days: 1));
          }
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart 
          ? (_happyHourStart ?? const TimeOfDay(hour: 17, minute: 0)) 
          : (_happyHourEnd ?? const TimeOfDay(hour: 20, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _happyHourStart = picked;
        } else {
          _happyHourEnd = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final orgId = ref.read(authProvider)?.userMetadata?['organisation_id'];
    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine organisation ID')),
      );
      return;
    }

    if (_isHappyHour && (_happyHourStart == null || _happyHourEnd == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Happy hour requires start and end times')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final format = DateFormat('HH:mm:ss');
      final startStr = _happyHourStart != null 
          ? format.format(DateTime(2020, 1, 1, _happyHourStart!.hour, _happyHourStart!.minute)) 
          : null;
      final endStr = _happyHourEnd != null 
          ? format.format(DateTime(2020, 1, 1, _happyHourEnd!.hour, _happyHourEnd!.minute)) 
          : null;

      await ref.read(promotionRepositoryProvider).addPromotion(
            organisationId: orgId,
            name: _name,
            type: _type,
            value: _value,
            targetType: _targetType,
            targetValue: _targetType == 'all' ? null : _targetValue,
            validFrom: _validFrom,
            validUntil: _validUntil,
            isHappyHour: _isHappyHour,
            happyHourStart: startStr,
            happyHourEnd: endStr,
            activeDays: _activeDays.isEmpty ? null : _activeDays,
          );
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding promotion: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Promotion'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Name (e.g. 10% Off Everything)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Discount Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (KES)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _type = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Must be a number';
                      return null;
                    },
                    onSaved: (value) => _value = int.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _targetType,
                    decoration: const InputDecoration(
                      labelText: 'Target Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Products')),
                      DropdownMenuItem(value: 'category', child: Text('Specific Category')),
                      DropdownMenuItem(value: 'product', child: Text('Specific Product')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _targetType = val);
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _targetType != 'all'
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: _targetType == 'category' ? 'Category Name' : 'Product ID/Name',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              onSaved: (value) => _targetValue = value,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text('Valid From: ${DateFormat('MMM d, yyyy').format(_validFrom)}'),
                    onPressed: () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text('Valid Until: ${DateFormat('MMM d, yyyy').format(_validUntil)}'),
                    onPressed: () => _selectDate(context, false),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Is Happy Hour / Time-based?'),
                    subtitle: const Text('Enable to restrict promotion to specific times or days'),
                    value: _isHappyHour,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isHappyHour = val),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isHappyHour
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.access_time),
                                      label: Text(_happyHourStart != null ? 'Start: ${_happyHourStart!.format(context)}' : 'Select Start Time'),
                                      onPressed: () => _selectTime(context, true),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.access_time_filled),
                                      label: Text(_happyHourEnd != null ? 'End: ${_happyHourEnd!.format(context)}' : 'Select End Time'),
                                      onPressed: () => _selectTime(context, false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text('Active Days', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _daysOfWeek.map((day) {
                                  final isSelected = _activeDays.contains(day);
                                  return FilterChip(
                                    label: Text(day[0].toUpperCase() + day.substring(1)),
                                    selected: isSelected,
                                    showCheckmark: false,
                                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _activeDays.add(day);
                                        } else {
                                          _activeDays.remove(day);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Add Promotion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
