import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/branch.dart';
import '../../features/auth/auth_provider.dart';
import '../powersync/powersync_client.dart';
import 'branch_repository.dart';

part 'branch_provider.g.dart';

@Riverpod(keepAlive: true)
BranchRepository branchRepository(Ref ref) => BranchRepository();

@Riverpod(keepAlive: true)
Stream<List<Branch>> branchesStream(Ref ref) {
  return ref.watch(branchRepositoryProvider).watchBranches();
}

@Riverpod(keepAlive: true)
class CurrentBranchId extends _$CurrentBranchId {
  @override
  String? build() {
    final authUser = ref.watch(authProvider);
    if (authUser == null) return null;

    final metadata = authUser.userMetadata;
    final branchIds = metadata?['branch_ids'] as List<dynamic>?;
    final isOwner = metadata?['role'] == 'owner';

    // Cashier always gets their first assigned branch from metadata.
    if (!isOwner) {
      if (branchIds != null && branchIds.isNotEmpty) {
        return branchIds.first as String;
      }
      return null;
    }

    // Owner defaults to the first branch in metadata, but can switch it.
    if (branchIds != null && branchIds.isNotEmpty) {
      return branchIds.first as String;
    }
    return null;
  }

  void setBranchId(String branchId) {
    final authUser = ref.read(authProvider);
    final isOwner = authUser?.userMetadata?['role'] == 'owner';
    if (!isOwner) return; // Cashier is read-only

    state = branchId;
  }
}

@Riverpod(keepAlive: true)
Branch? currentBranch(Ref ref) {
  final currentId = ref.watch(currentBranchIdProvider);
  if (currentId == null) return null;

  final branchesAsync = ref.watch(branchesStreamProvider);
  return branchesAsync.when(
    data: (branches) {
      try {
        return branches.firstWhere((b) => b.id == currentId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (e, s) => null,
  );
}

@Riverpod(keepAlive: true)
Stream<int> openTabsCount(Ref ref) {
  return db
      .watch('SELECT COUNT(*) as count FROM open_tabs WHERE is_open = 1')
      .map((results) {
        if (results.isEmpty) return 0;
        return results.first['count'] as int;
      });
}
