import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// Result of an update check, with no UI side effects.
class UpdateStatus {
  /// The currently-installed app version (e.g. "1.8.0").
  final String currentVersion;

  /// The latest released version, if the check succeeded (e.g. "1.8.1").
  final String? latestVersion;

  /// Direct installer URL for this platform, set only when a newer version with
  /// a matching asset (.apk / .exe) exists.
  final String? downloadUrl;

  /// Whether this platform supports in-app updates (Android / Windows).
  final bool supported;

  /// Whether the check failed (network/parse error). Distinct from "up to date".
  final bool failed;

  const UpdateStatus({
    required this.currentVersion,
    this.latestVersion,
    this.downloadUrl,
    this.supported = true,
    this.failed = false,
  });

  /// True when a newer version is installable on this platform.
  bool get updateAvailable => downloadUrl != null && latestVersion != null;
}

class UpdateService {
  final Dio _dio = Dio();
  static const _repoUrl = 'https://api.github.com/repos/WolfeLeo2/PapsnPops/releases/latest';

  /// Guards against re-prompting on the same app run. The shell that triggers
  /// the check can remount (e.g. on auth token refresh), so without this the
  /// banner could re-appear even after the user dismissed it with "Later".
  bool _alreadyChecked = false;

  /// Auto-check used on app launch (from AppScaffold). Guarded so it runs once
  /// per session and shows the banner only when an update is actually available.
  Future<void> checkForUpdates(BuildContext context) async {
    if (!Platform.isWindows && !Platform.isAndroid) return;
    if (_alreadyChecked) return;
    _alreadyChecked = true;

    final status = await fetchUpdateStatus();
    if (status.failed) {
      // Allow a retry later this session since the failure was transient.
      _alreadyChecked = false;
      return;
    }
    if (status.updateAvailable && context.mounted) {
      showUpdateBanner(context, status.latestVersion!, status.downloadUrl!);
    }
  }

  /// Queries the latest GitHub release and reports update status WITHOUT showing
  /// any UI. Used by the Settings tile so it can display the current version and
  /// whether an update exists. Never throws — failures are reported via
  /// [UpdateStatus.failed].
  Future<UpdateStatus> fetchUpdateStatus() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (!Platform.isWindows && !Platform.isAndroid) {
      return UpdateStatus(currentVersion: currentVersion, supported: false);
    }

    try {
      final response = await _dio.get(
        _repoUrl,
        options: Options(
          // GitHub's REST API returns 403 if there is no User-Agent header.
          headers: {
            'User-Agent': 'PapsnPops-App',
            'Accept': 'application/vnd.github+json',
          },
          // Don't let Dio throw on non-2xx; we handle status explicitly below.
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode != 200) {
        debugPrint('Update check HTTP ${response.statusCode}: ${response.data}');
        return UpdateStatus(currentVersion: currentVersion, failed: true);
      }
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final tagName = data['tag_name'] as String;
      // The tag might be "v1.0.4", strip the leading 'v'.
      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      String? downloadUrl;
      if (_isNewerVersion(latestVersion, currentVersion)) {
        final assets = data['assets'] as List;
        final extensionTarget = Platform.isWindows ? '.exe' : '.apk';
        final installerAsset = assets.firstWhere(
          (asset) => (asset['name'] as String).endsWith(extensionTarget),
          orElse: () => null,
        );
        if (installerAsset != null) {
          downloadUrl = installerAsset['browser_download_url'] as String;
        }
      }

      return UpdateStatus(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return UpdateStatus(currentVersion: currentVersion, failed: true);
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      
      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true; // 1.0.1 vs 1.0
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false; // Equal or older
    } catch (_) {
      return false;
    }
  }

  void showUpdateBanner(BuildContext context, String version, String downloadUrl) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: _UpdateBannerContent(
          version: version,
          downloadUrl: downloadUrl,
          updateService: this,
        ),
        actions: const [SizedBox.shrink()], // Actions handled inside the content to allow state changes
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 2,
      ),
    );
  }

  /// Downloads the installer for this platform (reporting [onProgress] 0..1) and
  /// then launches it:
  ///  - Android: opens the system package installer for the downloaded APK.
  ///  - Windows: runs the Inno Setup installer silently; it replaces the running
  ///    exe and relaunches the app, so this never returns (the app exits).
  Future<void> downloadAndInstallUpdate(String url, void Function(double) onProgress) async {
    final tempDir = await getTemporaryDirectory();

    if (Platform.isAndroid) {
      final savePath = '${tempDir.path}/PAPs_n_POPs_update.apk';
      try {
        await _dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0) onProgress(received / total);
          },
        );
      } catch (e) {
        debugPrint('Error downloading update: $e');
        throw Exception('Failed to download update.');
      }

      // Hand the APK to the system installer (requires REQUEST_INSTALL_PACKAGES
      // + the user's one-time "install unknown apps" consent).
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw Exception('Could not open the installer: ${result.message}');
      }
      return;
    }

    if (Platform.isWindows) {
      final savePath = '${tempDir.path}\\PAPs_n_POPs_Installer.exe';
      try {
        await _dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0) onProgress(received / total);
          },
        );
      } catch (e) {
        debugPrint('Error downloading update: $e');
        throw Exception('Failed to download update.');
      }

      // Silent install. UAC may still prompt once (installer needs elevation);
      // the installer replaces the running exe and relaunches the app for us.
      await Process.start(
        savePath,
        ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'],
        mode: ProcessStartMode.detached,
      );
      exit(0);
    }
  }
}

class _UpdateBannerContent extends StatefulWidget {
  final String version;
  final String downloadUrl;
  final UpdateService updateService;

  const _UpdateBannerContent({
    required this.version,
    required this.downloadUrl,
    required this.updateService,
  });

  @override
  State<_UpdateBannerContent> createState() => _UpdateBannerContentState();
}

class _UpdateBannerContentState extends State<_UpdateBannerContent> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    try {
      await widget.updateService.downloadAndInstallUpdate(widget.downloadUrl, (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Failed to download update. Please try again later.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
            ),
          ),
        if (!_isDownloading)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Version ${widget.version} is available! Update now?',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
                child: const Text('Later'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _startUpdate,
                child: const Text('Update Now'),
              ),
            ],
          ),
        if (_isDownloading) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Downloading update... ${(_progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _progress),
        ],
      ],
    );
  }
}
