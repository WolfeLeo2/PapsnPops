import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QtyStepper extends StatelessWidget {
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
            onPressed: quantity > minQuantity ? () => onChanged(quantity - 1) : null,
            style: IconButton.styleFrom(
              foregroundColor: cs.onSurface,
              disabledForegroundColor: cs.onSurface.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(8),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.plus,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity + 1),
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
