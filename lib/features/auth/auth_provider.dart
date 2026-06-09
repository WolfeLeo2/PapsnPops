import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/supabase/supabase_client.dart';
import '../../data/powersync/powersync_client.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  User? build() {
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        connectPowerSync();
      } else {
        disconnectPowerSync();
      }
      state = session?.user;
    });
    return supabase.auth.currentUser;
  }

  bool get isOwner {
    if (state == null) return false;
    final metadata = state!.userMetadata;
    return metadata != null && metadata['role'] == 'owner';
  }

  Future<void> signUp(String email, String password) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  Future<void> verifyEmailOTP(String email, String token) async {
    await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  Future<void> resendSignupOTP(String email) async {
    await supabase.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyRecoveryOTPAndUpdatePassword(
    String email,
    String token,
    String newPassword,
  ) async {
    await supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String organisationId,
    required List<String> branchIds,
  }) async {
    final response = await supabase.functions.invoke(
      'create-user',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        'organisation_id': organisationId,
        'branch_ids': branchIds,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to create user: ${response.data}');
    }
  }

  Future<void> updateUserName(String id, String name) async {
    await supabase.from('user_profiles').update({'full_name': name}).eq('id', id);
  }

  Future<void> updateUserStatus(String id, bool isActive) async {
    await supabase.from('user_profiles').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> loginWithPassword(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await disconnectPowerSync();
    await supabase.auth.signOut();
  }
}
