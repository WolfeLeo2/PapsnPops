import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../pos_provider.dart';

class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final methods = [
      (
        value: 'cash',
        label: 'Cash',
        icon: PhosphorIconsRegular.money,
      ),
      (
        value: 'mpesa',
        label: 'M-Pesa',
        icon: PhosphorIconsRegular.deviceMobile,
      ),
      (
        value: 'card',
        label: 'Card',
        icon: PhosphorIconsRegular.creditCard,
      ),
    ];

    return Row(
      children: methods.map((method) {
        final isSelected = selectedMethod == method.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              avatar: PhosphorIcon(
                method.icon,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                size: 18,
              ),
              label: Text(
                method.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedPaymentMethodProvider.notifier).set(method.value);
                }
              },
              selectedColor: cs.primary,
              backgroundColor: cs.surfaceContainer,
              checkmarkColor: Colors.transparent,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
