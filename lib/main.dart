import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/supabase/supabase_client.dart';
import 'data/powersync/powersync_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/notifications/notification_service.dart';
import 'app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  await initializePowerSync();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
    await Firebase.initializeApp();
    setupFirebaseBackgroundHandler();
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://6cad5425183d8785a8d63f9c2b332a6d@o4511593304358912.ingest.de.sentry.io/4511593324281936';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const ProviderScope(child: PapsnPopsApp()))),
  );
}
