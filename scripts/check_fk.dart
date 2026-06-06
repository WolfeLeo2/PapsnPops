import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final supabase = Supabase.instance.client;

  try {
    print('Trying to get open_tabs...');
    final tabs = await supabase.from('open_tabs').select();
    print('Tabs: $tabs');
  } catch (e) {
    print('Failed to read tabs: $e');
  }

  try {
    print('Trying to get staff...');
    final staff = await supabase.from('staff').select();
    print('Staff: $staff');
  } catch (e) {
    print('Failed to read staff: $e');
  }
}
