import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'schema.dart';
import '../supabase/supabase_client.dart';
import '../../core/config/app_config.dart';

late PowerSyncDatabase db;

class DeadLetteredUpload {
  final String table;
  final String op;
  final String id;
  final String? code;
  final String message;
  DeadLetteredUpload(this.table, this.op, this.id, this.code, this.message);

  @override
  String toString() =>
      'DeadLetter($op $table#$id code=$code: $message)';
}

/// Reactive store of CRUD ops the server permanently rejected. These were
/// skipped (dead-lettered) so the upload queue could keep draining instead of
/// wedging on a single bad row. The UI listens to this to warn the user that
/// some changes did not sync and need follow-up.
class UploadDeadLetterStore extends ValueNotifier<List<DeadLetteredUpload>> {
  UploadDeadLetterStore() : super(const []);
  void add(DeadLetteredUpload dl) => value = [...value, dl];
  void clear() => value = const [];
}

final uploadDeadLetters = UploadDeadLetterStore();

/// Postgres SQLSTATE codes (and PostgREST codes) that will NEVER succeed on
/// retry. Re-sending these forever would freeze the entire upload queue and
/// strand every later write (e.g. sales) on-device. We skip the offending op
/// instead so the rest of the queue can flow.
const Set<String> _terminalSqlStates = {
  '23502', // not_null_violation
  '23503', // foreign_key_violation
  '23514', // check_violation
  '22P02', // invalid_text_representation (e.g. bad uuid)
  '22007', // invalid_datetime_format
  '22008', // datetime_field_overflow
  '42501', // insufficient_privilege (RLS denial / 403)
  '42703', // undefined_column (schema drift)
  '42P01', // undefined_table
  '42804', // datatype_mismatch
};

bool _isTerminal(PostgrestException e) {
  final code = e.code;
  if (code != null) {
    if (_terminalSqlStates.contains(code)) return true;
    // PostgREST-level errors (schema cache, malformed request) won't self-heal.
    if (code.startsWith('PGRST')) return true;
  }
  // RLS denials sometimes arrive as a 401/403 without a SQLSTATE code.
  final msg = e.message.toLowerCase();
  if (msg.contains('row-level security') ||
      msg.contains('violates') ||
      msg.contains('permission denied')) {
    return true;
  }
  return false;
}

class SupabaseConnector extends PowerSyncBackendConnector {
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    return PowerSyncCredentials(
      endpoint: AppConfig.powerSyncUrl,
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    // We process ops individually. A permanently-rejected op (RLS/constraint/
    // schema error) is skipped (dead-lettered) so it cannot freeze the queue and
    // strand later writes such as sales. Only transient errors (network, 5xx) are
    // rethrown, which leaves the transaction queued for a later retry.
    for (final op in transaction.crud) {
      try {
        Map<String, dynamic>? data;
        if (op.opData != null) {
          data = Map<String, dynamic>.from(op.opData!);

          // Replace any empty strings with null to avoid Postgres UUID parsing errors
          data.updateAll((key, value) => value == "" ? null : value);

          // PowerSync stores JSON arrays as stringified JSON.
          // Postgres array columns (like promotion_ids uuid[]) need them as Lists.
          if (data['promotion_ids'] is String) {
            try {
              data['promotion_ids'] = jsonDecode(data['promotion_ids']);
            } catch (_) {}
          }
        }

        switch (op.op) {
          case UpdateType.put:
            await supabase.from(op.table).upsert({...data!, 'id': op.id});
          case UpdateType.patch:
            await supabase.from(op.table).update(data!).eq('id', op.id);
          case UpdateType.delete:
            await supabase.from(op.table).delete().eq('id', op.id);
        }
      } on PostgrestException catch (e) {
        // 23505 (duplicate) means the row already exists server-side — the write
        // effectively succeeded, so treat it as done.
        if (e.code == '23505') {
          continue;
        }
        // Other permanent rejections: skip so the queue keeps flowing.
        if (_isTerminal(e)) {
          final dl = DeadLetteredUpload(
            op.table, op.op.toString(), op.id, e.code, e.message);
          uploadDeadLetters.add(dl);
          debugPrint('PowerSync upload dead-lettered: $dl');
          continue;
        }
        // Transient (e.g. 5xx). Abort without completing; PowerSync will retry
        // the whole transaction later.
        rethrow;
      }
    }

    await transaction.complete();
  }
}

Future<void> initializePowerSync() async {
  final dir = await getApplicationSupportDirectory();
  final path = join(dir.path, 'paps_n_pops.db');

  db = PowerSyncDatabase(schema: schema, path: path);
  await db.initialize();
}

Future<void> connectPowerSync() async {
  await db.connect(connector: SupabaseConnector());
}

/// Disconnects sync WITHOUT deleting local data.
///
/// Never call `disconnectAndClear()` on logout: it wipes the local DB including
/// any writes still waiting in the CRUD upload queue, which permanently loses
/// unsynced sales. `disconnect()` preserves everything; the queue resumes
/// uploading on the next `connect()`.
Future<void> disconnectPowerSync() async {
  await db.disconnect();
}

/// Clears all local data, but ONLY when nothing is waiting to upload — so we can
/// never destroy unsynced writes. Use this (instead of an unconditional clear)
/// when a different user is about to sign in on a shared device. Returns true if
/// the local DB was actually cleared.
Future<bool> clearLocalDataIfSynced() async {
  if (await hasPendingPowerSyncUploads()) return false;
  await db.disconnectAndClear();
  return true;
}

Future<bool> hasPendingPowerSyncUploads() async {
  final transaction = await db.getNextCrudTransaction();
  return transaction != null && transaction.crud.isNotEmpty;
}
