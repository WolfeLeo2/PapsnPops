import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/supabase/supabase_client.dart';
import 'data/powersync/powersync_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeSupabase();
  await initializePowerSync();
  runApp(const ProviderScope(child: PapsnPopsApp()));
}
