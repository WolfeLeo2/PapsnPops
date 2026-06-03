import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final supabase = Supabase.instance.client;
  final res = await supabase
      .from('products')
      .select()
      .ilike('name', '%Jameson%');

  print('--- PRODUCTS IN SUPABASE ---');
  for (var r in res) {
    print('ID: ${r['id']}');
    print('Name: ${r['name']}');
    print('Base Unit: ${r['base_unit']}');
    print('Container Size: ${r['container_size']}');
    print('Container Name: ${r['container_name']}');
    print('---');
  }
}
