import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // FCM push notifications only work on Android/iOS, skip on web
    if (kIsWeb) {
      debugPrint('FCM: Skipping on web platform');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS + Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Notification permission denied');
        return;
      }

      // Subscribe to all_users topic
      try {
        await messaging.subscribeToTopic('all');
        debugPrint('FCM: Subscribed to all_users topic');
      } catch (e) {
        debugPrint('FCM: Topic subscription failed: $e');
      }

      // Get FCM token
      try {
        final token = await messaging.getToken();
        debugPrint('FCM Token: $token');
      } catch (e) {
        debugPrint('FCM: Failed to get token: $e');
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a notification (when terminated)
      try {
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      } catch (e) {
        debugPrint('FCM: Failed to get initial message: $e');
      }

      _initialized = true;
      debugPrint('FCM: Initialized successfully');
    } catch (e) {
      debugPrint('FCM: Init failed - $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM opened: ${message.notification?.title}');
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('FCM background: ${message.notification?.title}');
  } catch (e) {
    debugPrint('FCM background init error: $e');
  }
}
