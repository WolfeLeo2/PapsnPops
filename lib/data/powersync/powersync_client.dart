import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'schema.dart';
import '../supabase/supabase_client.dart';

late PowerSyncDatabase db;

class SupabaseConnector extends PowerSyncBackendConnector {
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    return PowerSyncCredentials(
      endpoint: dotenv.env['POWERSYNC_URL']!,
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (final op in transaction.crud) {
        Map<String, dynamic>? data;
        if (op.opData != null) {
          data = Map<String, dynamic>.from(op.opData!);
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
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        await transaction.complete();
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
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

Future<void> disconnectPowerSync() async {
  await db.disconnectAndClear();
}
