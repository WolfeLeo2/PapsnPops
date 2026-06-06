import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/powersync/powersync_client.dart';
import '../../data/repositories/branch_provider.dart';

part 'settings_data_provider.g.dart';

@riverpod
Stream<List<Map<String, dynamic>>> allStaffStream(Ref ref) {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId == null) return Stream.value([]);

  return db.watch(
    'SELECT * FROM staff WHERE branch_id = ? ORDER BY name ASC',
    parameters: [branchId],
  ).map((results) => results.toList());
}

@riverpod
Stream<List<Map<String, dynamic>>> allPromotionsStream(Ref ref) {
  return db.watch(
    'SELECT * FROM promotions ORDER BY created_at DESC',
  ).map((results) => results.toList());
}

@riverpod
Stream<List<Map<String, dynamic>>> allUsersStream(Ref ref) {
  // Wait, owner can see all users, but user_profiles is synced based on branch access.
  // We'll just fetch all local user profiles since PowerSync handles the branch filtering.
  return db.watch(
    'SELECT * FROM user_profiles ORDER BY full_name ASC',
  ).map((results) => results.toList());
}
