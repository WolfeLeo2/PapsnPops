import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository();
});

class StaffRepository {
  Future<void> addStaff({
    required String branchId,
    required String name,
    required String roleLabel,
  }) async {
    await supabase.from('staff').insert({
      'branch_id': branchId,
      'name': name,
      'role_label': roleLabel,
      'is_active': true,
    });
  }
}
