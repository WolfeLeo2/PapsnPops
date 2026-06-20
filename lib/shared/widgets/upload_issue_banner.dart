import 'package:flutter/material.dart';

import '../../data/powersync/powersync_client.dart';

/// Persistent warning shown whenever the sync layer had to skip
/// ("dead-letter") one or more changes that the server permanently rejected.
///
/// This is critical for a POS: a skipped op means a sale/edit did NOT reach the
/// server. The user must know so they can re-enter it. Renders nothing when
/// there are no issues, so it is safe to mount at the top of every screen.
class UploadIssueBanner extends StatelessWidget {
  const UploadIssueBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<DeadLetteredUpload>>(
      valueListenable: uploadDeadLetters,
      builder: (context, deadLetters, _) {
        if (deadLetters.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final count = deadLetters.length;

        return Material(
          color: scheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$count change${count == 1 ? '' : 's'} could not be synced '
                      'and ${count == 1 ? 'was' : 'were'} skipped. '
                      'Affected sales/edits may need to be re-entered.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showDetails(context, deadLetters),
                    style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
                    child: const Text('Details'),
                  ),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: uploadDeadLetters.clear,
                    icon: Icon(Icons.close_rounded, color: scheme.onErrorContainer, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, List<DeadLetteredUpload> items) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsynced changes'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (_, i) {
              final dl = items[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${dl.op}  ·  ${dl.table}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('id: ${dl.id}',
                      style: Theme.of(ctx).textTheme.bodySmall),
                  Text('reason: ${dl.code ?? '—'} ${dl.message}',
                      style: Theme.of(ctx).textTheme.bodySmall),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              uploadDeadLetters.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
