import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(isDesktop ? Icons.menu_open : Icons.menu),
              onPressed: () {
                if (isDesktop) {
                  ref.read(railExpandedProvider.notifier).toggle();
                } else {
                  context
                      .findRootAncestorStateOfType<ScaffoldState>()
                      ?.openDrawer();
                }
              },
            );
          },
        ),
      ),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}
