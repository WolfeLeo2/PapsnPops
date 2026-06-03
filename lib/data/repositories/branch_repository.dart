import '../../domain/models/branch.dart';
import '../powersync/powersync_client.dart';

class BranchRepository {
  Future<List<Branch>> getBranches() async {
    final results = await db.getAll('SELECT * FROM branches');
    return results.map((row) => Branch.fromMap(row)).toList();
  }

  Stream<List<Branch>> watchBranches() {
    return db.watch('SELECT * FROM branches').map((results) {
      return results.map((row) => Branch.fromMap(row)).toList();
    });
  }
}
