import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/utils/update_service.dart';

/// Settings tile that shows the installed app version and, on supported
/// platforms (Android/Windows), whether an update is available. Tapping when an
/// update exists starts it: launches the download URL on Android, or shows the
/// progress banner on Windows (both reuse [UpdateService]).
class AppVersionTile extends ConsumerStatefulWidget {
  const AppVersionTile({super.key});

  @override
  ConsumerState<AppVersionTile> createState() => _AppVersionTileState();
}

class _AppVersionTileState extends ConsumerState<AppVersionTile> {
  UpdateStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    final status = await ref.read(updateServiceProvider).fetchUpdateStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<void> _onTap() async {
    final status = _status;
    if (_loading) return;

    // Couldn't reach the release info — let the user retry.
    if (status == null || status.failed) {
      await _check();
      return;
    }

    if (!status.updateAvailable) return;

    // Both platforms now download in-app with progress, so reuse the banner,
    // which shows the progress bar and performs the platform-specific install.
    ref
        .read(updateServiceProvider)
        .showUpdateBanner(context, status.latestVersion!, status.downloadUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = _status;

    final version = status?.currentVersion;
    final updateAvailable = status?.updateAvailable ?? false;
    final failed = status?.failed ?? false;
    final unsupported = status != null && !status.supported;

    final String subtitle;
    final Widget trailing;
    IconData leadingIcon = PhosphorIconsRegular.info;
    Color? leadingColor;

    if (_loading) {
      subtitle = 'Checking for updates…';
      trailing = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (updateAvailable) {
      subtitle = 'Update available: v${status!.latestVersion}';
      leadingIcon = PhosphorIconsRegular.downloadSimple;
      leadingColor = cs.primary;
      trailing = FilledButton.tonal(
        onPressed: _onTap,
        child: const Text('Update'),
      );
    } else if (failed) {
      subtitle = "Couldn't check for updates — tap to retry";
      leadingIcon = PhosphorIconsRegular.warningCircle;
      leadingColor = cs.error;
      trailing = IconButton(
        tooltip: 'Retry',
        icon: const Icon(Icons.refresh_rounded),
        onPressed: _check,
      );
    } else if (unsupported) {
      subtitle = 'v${version ?? '—'}';
      trailing = const SizedBox.shrink();
    } else {
      subtitle = "You're on the latest version";
      leadingIcon = PhosphorIconsRegular.checkCircle;
      trailing = Icon(PhosphorIconsRegular.checkCircle, color: cs.primary, size: 20);
    }

    return ListTile(
      leading: PhosphorIcon(leadingIcon, color: leadingColor),
      title: Text('App Version${version != null ? '  ·  v$version' : ''}'),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: (updateAvailable || failed) ? _onTap : null,
    );
  }
}
