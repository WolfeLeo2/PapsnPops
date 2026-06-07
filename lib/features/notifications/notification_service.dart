import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  return service;
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  NotificationService(
    this._ref, {
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin() {
    _init();
  }

  Future<void> _init() async {
    // 1. Initialize Local Notifications for foreground messages
    const androidInitSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    await _localNotificationsPlugin.initialize(settings: initSettings);

    // 2. Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 3. Listen for token updates
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _syncTokenToSupabase(token);
      });

      // 4. Get initial token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _syncTokenToSupabase(token);
      }

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    }
    
    // Listen to auth changes so we sync token on login
    _ref.listen(authProvider, (previous, next) async {
      if (next != null && next.userMetadata?['role'] == 'owner') {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          _syncTokenToSupabase(token);
        }
      }
    });
  }

  Future<void> _syncTokenToSupabase(String fcmToken) async {
    final user = _ref.read(authProvider);
    // Only sync if the user is an owner
    if (user == null || user.userMetadata?['role'] != 'owner') return;

    try {
      final deviceType = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web';
      
      await upsertToken(user.id, fcmToken, deviceType);
    } catch (e) {
      print('Error syncing FCM token: $e');
    }
  }

  @visibleForTesting
  Future<void> upsertToken(String userId, String fcmToken, String deviceType) async {
    await Supabase.instance.client.from('user_devices').upsert({
      'user_id': userId,
      'fcm_token': fcmToken,
      'device_type': deviceType,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'fcm_token');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'paps_n_pops_alerts',
      'PAPs n POPs Alerts',
      channelDescription: 'Important business alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }
}

// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We don't need to do anything here because Android natively shows 
  // background notifications automatically if they contain a "notification" payload.
}

// Helper to initialize background handler before runApp
void setupFirebaseBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
