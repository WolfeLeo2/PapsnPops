import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'stock_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/widgets/empty_state.dart';

class StockAdjustmentsReviewScreen extends ConsumerWidget {
  const StockAdjustmentsReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjustmentsAsync = ref.watch(stockAdjustmentsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Adjustments Review'),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => context
                      .findRootAncestorStateOfType<ScaffoldState>()
                      ?.openDrawer(),
                ),
              ),
      ),
      body: adjustmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (adjustments) {
          if (adjustments.isEmpty) {
            return const EmptyState(
              icon: PhosphorIconsRegular.clipboardText,
              title: 'No adjustments',
              message: 'No stock adjustments found.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: adjustments.length,
            itemBuilder: (context, i) {
              return _AdjustmentTile(record: adjustments[i]);
            },
          );
        },
      ),
    );
  }
}

class _AdjustmentTile extends ConsumerWidget {
  final StockAdjustmentRecord record;

  const _AdjustmentTile({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    // The quantity delta
    final isPositive = record.quantityDelta > 0;
    final sign = isPositive ? '+' : '';
    final deltaColor = record.isReverted 
        ? colorScheme.onSurfaceVariant
        : (isPositive ? colorScheme.primary : colorScheme.error);

    return Opacity(
      opacity: record.isReverted ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.isReverted 
                            ? '${record.reason.isNotEmpty ? record.reason : 'Adjustment'} (Reverted)'
                            : (record.reason.isNotEmpty ? record.reason : 'Adjustment'),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: record.isReverted ? colorScheme.onSurfaceVariant : colorScheme.primary,
                          decoration: record.isReverted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (record.stockAfter != null) ...[
                      Text(
                        'New Total: ',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${record.stockAfter}',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: deltaColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$sign${record.quantityDelta}',
                        style: TextStyle(
                          color: deltaColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (record.referenceId != null && record.referenceId!.isNotEmpty) ...[
                  Text(
                    'Ref: ${record.referenceId}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  record.productName,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: record.isReverted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.storefront,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.branchName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.user,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.userName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.calendar,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(record.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (!record.isReverted)
                      TextButton.icon(
                        onPressed: () => _confirmRevert(context, ref, record),
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.arrowUUpLeft,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        label: Text(
                          'Revert',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRevert(BuildContext context, WidgetRef ref, StockAdjustmentRecord record) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert Adjustment'),
        content: Text('Are you sure you want to revert this adjustment for ${record.productName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revert'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final userId = ref.read(authProvider)?.id;
        if (userId == null) throw Exception('Not logged in');
        
        await ref.read(stockAdjustmentControllerProvider).revertAdjustment(
          movementId: record.id,
          branchId: record.branchId,
          productId: record.productId,
          originalQuantityDelta: record.quantityDelta,
          userId: userId,
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adjustment reverted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to revert: $e')),
          );
        }
      }
    }
  }
}
