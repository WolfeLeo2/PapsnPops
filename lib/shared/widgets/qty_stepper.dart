import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QtyStepper extends StatefulWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int minQuantity;

  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 1,
  });

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      } else {
        // When losing focus, ensure empty text reverts to the min quantity
        if (_controller.text.isEmpty) {
          _controller.text = widget.minQuantity.toString();
          widget.onChanged(widget.minQuantity);
        }
      }
    });
  }

  @override
  void didUpdateWidget(QtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      final newText = widget.quantity.toString();
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitText(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= widget.minQuantity) {
      widget.onChanged(parsed);
    } else {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.minus,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: widget.quantity > widget.minQuantity
                ? () => widget.onChanged(widget.quantity - 1)
                : null,
            style: IconButton.styleFrom(
              foregroundColor: cs.onSurface,
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(8),
            ),
          ),
          SizedBox(
            width: 48, // Slightly wider for text input
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: _submitText,
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed >= widget.minQuantity) {
                  widget.onChanged(parsed);
                }
              },
            ),
          ),
          IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.plus,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => widget.onChanged(widget.quantity + 1),
            style: IconButton.styleFrom(
              foregroundColor: cs.onSurface,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}
