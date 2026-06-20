import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you do not initialize Firebase in the background handler, some Firebase services might fail.
  // But since we are keeping it simple, we just log the message.
  debugPrint("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    debugPrint("Background Notification Title: ${message.notification!.title}");
    debugPrint("Background Notification Body: ${message.notification!.body}");
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;
  String? _fcmToken;

  bool get isInitialized => _initialized;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Check if Firebase is initialized first
      if (Firebase.apps.isEmpty) {
        debugPrint("Firebase has not been initialized. Skipping FCM initialization.");
        return;
      }

      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (for iOS and Android 13+)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM User granted permission: ${settings.authorizationStatus}');

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Listen to foreground messages and show local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          
          final notification = message.notification!;
          // Use our local notification service to display the notification
          NotificationService().showInstantNotification(
            id: notification.hashCode,
            title: notification.title ?? 'تنبيه جديد',
            body: notification.body ?? '',
            payload: 'fcm_payload',
          );
        }
      });

      // 4. Retrieve FCM Token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');
      } catch (e) {
        debugPrint('Error getting FCM Token: $e');
      }

      // 5. Setup token refresh listener
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token Refreshed: $_fcmToken');
      });

      _initialized = true;
    } catch (e) {
      debugPrint("Error initializing FCM: $e");
    }
  }
}
