import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/powersync/powersync_client.dart';

/// Shows live sync status (connection + last synced) and a support action to
/// wipe the local database and re-download everything from the server.
///
/// Global to all users (no RBAC). The reset is the deliberate, confirmed place
/// we DO call `disconnectAndClear()` — it discards un-uploaded local changes, so
/// it's gated behind a warning when there are pending uploads.
class SyncResetTile extends StatefulWidget {
  const SyncResetTile({super.key});

  @override
  State<SyncResetTile> createState() => _SyncResetTileState();
}

class _SyncResetTileState extends State<SyncResetTile> {
  bool _busy = false;

  Future<void> _reset() async {
    final messenger = ScaffoldMessenger.of(context);
    final hasPending = await hasPendingPowerSyncUploads();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset local data & re-sync'),
        content: Text(
          hasPending
              ? 'This device has changes that have NOT been uploaded yet. '
                'Resetting will permanently discard them, then re-download '
                'everything from the server. Continue?'
              : 'This clears the local copy and re-downloads everything from '
                'the server. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Reset & re-sync'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await db.disconnectAndClear();
      await connectPowerSync();
      messenger.showSnackBar(
        const SnackBar(content: Text('Local data cleared. Re-syncing…')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: db.statusStream,
      initialData: db.currentStatus,
      builder: (context, snapshot) {
        final s = snapshot.data;
        final connected = s?.connected ?? false;
        final lastSynced = s?.lastSyncedAt;
        final error = s?.uploadError ?? s?.downloadError;

        final String subtitle;
        if (error != null) {
          subtitle = 'Sync error — tap to reset';
        } else if (lastSynced != null) {
          subtitle =
              '${connected ? 'Connected' : 'Offline'} · last synced '
              '${DateFormat('MMM d, HH:mm').format(lastSynced.toLocal())}';
        } else {
          subtitle = connected ? 'Connected · syncing…' : 'Not synced yet';
        }

        return ListTile(
          leading: _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const PhosphorIcon(PhosphorIconsRegular.arrowsClockwise),
          title: const Text('Reset local data & re-sync'),
          subtitle: Text(subtitle),
          onTap: _busy ? null : _reset,
        );
      },
    );
  }
}
