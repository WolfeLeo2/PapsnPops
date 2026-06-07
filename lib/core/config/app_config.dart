/// App configuration loaded via --dart-define at build time.
/// Values are baked into the binary — no runtime file needed.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const powerSyncUrl = String.fromEnvironment('POWERSYNC_URL');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      powerSyncUrl.isNotEmpty;
}
