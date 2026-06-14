import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/repositories/branch_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../data/powersync/powersync_client.dart';

class Sidebar extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isMobile;

  const Sidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.isMobile,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final hasPending = await hasPendingPowerSyncUploads();
    if (hasPending) {
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pending Uploads'),
          content: const Text(
            'You have offline data waiting to sync. If you log out now, this data will be permanently lost.\n\nPlease connect to the internet to sync before logging out.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Force Logout'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isOwner = user?.userMetadata?['role'] == 'owner';
    final currentPath = GoRouterState.of(context).uri.path;

    final openTabsCountAsync = ref.watch(openTabsCountProvider);
    final openTabsCount = openTabsCountAsync.value ?? 0;

    final currentBranchObj = ref.watch(currentBranchProvider);
    final currentBranchId = ref.watch(currentBranchIdProvider);
    final branchesAsync = ref.watch(branchesStreamProvider);

    final fullName = user?.userMetadata?['full_name'] as String? ?? 'User';
    final roleName = user?.userMetadata?['role'] as String? ?? 'staff';

    // Initials helper
    String initials = 'U';
    if (fullName.isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      initials = parts.map((e) => e.isNotEmpty ? e[0] : '').join();
      if (initials.length > 2) {
        initials = initials.substring(0, 2);
      }
      initials = initials.toUpperCase();
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Dropdown / static label for branch switcher
    Widget branchHeader;
    if (isExpanded) {
      if (isOwner) {
        branchHeader = branchesAsync.when(
          data: (branches) {
            if (branches.isEmpty) {
              return Text(
                'No branches',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              );
            }
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentBranchId,
                isExpanded: true,
                dropdownColor: cs.surfaceContainerHigh,
                icon: PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  color: cs.onSurfaceVariant,
                ),
                items: branches.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch.id,
                    child: Text(
                      branch.name,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(currentBranchIdProvider.notifier).setBranchId(val);
                  }
                },
              ),
            );
          },
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (err, stack) =>
              Text('Error', style: tt.bodySmall?.copyWith(color: cs.error)),
        );
      } else {
        branchHeader = Text(
          currentBranchObj?.name ?? 'Branch',
          style: tt.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        );
      }
    } else {
      branchHeader = CircleAvatar(
        radius: 18,
        backgroundColor: cs.primaryContainer,
        child: Text(
          (() {
            final name = currentBranchObj?.name ?? 'B';
            return name.isNotEmpty ? name[0].toUpperCase() : 'B';
          })(),
          style: tt.bodyMedium?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Navigation sections
    Widget sectionHeader(String title) {
      if (!isExpanded) return const SizedBox(height: 12);
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
        child: Text(
          title,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      );
    }

    return Material(
      color: cs.surfaceContainer,
      child: SizedBox(
        width: isExpanded ? (isMobile ? 260 : 188) : 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo & Header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isExpanded)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const PhosphorIcon(
                            PhosphorIconsDuotone.storefront,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'PAPs n\nPOPs',
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const PhosphorIcon(
                          PhosphorIconsDuotone.storefront,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  branchHeader,
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),

            // Scrollable Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  sectionHeader('MAIN'),
                  if (isOwner)
                    SidebarItem(
                      label: 'Dashboard',
                      path: '/dashboard',
                      regularIcon: PhosphorIconsRegular.chartBar,
                      fillIcon: PhosphorIconsFill.chartBar,
                      isExpanded: isExpanded,
                      currentPath: currentPath,
                      isMobile: isMobile,
                    ),
                  SidebarItem(
                    label: 'POS',
                    path: '/pos',
                    regularIcon: PhosphorIconsRegular.cashRegister,
                    fillIcon: PhosphorIconsFill.cashRegister,
                    isExpanded: isExpanded,
                    currentPath: currentPath,
                    isMobile: isMobile,
                  ),
                  SidebarItem(
                    label: 'Open Tabs',
                    path: '/tabs',
                    regularIcon: PhosphorIconsRegular.folders,
                    fillIcon: PhosphorIconsFill.folders,
                    isExpanded: isExpanded,
                    currentPath: currentPath,
                    isMobile: isMobile,
                    badgeCount: openTabsCount,
                  ),
                  SidebarItem(
                    label: 'Sales',
                    path: '/sales',
                    regularIcon: PhosphorIconsRegular.receipt,
                    fillIcon: PhosphorIconsFill.receipt,
                    isExpanded: isExpanded,
                    currentPath: currentPath,
                    isMobile: isMobile,
                  ),

                  sectionHeader('INVENTORY'),
                  SidebarItem(
                    label: 'Products',
                    path: '/products',
                    regularIcon: PhosphorIconsRegular.shoppingBag,
                    fillIcon: PhosphorIconsFill.shoppingBag,
                    isExpanded: isExpanded,
                    currentPath: currentPath,
                    isMobile: isMobile,
                  ),
                  SidebarItem(
                    label: 'Stock Adjustment',
                    path: '/stock',
                    regularIcon: PhosphorIconsRegular.package,
                    fillIcon: PhosphorIconsFill.package,
                    isExpanded: isExpanded,
                    currentPath: currentPath,
                    isMobile: isMobile,
                  ),
                  if (isOwner)
                    SidebarItem(
                      label: 'Stock Review',
                      path: '/stock-review',
                      regularIcon: PhosphorIconsRegular.clipboardText,
                      fillIcon: PhosphorIconsFill.clipboardText,
                      isExpanded: isExpanded,
                      currentPath: currentPath,
                      isMobile: isMobile,
                    ),

                  if (isOwner) ...[
                    sectionHeader('REPORTS'),
                    SidebarItem(
                      label: 'Reports',
                      path: '/reports',
                      regularIcon: PhosphorIconsRegular.chartLine,
                      fillIcon: PhosphorIconsFill.chartLine,
                      isExpanded: isExpanded,
                      currentPath: currentPath,
                      isMobile: isMobile,
                    ),
                  ],

                  if (isOwner) ...[
                    sectionHeader('SETTINGS'),
                    SidebarItem(
                      label: 'Settings',
                      path: '/settings',
                      regularIcon: PhosphorIconsRegular.gear,
                      fillIcon: PhosphorIconsFill.gear,
                      isExpanded: isExpanded,
                      currentPath: currentPath,
                      isMobile: isMobile,
                    ),
                  ],
                ],
              ),
            ),

            // Footer - User profile
            Padding(
              padding: const EdgeInsets.all(16),
              child: isExpanded
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: cs.primary.withValues(alpha: 0.1),
                            child: Text(
                              initials,
                              style: tt.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  fullName,
                                  style: tt.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  roleName.toUpperCase(),
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const PhosphorIcon(PhosphorIconsRegular.signOut),
                            color: cs.error,
                            onPressed: () => _handleLogout(context, ref),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                    )
                  : PopupMenuButton<String>(
                      tooltip: '$fullName ($roleName)',
                      offset: const Offset(50, 0),
                      onSelected: (val) {
                        if (val == 'logout') {
                          _handleLogout(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Logout'),
                        ),
                      ],
                      child: Center(
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          child: Text(
                            initials,
                            style: tt.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final String label;
  final String path;
  final IconData regularIcon;
  final IconData fillIcon;
  final bool isExpanded;
  final String currentPath;
  final int? badgeCount;
  final bool isMobile;

  const SidebarItem({
    super.key,
    required this.label,
    required this.path,
    required this.regularIcon,
    required this.fillIcon,
    required this.isExpanded,
    required this.currentPath,
    required this.isMobile,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = path == '/'
        ? currentPath == '/'
        : currentPath.startsWith(path);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget titleWidget = Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (badgeCount != null && badgeCount! > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badgeCount',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );

    if (!isExpanded) {
      return Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: InkWell(
            onTap: () {
              if (isMobile) Navigator.of(context).pop();
              context.go(path);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PhosphorIcon(
                    isActive ? fillIcon : regularIcon,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      top: 0,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isActive,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        leading: PhosphorIcon(
          isActive ? fillIcon : regularIcon,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 20,
        ),
        title: titleWidget,
        onTap: () {
          if (isMobile) {
            Navigator.of(context).pop();
          }
          context.go(path);
        },
      ),
    );
  }
}
