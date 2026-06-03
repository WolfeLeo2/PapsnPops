import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../add_product_screen.dart';

class PieceVariantCard extends StatefulWidget {
  final PieceVariantState state;
  final String baseName;
  final VoidCallback? onDelete;

  const PieceVariantCard({
    super.key,
    required this.state,
    required this.baseName,
    this.onDelete,
  });

  @override
  State<PieceVariantCard> createState() => _PieceVariantCardState();
}

class _PieceVariantCardState extends State<PieceVariantCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.state.showAdvanced ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleAdvanced() {
    setState(() {
      widget.state.showAdvanced = !widget.state.showAdvanced;
      if (widget.state.showAdvanced) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isBase = widget.state.isBase;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                if (isBase)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'BASE OPTION',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    'Bulk Option',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.trash,
                      size: 18,
                      color: cs.error,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _FormField(
              controller: widget.state.nameCtrl,
              label: isBase ? 'Name' : 'Name (e.g. Crate, Pack)',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          if (!isBase) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FormField(
                controller: widget.state.quantityCtrl,
                label:
                    'How many ${widget.baseName.isNotEmpty ? widget.baseName : "base units"} in a ${widget.state.nameCtrl.text.isNotEmpty ? widget.state.nameCtrl.text : "bulk unit"}?',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 1) return 'Must be > 1';
                  return null;
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _PriceField(
                    controller: widget.state.sellingPriceCtrl,
                    label: 'Selling price',
                    validator: (v) => _validatePrice(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceField(
                    controller: widget.state.costPriceCtrl,
                    label: 'Cost price',
                    validator: (v) => _validatePrice(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PriceField(
              controller: widget.state.wholesalePriceCtrl,
              label: 'Wholesale price (optional)',
            ),
          ),
          const SizedBox(height: 12),
          _AdvancedToggle(
            isExpanded: widget.state.showAdvanced,
            onTap: _toggleAdvanced,
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: widget.state.barcodeCtrl,
                      label: 'Barcode',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      controller: widget.state.skuCtrl,
                      label: 'SKU',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.state.showAdvanced) const SizedBox(height: 16),
        ],
      ),
    );
  }

  String? _validatePrice(String? v) {
    final n = int.tryParse(v?.replaceAll(',', '') ?? '');
    if (n == null || n < 1) return 'Required';
    return null;
  }
}

class VolumeServingCard extends StatefulWidget {
  final VolumeServingState state;
  final VoidCallback? onDelete;

  const VolumeServingCard({super.key, required this.state, this.onDelete});

  @override
  State<VolumeServingCard> createState() => _VolumeServingCardState();
}

class _VolumeServingCardState extends State<VolumeServingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.state.showAdvanced ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleAdvanced() {
    setState(() {
      widget.state.showAdvanced = !widget.state.showAdvanced;
      if (widget.state.showAdvanced) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  'Serving Size',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: PhosphorIcon(
                      PhosphorIconsRegular.trash,
                      size: 18,
                      color: cs.error,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _FormField(
                    controller: widget.state.nameCtrl,
                    label: 'Name (e.g. Shot)',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _FormField(
                    controller: widget.state.sizeCtrl,
                    label: 'Size (ml)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PriceField(
              controller: widget.state.sellingPriceCtrl,
              label: 'Selling price',
              validator: (v) {
                final n = int.tryParse(v?.replaceAll(',', '') ?? '');
                if (n == null || n < 1) return 'Required';
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          _AdvancedToggle(
            isExpanded: widget.state.showAdvanced,
            onTap: _toggleAdvanced,
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: widget.state.barcodeCtrl,
                      label: 'Barcode',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      controller: widget.state.skuCtrl,
                      label: 'SKU',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.state.showAdvanced) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class VolumeContainerCard extends StatefulWidget {
  final VolumeContainerState state;
  final String containerName;
  final String containerSize;

  const VolumeContainerCard({
    super.key,
    required this.state,
    required this.containerName,
    required this.containerSize,
  });

  @override
  State<VolumeContainerCard> createState() => _VolumeContainerCardState();
}

class _VolumeContainerCardState extends State<VolumeContainerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.state.showAdvanced ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleAdvanced() {
    setState(() {
      widget.state.showAdvanced = !widget.state.showAdvanced;
      if (widget.state.showAdvanced) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Full Container (Auto-generated)',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const PhosphorIcon(PhosphorIconsRegular.lockKey, size: 18),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: 'Full ${widget.containerName}',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: cs.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: widget.containerSize,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Size (ml)',
                      filled: true,
                      fillColor: cs.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _PriceField(
                    controller: widget.state.sellingPriceCtrl,
                    label: 'Selling price',
                    validator: (v) {
                      final n = int.tryParse(v?.replaceAll(',', '') ?? '');
                      if (n == null || n < 1) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PriceField(
                    controller: widget.state.costPriceCtrl,
                    label: 'Cost price',
                    validator: (v) {
                      final n = int.tryParse(v?.replaceAll(',', '') ?? '');
                      if (n == null || n < 1) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PriceField(
              controller: widget.state.wholesalePriceCtrl,
              label: 'Wholesale price (optional)',
            ),
          ),
          const SizedBox(height: 12),
          _AdvancedToggle(
            isExpanded: widget.state.showAdvanced,
            onTap: _toggleAdvanced,
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: widget.state.barcodeCtrl,
                      label: 'Barcode',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormField(
                      controller: widget.state.skuCtrl,
                      label: 'SKU',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.state.showAdvanced) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AdvancedToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _AdvancedToggle({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Advanced (barcode, SKU)',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;

  const _PriceField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'KES ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
