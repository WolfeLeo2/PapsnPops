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
  Future<void> updateStaffName(String id, String name) async {
    await supabase.from('staff').update({'name': name}).eq('id', id);
  }

  Future<void> updateStaffStatus(String id, bool isActive) async {
    await supabase.from('staff').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deleteStaffMember(String id) async {
    // Check if there are any sales for this staff member
    final result = await supabase
        .from('sales')
        .select('id')
        .eq('staff_id', id)
        .limit(1);

    if (result.isNotEmpty) {
      // Soft delete if they have transactions
      await updateStaffStatus(id, false);
    } else {
      // Hard delete if safe
      await supabase.from('staff').delete().eq('id', id);
    }
  }
}
