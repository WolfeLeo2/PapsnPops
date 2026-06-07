import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:paps_n_pops/features/auth/auth_provider.dart';
import 'package:paps_n_pops/features/notifications/notification_service.dart';
import 'dart:async';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}
class MockFlutterLocalNotificationsPlugin extends Mock implements FlutterLocalNotificationsPlugin {}
class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockAuth extends Auth {
  final User? _user;
  MockAuth(this._user);
  
  @override
  User? build() => _user;
}

class TestNotificationService extends NotificationService {
  TestNotificationService(
    super.ref, {
    super.firebaseMessaging,
    super.localNotificationsPlugin,
  });

  bool upsertCalled = false;
  String? upsertedUserId;
  String? upsertedToken;

  @override
  Future<void> upsertToken(String userId, String fcmToken, String deviceType) async {
    upsertCalled = true;
    upsertedUserId = userId;
    upsertedToken = fcmToken;
  }
}

void main() {
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFlutterLocalNotificationsPlugin mockLocalNotificationsPlugin;
  late StreamController<String> tokenRefreshController;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  });

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockLocalNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
    tokenRefreshController = StreamController<String>();

    // Setup Local Notifications mock
    when(() => mockLocalNotificationsPlugin.initialize(
          settings: any(named: 'settings'),
        )).thenAnswer((_) async => true);

    // Setup Firebase mock
    final mockSettings = MockNotificationSettings();
    when(() => mockSettings.authorizationStatus).thenReturn(AuthorizationStatus.authorized);
    
    when(() => mockFirebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )).thenAnswer((_) async => mockSettings);

    when(() => mockFirebaseMessaging.getToken())
        .thenAnswer((_) async => 'test_fcm_token');
        
    when(() => mockFirebaseMessaging.onTokenRefresh)
        .thenAnswer((_) => tokenRefreshController.stream);
  });

  tearDown(() {
    tokenRefreshController.close();
  });

  Ref _getRealRef(ProviderContainer container) {
    late Ref ref;
    container.listen(
      Provider((r) {
        ref = r;
        return 1;
      }),
      (_, __) {},
      fireImmediately: true,
    );
    return ref;
  }

  test('NotificationService initializes and syncs token for owner', () async {
    // Mock user as owner
    final mockUser = User(
      id: 'owner_123',
      appMetadata: const {},
      userMetadata: const {'role': 'owner'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => MockAuth(mockUser)),
      ],
    );

    final ref = _getRealRef(container);

    final service = TestNotificationService(
      ref,
      firebaseMessaging: mockFirebaseMessaging,
      localNotificationsPlugin: mockLocalNotificationsPlugin,
    );

    // Allow async init to complete
    await Future.delayed(Duration.zero);

    verify(() => mockLocalNotificationsPlugin.initialize(
          settings: any(named: 'settings'),
        )).called(1);
    verify(() => mockFirebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )).called(1);
    verify(() => mockFirebaseMessaging.getToken()).called(1);

    expect(service.upsertCalled, isTrue);
    expect(service.upsertedUserId, 'owner_123');
    expect(service.upsertedToken, 'test_fcm_token');
  });

  test('NotificationService does not sync token for non-owner', () async {
    // Mock user as cashier
    final mockUser = User(
      id: 'cashier_123',
      appMetadata: const {},
      userMetadata: const {'role': 'cashier'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => MockAuth(mockUser)),
      ],
    );

    final ref = _getRealRef(container);

    final service = TestNotificationService(
      ref,
      firebaseMessaging: mockFirebaseMessaging,
      localNotificationsPlugin: mockLocalNotificationsPlugin,
    );

    // Allow async init to complete
    await Future.delayed(Duration.zero);

    expect(service.upsertCalled, isFalse);
  });
}
