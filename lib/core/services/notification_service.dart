import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      // محاكاة إشعار الويب
      debugPrint("Web Notification Service Initialized");
      _initialized = true;
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // يمكن لاحقاً تهيئة flutter_local_notifications الفعلي هنا للهواتف
        debugPrint("Mobile Notification Service Initialized (Stub)");
      } else {
        debugPrint("Desktop Notification Service Initialized (Stub)");
      }
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
    }

    _initialized = true;
  }

  // جدولة إشعار
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    debugPrint("Scheduled notification '$title' for $scheduledDate");
    // محاكاة الإشعار المجدول في المنصات غير المتوافقة
  }

  // إظهار إشعار فوري (سواء في التطبيق أو عبر النظام)
  void showInstantAlert(BuildContext context, String title, String body) {
    if (!context.mounted) return;
    
    // إظهار تنبيه مخصص وجميل داخل التطبيق
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: kIsWeb ? FontWeight.bold : FontWeight.w700, fontFamily: 'Outfit'),
                  ),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
