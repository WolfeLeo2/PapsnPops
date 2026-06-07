import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/supabase/supabase_client.dart';
import 'data/powersync/powersync_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/notifications/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeSupabase();
  await initializePowerSync();
  await Firebase.initializeApp();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    setupFirebaseBackgroundHandler();
  }
  runApp(const ProviderScope(child: PapsnPopsApp()));
}
