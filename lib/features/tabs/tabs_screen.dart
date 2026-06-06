import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/stat_card.dart';
import '../../domain/models/open_tab.dart';
import '../../domain/models/customer.dart';
import '../../core/utils/currency.dart';
import '../../data/repositories/tab_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/branch_provider.dart';
import '../stock/stock_provider.dart' show generateV4Uuid;
import '../pos/pos_provider.dart' show activeStaffProvider;
import 'tabs_provider.dart';
import 'widgets/tab_card.dart';
import 'widgets/tab_detail_panel.dart';


class TabsScreen extends ConsumerWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final openTabsAsync = ref.watch(openTabsProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final summaryAsync = ref.watch(tabsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Open Tabs'
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: PhosphorIcon(isDesktop ? PhosphorIconsRegular.sidebar : PhosphorIconsRegular.list, size: 24),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Stats Bar (Square POS minimalist style)
          summaryAsync.when(
            data: (summary) {
              final longestMin = summary['longest_open_minutes'] as int;
              String longestStr = 'None';
              if (longestMin > 0) {
                if (longestMin >= 60) {
                  longestStr = '${longestMin ~/ 60}h ${longestMin % 60}m';
                } else {
                  longestStr = '$longestMin m';
                }
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Wrap(
                    spacing: 48,
                    runSpacing: 24,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildStatItem(context, 'Active Tabs', '${summary['count']}'),
                      _buildStatItem(context, 'Outstanding', CurrencyHelper.format(summary['total'] as int)),
                      _buildStatItem(context, 'Longest Open', longestStr),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 16),

          // Main content: Split panel on Desktop, list on Mobile
          Expanded(
            child: openTabsAsync.when(
              data: (tabs) {
                // Keep selected tab in sync if it is closed or none selected yet
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (tabs.isEmpty) {
                    if (ref.read(selectedTabProvider) != null) {
                      ref.read(selectedTabProvider.notifier).select(null);
                    }
                  } else {
                    final current = ref.read(selectedTabProvider);
                    if (current == null || !tabs.any((t) => t.id == current.id)) {
                      ref.read(selectedTabProvider.notifier).select(tabs.first);
                    }
                  }
                });

                if (tabs.isEmpty) {
                  return const EmptyState(
                    title: 'No open tabs',
                    message: 'Tap the button below to open a new bar tab.',
                    icon: PhosphorIconsDuotone.folders,
                  );
                }

                if (isDesktop) {
                  return Row(
                    children: [
                      // List panel
                      Expanded(
                        flex: 5,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: tabs.length,
                          itemBuilder: (context, index) {
                            final tab = tabs[index];
                            final isSelected = selectedTab?.id == tab.id;
                            return TabCard(
                              tab: tab,
                              isSelected: isSelected,
                              onTap: () {
                                ref.read(selectedTabProvider.notifier).select(tab);
                              },
                            );
                          },
                        ),
                      ),
                      // Details panel
                      Expanded(
                        flex: 4,
                        child: selectedTab != null
                            ? TabDetailPanel(
                                key: ValueKey(selectedTab.id),
                                tab: selectedTab,
                              )
                            : Container(
                                color: cs.surfaceContainerLow,
                                child: Center(
                                  child: Text(
                                    'Select a tab to view details',
                                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                } else {
                  // Mobile list
                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: tabs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      return TabCard(
                        tab: tab,
                        isSelected: false,
                        onTap: () {
                          // Push detail panel inside a scaffold
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text(tab.name),
                                ),
                                body: TabDetailPanel(
                                  tab: tab,
                                  isMobile: true,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
              loading: () => Center(
                child: Shimmer.fromColors(
                  baseColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  highlightColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              error: (err, __) => Center(
                child: Text('Error: $err', style: tt.bodyLarge?.copyWith(color: cs.error)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOpenTabDialog(context, ref),
        icon: const PhosphorIcon(PhosphorIconsRegular.plus, size: 20),
        label: const Text('New Tab'),
      ),
    );
  }

  void _showOpenTabDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    
    String? selectedCustomerId;
    List<Customer> suggestions = [];
    bool showSuggestions = false;
    String? selectedStaffId;

    final staffAsync = ref.read(activeStaffProvider);
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void onNameChanged(String query) async {
            if (query.trim().isEmpty) {
              setDialogState(() {
                suggestions = [];
                showSuggestions = false;
                selectedCustomerId = null;
              });
              return;
            }
            final repo = ref.read(customerRepositoryProvider);
            final results = await repo.searchCustomers(query);
            setDialogState(() {
              suggestions = results;
              showSuggestions = results.isNotEmpty;
            });
          }

          void selectCustomer(Customer customer) {
            setDialogState(() {
              selectedCustomerId = customer.id;
              nameCtrl.text = customer.name;
              phoneCtrl.text = customer.phone;
              showSuggestions = false;
            });
          }

          return AlertDialog(
            title: const Text('Open New Tab'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tab Name / Table Number',
                        prefixIcon: PhosphorIcon(PhosphorIconsRegular.tag),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Tab name is required';
                        }
                        return null;
                      },
                      onChanged: onNameChanged,
                    ),
                    if (showSuggestions) ...[
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          border: Border.all(color: cs.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final c = suggestions[index];
                            return ListTile(
                              title: Text(c.name),
                              subtitle: Text(c.phone),
                              onTap: () => selectCustomer(c),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        prefixIcon: PhosphorIcon(PhosphorIconsRegular.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    staffAsync.when(
                      data: (staffList) {
                        return DropdownButtonFormField<String>(
                          value: selectedStaffId,
                          hint: const Text('Opened By (Optional)'),
                          decoration: const InputDecoration(
                            labelText: 'Opened By Staff (Optional)',
                            prefixIcon: PhosphorIcon(PhosphorIconsRegular.user),
                            border: OutlineInputBorder(),
                          ),
                          items: staffList.map((s) {
                            return DropdownMenuItem<String>(
                              value: s['id'] as String,
                              child: Text(s['name'] as String),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => selectedStaffId = val),
                        );
                      },
                      loading: () => Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          border: Border.all(color: cs.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final scaffold = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    
                    final branchId = ref.read(currentBranchIdProvider);

                    if (branchId == null) {
                      scaffold.showSnackBar(
                        const SnackBar(content: Text('No active branch selected')),
                      );
                      return;
                    }

                    final tab = OpenTab(
                      id: generateV4Uuid(),
                      branchId: branchId,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                      openedBy: selectedStaffId,
                      customerId: selectedCustomerId,
                      isOpen: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    try {
                      await ref.read(tabRepositoryProvider).createTab(tab);
                      scaffold.showSnackBar(
                        SnackBar(content: Text('Tab "${tab.name}" opened successfully')),
                      );
                      nav.pop();
                    } catch (e) {
                      scaffold.showSnackBar(
                        SnackBar(content: Text('Failed to open tab: $e')),
                      );
                    }
                  }
                },
                child: const Text('Open Tab'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: tt.headlineMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
