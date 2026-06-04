import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/open_tab.dart';
import '../../domain/models/tab_item.dart';
import '../../data/repositories/tab_repository.dart';
import '../../data/repositories/branch_provider.dart';
import '../../data/powersync/powersync_client.dart';

part 'tabs_provider.g.dart';

@riverpod
Stream<List<OpenTab>> openTabs(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);
  return ref.watch(tabRepositoryProvider).watchOpenTabs(branchId);
}

@riverpod
Stream<List<TabItem>> tabItems(Ref ref, String tabId) {
  return ref.watch(tabRepositoryProvider).watchTabItems(tabId);
}

@riverpod
Stream<int> tabTotal(Ref ref, String tabId) {
  return ref.watch(tabRepositoryProvider).watchTabItems(tabId).map((items) {
    return items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));
  });
}

@riverpod
Stream<Map<String, dynamic>> tabsSummary(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) {
    return Stream.value({
      'count': 0,
      'total': 0,
      'longest_open_minutes': 0,
    });
  }
  return db.watch('''
    SELECT 
      COUNT(DISTINCT ot.id) as count,
      SUM(ti.quantity * ti.unit_price) as total,
      MIN(ot.created_at) as oldest_created_at
    FROM open_tabs ot
    LEFT JOIN tab_items ti ON ot.id = ti.tab_id
    WHERE ot.branch_id = ? AND ot.is_open = 1
  ''', parameters: [branchId]).map((rows) {
    if (rows.isEmpty || rows.first['count'] == 0) {
      return {
        'count': 0,
        'total': 0,
        'longest_open_minutes': 0,
      };
    }
    final row = rows.first;
    final count = row['count'] as int? ?? 0;
    final total = row['total'] as int? ?? 0;
    final oldestStr = row['oldest_created_at'] as String?;
    int longestOpenMinutes = 0;
    if (oldestStr != null) {
      final oldest = DateTime.parse(oldestStr);
      longestOpenMinutes = DateTime.now().difference(oldest).inMinutes;
    }
    return {
      'count': count,
      'total': total,
      'longest_open_minutes': longestOpenMinutes,
    };
  });
}

@riverpod
class SelectedTab extends _$SelectedTab {
  @override
  OpenTab? build() => null;

  void select(OpenTab? tab) => state = tab;
}
