import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TenthingWidget extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const TenthingWidget({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<TenthingWidget> createState() => _TenthingWidgetState();
}

class _TenthingWidgetState extends State<TenthingWidget> {
  late double _currentValue;
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(0.0, 1.0);
    _controller = TextEditingController(text: _currentValue.toStringAsFixed(1));

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.text = _currentValue.toStringAsFixed(1);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TenthingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _currentValue = widget.initialValue.clamp(0.0, 1.0);
        if (!_focusNode.hasFocus) {
          _controller.text = _currentValue.toStringAsFixed(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateValue(double newValue) {
    final clamped = newValue.clamp(0.0, 1.0);
    setState(() {
      _currentValue = clamped;
      if (!_focusNode.hasFocus) {
        _controller.text = clamped.toStringAsFixed(1);
      }
    });
    widget.onChanged(clamped);
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) return;
    final value = double.tryParse(text);
    if (value != null) {
      final clamped = value.clamp(0.0, 1.0);
      setState(() {
        _currentValue = clamped;
      });
      widget.onChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.drop, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Level',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vertical Slider
          SizedBox(
            height: 180,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: cs.primary,
                  inactiveTrackColor: cs.surfaceContainerHigh,
                  thumbColor: cs.primary,
                  overlayColor: cs.primary.withValues(alpha: 0.12),
                  trackHeight: 12,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  value: _currentValue,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: _updateValue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Text Input
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              onChanged: _onTextChanged,
            ),
          ),
        ],
      ),
    );
  }
}
