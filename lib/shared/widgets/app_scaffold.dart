import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/update_service.dart';
import 'sidebar.dart';
import 'upload_issue_banner.dart';

class RailExpanded extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final railExpandedProvider = NotifierProvider<RailExpanded, bool>(
  RailExpanded.new,
);

class AppScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  @override
  void initState() {
    super.initState();
    // Run once per session for the whole app (this shell persists across all
    // in-app navigation), so every role — including cashiers who never see the
    // dashboard — gets the update prompt regardless of which screen they're on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(updateServiceProvider).checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Sidebar(
                  isExpanded: ref.watch(railExpandedProvider),
                  onToggle: () =>
                      ref.read(railExpandedProvider.notifier).toggle(),
                  isMobile: false,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      const UploadIssueBanner(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: Drawer(
            width: 260,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            child: SafeArea(
              child: Sidebar(isExpanded: true, onToggle: () {}, isMobile: true),
            ),
          ),
          body: Column(
            children: [
              const UploadIssueBanner(),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
