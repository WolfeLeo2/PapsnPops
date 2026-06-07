import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
}

final supabase = Supabase.instance.client;
