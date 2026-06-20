import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AppScaffold extends ConsumerWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
