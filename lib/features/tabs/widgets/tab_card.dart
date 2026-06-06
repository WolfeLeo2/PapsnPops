import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/models/open_tab.dart';
import '../../../core/utils/currency.dart';
import '../tabs_provider.dart';

class TabCard extends ConsumerStatefulWidget {
  final OpenTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const TabCard({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<TabCard> createState() => _TabCardState();
}

class _TabCardState extends ConsumerState<TabCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Rebuild every 30 seconds to update duration badge in real-time
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final duration = DateTime.now().difference(widget.tab.createdAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    // Urgency colors
    Color badgeColor;
    Color badgeTextColor;
    if (duration.inHours >= 2) {
      badgeColor = cs.errorContainer;
      badgeTextColor = cs.error;
    } else if (duration.inHours >= 1) {
      badgeColor = const Color(0xFFFEF3C7); // warningContainer
      badgeTextColor = const Color(0xFFB45309); // warning
    } else {
      badgeColor = const Color(0xFFDCFCE7); // successContainer
      badgeTextColor = const Color(0xFF166534); // success
    }

    final totalAsync = ref.watch(tabTotalProvider(widget.tab.id));
    final itemsAsync = ref.watch(tabItemsProvider(widget.tab.id));

    return Card(
      elevation: widget.isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: widget.isSelected ? cs.primary : Colors.transparent,
          width: widget.isSelected ? 2 : 0,
        ),
      ),
      color: widget.isSelected ? cs.primaryContainer.withValues(alpha: 0.1) : cs.surfaceContainerHigh,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top line: Name + Duration Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.tab.name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.clock,
                          size: 12,
                          color: badgeTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                          style: tt.labelSmall?.copyWith(
                            color: badgeTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Middle line: phone or subtitle
              if (widget.tab.phone != null && widget.tab.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.phone,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.tab.phone!,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // Bottom line: item count & total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  itemsAsync.when(
                    data: (items) {
                      final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
                      return Text(
                        count == 1 ? '1 item' : '$count items',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      );
                    },
                    loading: () => Text('...', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    error: (_, _) => Text('Error', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  totalAsync.when(
                    data: (total) => Text(
                      CurrencyHelper.format(total),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    loading: () => Text('...', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    error: (_, _) => Text('---', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
