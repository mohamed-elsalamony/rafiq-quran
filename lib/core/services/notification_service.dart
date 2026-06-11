import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      debugPrint("Web Notification Service Initialized");
      _initialized = true;
      return;
    }

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      final String localName = 'Asia/Riyadh'; // Fallback timezone
      try {
        // You can use flutter_timezone package to get local timezone name if needed,
        // but setting Riyadh or Cairo as fallback is safe, or we can use local timezone offset.
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        debugPrint("Could not set timezone location, using Riyadh as default.");
      }

      // 2. Initialize settings for Android & iOS
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification Clicked: ${details.payload}");
        },
      );

      // Create high importance notification channel for Android 8.0+
      if (Platform.isAndroid) {
        final AndroidNotificationChannel channel = const AndroidNotificationChannel(
          'prayer_channel_id',
          'تنبيهات الأذان والصلوات',
          description: 'تنبهات مواقيت الصلاة والأذان المكتوب',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.createNotificationChannel(channel);
          await androidImplementation.requestNotificationsPermission();
          try {
            await androidImplementation.requestExactAlarmsPermission();
          } catch (e) {
            debugPrint("Error requesting exact alarms permission: $e");
          }
        }
      }

      debugPrint("Notification Service Initialized Successfully");
      _initialized = true;
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
    }
  }

  // --- Schedule generic local notification ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'prayer_channel_id',
        'تنبيهات الأذان والصلوات',
        channelDescription: 'تنبهات مواقيت الصلاة والأذان المكتوب',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("Scheduled exact notification '$title' (ID: $id) for $tzDateTime");
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  // --- Schedule all weekly prayer alarms based on settings ---
  Future<void> schedulePrayerAlarms({
    required double latitude,
    required double longitude,
    required Map<String, bool> enabledAlarms,
    required CalculationMethod method,
    bool preAlarmsEnabled = false,
    int preAlarmMinutes = 15,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      // Cancel previous scheduled notifications first to prevent duplicates
      await _notificationsPlugin.cancelAll();

      final coords = Coordinates(latitude, longitude);
      final now = DateTime.now();

      // Curated list of prayer-related verses to show in pre-alarms
      final List<String> prayerVerses = [
        "﴿ إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا ﴾ (النساء - 103)",
        "﴿ وَأَقِمِ الصَّلَاةَ لِدُلُوكِ الشَّمْسِ إِلَىٰ غَسَقِ اللَّيْلِ ﴾ (الإسراء - 78)",
        "﴿ حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ وَقُومُوا لِلَّهِ قَانِتِينَ ﴾ (البقرة - 238)",
        "﴿ وَأَقِمِ الصَّلَاةَ إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنْكَرِ ﴾ (العنكبوت - 45)",
        "﴿ يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ﴾ (البقرة - 153)",
        "﴿ وَأْمُرْ أَهْلَكَ بِالصَّلَاةِ وَاصْطَبِرْ عَلَيْهَا ﴾ (طه - 132)",
        "﴿ وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَارْكَعُوا مَعَ الرَّاكِعِينَ ﴾ (البقرة - 43)"
      ];

      // Schedule alarms for the next 7 days
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = now.add(Duration(days: dayOffset));
        final DateComponents dateComponents = DateComponents.from(date);
        
        final params = method.getParameters();
        params.madhab = Madhab.shafi;
        
        final times = PrayerTimes(coords, dateComponents, params);

        final List<Map<String, dynamic>> prayers = [
          {'name': 'Fajr', 'label': 'الفجر', 'time': times.fajr},
          {'name': 'Dhuhr', 'label': 'الظهر', 'time': times.dhuhr},
          {'name': 'Asr', 'label': 'العصر', 'time': times.asr},
          {'name': 'Maghrib', 'label': 'المغرب', 'time': times.maghrib},
          {'name': 'Isha', 'label': 'العشاء', 'time': times.isha},
        ];

        for (int i = 0; i < prayers.length; i++) {
          final prayer = prayers[i];
          final String name = prayer['name'];
          final String label = prayer['label'];
          final DateTime prayerTime = prayer['time'];

          // Skip if alarm is disabled
          if (enabledAlarms[name] != true) {
            continue;
          }

          // 1. Exact Prayer Time Notification
          if (prayerTime.isAfter(now)) {
            final int notificationId = (dayOffset * 10) + i + 1000;
            await scheduleNotification(
              id: notificationId,
              title: 'حان الآن موعد صلاة $label 🕌',
              body: 'الله أكبر، الله أكبر. حان الآن موعد الأذان لصلاة $label حسب توقيتك المحلي. أقم صلاتك تسعد حياتك 🤲',
              scheduledDate: prayerTime,
            );
          }

          // 2. Pre-Prayer Preparation Notification (إشعار الاستعداد قبل الصلاة)
          if (preAlarmsEnabled) {
            final DateTime preAlarmTime = prayerTime.subtract(Duration(minutes: preAlarmMinutes));
            if (preAlarmTime.isAfter(now)) {
              final int preNotificationId = (dayOffset * 10) + i + 2000;
              final String verse = prayerVerses[i % prayerVerses.length];
              
              await scheduleNotification(
                id: preNotificationId,
                title: 'تأهب لصلاة $label بعد $preAlarmMinutes دقيقة ⏱️',
                body: 'استعد للوقوف بين يدي الله سبحانه وتعالى لصلاة $label قريباً.\n$verse',
                scheduledDate: preAlarmTime,
              );
            }
          }
        }
      }
      debugPrint("Prayer alarms scheduled for the next 7 days.");
    } catch (e) {
      debugPrint("Error scheduling prayer alarms: $e");
    }
  }

  // --- Show instant alert inside the app ---
  void showInstantAlert(BuildContext context, String title, String body) {
    if (!context.mounted) return;
    
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
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
