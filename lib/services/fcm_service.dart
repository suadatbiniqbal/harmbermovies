import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

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

      // Subscribe to all_users topic (not supported on web)
      try {
        await messaging.subscribeToTopic('all');
        debugPrint('FCM: Subscribed to all_users topic');
      } catch (_) {
        debugPrint('FCM: Topic subscription not supported on this platform');
      }

      // Get FCM token
      final token = await messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a notification (when terminated)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _initialized = true;
      debugPrint('FCM: Initialized successfully');
    } catch (e) {
      debugPrint('FCM: Init failed - $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    // Messages are automatically shown as notifications by the system
    // when the app is in the background. For foreground, they're handled here.
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM opened: ${message.notification?.title}');
    // Handle navigation based on notification data
    // e.g., navigate to a specific movie/show detail
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
