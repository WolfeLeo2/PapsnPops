import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

class UpdateService {
  final Dio _dio = Dio();
  static const _repoUrl = 'https://api.github.com/repos/WolfeLeo2/PapsnPops/releases/latest';

  Future<void> checkForUpdates(BuildContext context) async {
    if (!Platform.isWindows) return;

    try {
      final response = await _dio.get(_repoUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = data['tag_name'] as String;
        // The tag might be "v1.0.4", let's strip the 'v'
        final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        // Set to true only when testing UI, otherwise false
        final bool isMockTesting = false;
        
        // Simple version check (assumes semantic versioning like 1.0.4)
        if (isMockTesting || _isNewerVersion(latestVersion, currentVersion)) {
          final assets = data['assets'] as List;
          final installerAsset = assets.firstWhere(
            (asset) => (asset['name'] as String).endsWith('.exe'),
            orElse: () => null,
          );

          if (installerAsset != null) {
            final downloadUrl = installerAsset['browser_download_url'] as String;
            if (context.mounted) {
              _showUpdateBanner(context, latestVersion, downloadUrl);
            }
          }
        }
      }
    } catch (e) {
      // Silently fail on network/update errors so it doesn't disrupt the user
      debugPrint('Error checking for updates: $e');
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

  void _showUpdateBanner(BuildContext context, String version, String downloadUrl) {
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

  Future<void> downloadAndInstallUpdate(String url, Function(double) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}\\PAPs_n_POPs_Installer.exe';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Execute installer and exit
      await Process.start(savePath, [], mode: ProcessStartMode.detached);
      exit(0);
    } catch (e) {
      debugPrint('Error downloading update: $e');
      throw Exception('Failed to download update.');
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
