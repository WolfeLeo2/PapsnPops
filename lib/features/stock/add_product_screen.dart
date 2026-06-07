import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'stock_provider.dart';
import 'widgets/variant_form_card.dart';
import 'widgets/add_category_dialog.dart';
import '../../features/auth/auth_provider.dart';

enum MeasurementType { piece, volume }

abstract class VariantFormState {
  TextEditingController get nameCtrl;
  TextEditingController get sellingPriceCtrl;
  TextEditingController get barcodeCtrl;
  TextEditingController get skuCtrl;
  bool showAdvanced = false;

  void dispose();
}

class PieceVariantState implements VariantFormState {
  @override
  final nameCtrl = TextEditingController();
  @override
  final sellingPriceCtrl = TextEditingController();
  final costPriceCtrl = TextEditingController();
  final wholesalePriceCtrl = TextEditingController();
  @override
  final barcodeCtrl = TextEditingController();
  @override
  final skuCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();

  bool isBase;
  @override
  bool showAdvanced = false;

  PieceVariantState({this.isBase = false}) {
    if (isBase) quantityCtrl.text = '1';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    sellingPriceCtrl.dispose();
    costPriceCtrl.dispose();
    wholesalePriceCtrl.dispose();
    barcodeCtrl.dispose();
    skuCtrl.dispose();
    quantityCtrl.dispose();
  }
}

class VolumeServingState implements VariantFormState {
  @override
  final nameCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();
  @override
  final sellingPriceCtrl = TextEditingController();
  @override
  final barcodeCtrl = TextEditingController();
  @override
  final skuCtrl = TextEditingController();

  @override
  bool showAdvanced = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    sizeCtrl.dispose();
    sellingPriceCtrl.dispose();
    barcodeCtrl.dispose();
    skuCtrl.dispose();
  }
}

class VolumeContainerState {
  final costPriceCtrl = TextEditingController();
  final wholesalePriceCtrl = TextEditingController();
  final sellingPriceCtrl = TextEditingController();
  final barcodeCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  bool showAdvanced = false;

  void dispose() {
    costPriceCtrl.dispose();
    wholesalePriceCtrl.dispose();
    sellingPriceCtrl.dispose();
    barcodeCtrl.dispose();
    skuCtrl.dispose();
  }
}

class AddProductScreen extends ConsumerStatefulWidget {
  final bool isSideSheet;
  const AddProductScreen({super.key, this.isSideSheet = false});

  static Future<void> show(BuildContext context) async {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    if (isDesktop) {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close Add Product',
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 500,
              child: AddProductScreen(isSideSheet: true),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          return SlideTransition(position: slideAnimation, child: child);
        },
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddProductScreen(isSideSheet: false),
        ),
      );
    }
  }

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Info
  final _nameCtrl = TextEditingController();
  String? _selectedCategoryId;

  // Step 2: Measurement Type
  MeasurementType _measurementType = MeasurementType.piece;

  // Step 3: Variants
  // Path A (Piece)
  final List<PieceVariantState> _pieceVariants = [];
  // Path B (Volume)
  final _containerNameCtrl = TextEditingController();
  final _containerSizeCtrl = TextEditingController();
  final _volumeContainerState = VolumeContainerState();
  final List<VolumeServingState> _volumeServings = [];

  // Step 4: Alerts
  final _reorderCtrl = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _pieceVariants.add(PieceVariantState(isBase: true));

    // Add default serving for Volume path
    _volumeServings.add(VolumeServingState());

    // Rebuild when container name/size change for preview
    _containerNameCtrl.addListener(() => setState(() {}));
    _containerSizeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var v in _pieceVariants) {
      v.dispose();
    }
    _containerNameCtrl.dispose();
    _containerSizeCtrl.dispose();
    _volumeContainerState.dispose();
    for (var v in _volumeServings) {
      v.dispose();
    }
    _reorderCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      // Validate current step
      if (_currentStep == 0 && _nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product name is required')),
        );
        return;
      }
      if (_currentStep == 2) {
        if (_measurementType == MeasurementType.piece) {
          for (var v in _pieceVariants) {
            if (v.nameCtrl.text.trim().isEmpty ||
                v.sellingPriceCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill all required variant fields'),
                ),
              );
              return;
            }
          }
        } else {
          if (_containerNameCtrl.text.trim().isEmpty ||
              _containerSizeCtrl.text.trim().isEmpty ||
              _volumeContainerState.sellingPriceCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fill container details and prices'),
              ),
            );
            return;
          }
          for (var v in _volumeServings) {
            if (v.nameCtrl.text.trim().isEmpty ||
                v.sizeCtrl.text.trim().isEmpty ||
                v.sellingPriceCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all serving fields')),
              );
              return;
            }
          }
        }
      }
      setState(() => _currentStep += 1);
    } else {
      _handleSave();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final controller = ref.read(productControllerProvider);
      final authState = ref.read(authProvider);
      final orgId = authState?.userMetadata?['organisation_id'] as String?;
      if (orgId == null) throw Exception('No organisation ID found');

      final List<VariantInput> variantInputs = [];

      if (_measurementType == MeasurementType.piece) {
        for (int i = 0; i < _pieceVariants.length; i++) {
          final v = _pieceVariants[i];
          variantInputs.add(
            VariantInput(
              name: v.nameCtrl.text.trim(),
              unitLabel: 'piece',
              conversionFactor: int.tryParse(v.quantityCtrl.text.trim()) ?? 1,
              sellingPrice:
                  (int.tryParse(v.sellingPriceCtrl.text.replaceAll(',', '')) ??
                      0) *
                  100,
              costPrice:
                  (int.tryParse(v.costPriceCtrl.text.replaceAll(',', '')) ??
                      0) *
                  100,
              wholesalePrice: v.wholesalePriceCtrl.text.isEmpty
                  ? null
                  : (int.tryParse(
                              v.wholesalePriceCtrl.text.replaceAll(',', ''),
                            ) ??
                            0) *
                        100,
              barcode: v.barcodeCtrl.text.trim(),
              sku: v.skuCtrl.text.trim(),
              isDefault: i == 0,
            ),
          );
        }
      } else {
        // Container Variant
        variantInputs.add(
          VariantInput(
            name: 'Full ${_containerNameCtrl.text.trim()}',
            unitLabel: 'ml',
            conversionFactor: int.tryParse(_containerSizeCtrl.text.trim()) ?? 1,
            sellingPrice:
                (int.tryParse(
                      _volumeContainerState.sellingPriceCtrl.text.replaceAll(
                        ',',
                        '',
                      ),
                    ) ??
                    0) *
                100,
            costPrice:
                (int.tryParse(
                      _volumeContainerState.costPriceCtrl.text.replaceAll(
                        ',',
                        '',
                      ),
                    ) ??
                    0) *
                100,
            wholesalePrice:
                _volumeContainerState.wholesalePriceCtrl.text.isEmpty
                ? null
                : (int.tryParse(
                            _volumeContainerState.wholesalePriceCtrl.text
                                .replaceAll(',', ''),
                          ) ??
                          0) *
                      100,
            barcode: _volumeContainerState.barcodeCtrl.text.trim(),
            sku: _volumeContainerState.skuCtrl.text.trim(),
            isDefault: true,
          ),
        );
        // Serving Variants
        for (var v in _volumeServings) {
          variantInputs.add(
            VariantInput(
              name: v.nameCtrl.text.trim(),
              unitLabel: 'ml',
              conversionFactor: int.tryParse(v.sizeCtrl.text.trim()) ?? 1,
              sellingPrice:
                  (int.tryParse(v.sellingPriceCtrl.text.replaceAll(',', '')) ??
                      0) *
                  100,
              costPrice: 0,
              wholesalePrice: null,
              barcode: v.barcodeCtrl.text.trim(),
              sku: v.skuCtrl.text.trim(),
              isDefault: false,
            ),
          );
        }
      }

      await controller.saveProduct(
        name: _nameCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        reorderLevel: int.tryParse(_reorderCtrl.text.trim()) ?? 0,
        organisationId: orgId,
        baseUnit: _measurementType == MeasurementType.piece ? 'piece' : 'ml',
        containerSize: _measurementType == MeasurementType.volume
            ? int.tryParse(_containerSizeCtrl.text.trim())
            : null,
        containerName: _measurementType == MeasurementType.volume
            ? _containerNameCtrl.text.trim()
            : null,
        variants: variantInputs,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product created successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving product: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    final content = Scaffold(
      backgroundColor: widget.isSideSheet ? cs.surface : null,
      appBar: AppBar(
        title: const Text('New Product'),
        backgroundColor: widget.isSideSheet ? cs.surface : null,
        elevation: 0,
        actions: [
          if (widget.isSideSheet)
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.x),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: isDesktop ? StepperType.vertical : StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: _nextStep,
          onStepCancel: _prevStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == 3;
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: _isSaving ? null : details.onStepContinue,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastStep ? 'Save Product' : 'Continue'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Product Info'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'e.g. Tusker Lager 500ml',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const PhosphorIcon(PhosphorIconsRegular.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final categoriesAsync = ref.watch(categoriesProvider);
                      return categoriesAsync.when(
                        data: (categories) => DropdownButtonFormField<String>(
                          value: () {
                            if (_selectedCategoryId == null) return null;
                            if (categories.any((c) => c.id == _selectedCategoryId)) return _selectedCategoryId;
                            return null; // fallback if category is not yet in the list
                          }(),
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No Category'),
                            ),
                            ...categories.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                            const DropdownMenuItem(
                              value: '_add_new_',
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add new category', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (v) async {
                            if (v == '_add_new_') {
                              final newId = await AddCategoryDialog.show(context);
                              if (newId != null) {
                                setState(() => _selectedCategoryId = newId);
                              }
                            } else {
                              setState(() => _selectedCategoryId = v);
                            }
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) =>
                            const Text('Error loading categories'),
                      );
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Measurement Type'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  RadioListTile<MeasurementType>(
                    title: const Text('📦 By Piece'),
                    subtitle: const Text(
                      'Sold as whole items (bottles, cans, packets)',
                    ),
                    value: MeasurementType.piece,
                    groupValue: _measurementType,
                    onChanged: (v) => setState(() => _measurementType = v!),
                  ),
                  RadioListTile<MeasurementType>(
                    title: const Text('🥃 By Volume'),
                    subtitle: const Text(
                      'Sold in measured portions (spirits, wine, draft beer)',
                    ),
                    value: MeasurementType.volume,
                    groupValue: _measurementType,
                    onChanged: (v) => setState(() => _measurementType = v!),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Variants & Pricing'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _measurementType == MeasurementType.piece
                  ? _buildPieceVariants()
                  : _buildVolumeVariants(),
            ),
            Step(
              title: const Text('Stock Alerts'),
              isActive: _currentStep >= 3,
              content: TextFormField(
                controller: _reorderCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Reorder Level',
                  helperText: _measurementType == MeasurementType.piece
                      ? 'Alert me when stock falls below this number of base units'
                      : 'Alert me when stock falls below this number of containers',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isSideSheet) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        child: content,
      );
    }
    return content;
  }

  Widget _buildPieceVariants() {
    final baseName = _pieceVariants.isNotEmpty
        ? _pieceVariants.first.nameCtrl.text
        : '';
    return Column(
      children: [
        ..._pieceVariants.asMap().entries.map((entry) {
          final index = entry.key;
          final state = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: PieceVariantCard(
              state: state,
              baseName: baseName,
              onDelete: index == 0
                  ? null
                  : () => setState(() => _pieceVariants.removeAt(index)),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => setState(
            () => _pieceVariants.add(PieceVariantState(isBase: false)),
          ),
          icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 18),
          label: const Text('Add bulk option'),
        ),
      ],
    );
  }

  Widget _buildVolumeVariants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _containerNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Container Name',
                  hintText: 'e.g. Bottle, Keg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _containerSizeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Size (ml)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Servings',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._volumeServings.asMap().entries.map((entry) {
          final index = entry.key;
          final state = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: VolumeServingCard(
              state: state,
              onDelete: _volumeServings.length > 1
                  ? () => setState(() => _volumeServings.removeAt(index))
                  : null,
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () =>
              setState(() => _volumeServings.add(VolumeServingState())),
          icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 18),
          label: const Text('Add Serving Size'),
        ),
        const SizedBox(height: 24),
        VolumeContainerCard(
          state: _volumeContainerState,
          containerName: _containerNameCtrl.text.isNotEmpty
              ? _containerNameCtrl.text
              : 'Container',
          containerSize: _containerSizeCtrl.text.isNotEmpty
              ? _containerSizeCtrl.text
              : '-',
        ),
        if (_containerSizeCtrl.text.isNotEmpty &&
            _volumeServings.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildQuickMath(),
        ],
      ],
    );
  }

  Widget _buildQuickMath() {
    final containerSize = int.tryParse(_containerSizeCtrl.text) ?? 0;
    if (containerSize == 0) return const SizedBox();

    final parts = <String>[];
    for (var serving in _volumeServings) {
      final sSize = int.tryParse(serving.sizeCtrl.text) ?? 0;
      if (sSize > 0) {
        final count = containerSize / sSize;
        final name = serving.nameCtrl.text.isNotEmpty
            ? serving.nameCtrl.text
            : 'Servings';
        parts.add(
          '${count.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${name}s',
        );
      }
    }

    if (parts.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.info,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '1 ${_containerNameCtrl.text.isNotEmpty ? _containerNameCtrl.text : 'Container'} = ${parts.join(" or ")}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
