import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:adhan/adhan.dart';
import 'periodic_notification_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    // On non-mobile platforms (desktop, etc.) treat as enabled
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final bool? enabled =
              await androidImplementation.areNotificationsEnabled();
          return enabled ?? true;
        }
        return true;
      } else if (Platform.isIOS) {
        final iosImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation != null) {
          final bool? granted = await iosImplementation.requestPermissions(
            alert: false,
            badge: false,
            sound: false,
          );
          return granted ?? true;
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error checking notifications status: $e');
    }
    return true; // Default to true to avoid false blocking
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      bool granted = false;
      if (Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final bool? result =
              await androidImplementation.requestNotificationsPermission();
          granted = result ?? false;
          try {
            await androidImplementation.requestExactAlarmsPermission();
          } catch (e) {
            debugPrint('Error requesting exact alarms permission: $e');
          }
        }
      } else if (Platform.isIOS) {
        final iosImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation != null) {
          final bool? result = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          granted = result ?? false;
        }
      }
      // Re-initialize the service if not already done after permission grant
      if (granted && !_initialized) {
        await init();
      }
      return granted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
    return false;
  }

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('Desktop/Web/Test: Notification Service Mock Initialized');
      _initialized = true;
      return;
    }

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      try {
        final String timeZoneName =
            (await FlutterTimezone.getLocalTimezone()).identifier;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Set local timezone to: $timeZoneName');
      } catch (e) {
        debugPrint('Could not set local timezone: $e. Using fallback Riyadh.');
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
        } catch (_) {
          try {
            tz.setLocalLocation(tz.UTC);
            debugPrint('Fallback to UTC timezone.');
          } catch (inner) {
            debugPrint('Failed to set even UTC timezone: $inner');
          }
        }
      }

      // 2. Initialize settings for Android & iOS
      // Use @drawable/ic_notification (white icon) — required for Android 5+
      // Colored icons appear as white squares in status bar on Android 5+
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification Clicked: ${details.payload}');
          final payload = details.payload;
          if (payload != null && payload.isNotEmpty) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
              arguments: payload,
            );
          }
        },
      );

      // Create high importance notification channels for Android 8.0+
      if (Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          // Channel 1: Prayer alarms
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'prayer_channel_id',
              'تنبيهات الأذان والصلوات',
              description: 'تنبهات مواقيت الصلاة والأذان المكتوب',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 2: Daily Reminders
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'daily_reminder_channel_id',
              'التذكير اليومي بالورد والأذكار',
              description: 'تنبيه يومي لقراءة الورد القرآني وأذكار الصباح والمساء',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 3: Smart Reminders
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'smart_reminders_channel_id',
              'التذكيرات الذكية اليومية',
              description: 'تنبيهات مخصصة لمرافقتك طوال اليوم من الاستيقاظ إلى النوم',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );

          // Channel 4: Periodic reminders (WorkManager)
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              'periodic_channel_id',
              'التذكير الدوري بالذكر والآية',
              description: 'تنبيهات الذكر والآيات والحديث الدوري التلقائي',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
            ),
          );
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
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint("Skipping scheduleNotification in desktop/test/web");
      return;
    }
    if (!_initialized) {
      throw Exception("خدمة الإشعارات ليست نشطة حالياً. يرجى تفعيلها أولاً.");
    }

    try {
      final tz.TZDateTime tzDateTime =
          tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint("Warning: Scheduled date $tzDateTime (ID: $id) is in the past. Skipping.");
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'prayer_channel_id',
        'تنبيهات الأذان والصلوات',
        channelDescription: 'تنبهات مواقيت الصلاة والأذان المكتوب',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@drawable/ic_notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint(
            "Scheduled exact notification '$title' (ID: $id) for $tzDateTime");
      } catch (e) {
        debugPrint(
            "Failed to schedule exact notification, retrying with inexact fallback: $e");
        try {
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tzDateTime,
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          debugPrint(
              "Scheduled inexact notification '$title' (ID: $id) for $tzDateTime");
        } catch (innerErr) {
          debugPrint("Failed to schedule inexact fallback notification (ID: $id): $innerErr");
        }
      }
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }


  // --- Schedule/Cancel Daily Reminder Notification ---
  Future<void> scheduleDailyReminder({required bool enabled}) async {
    if (kIsWeb || !_initialized || Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS)) return;

    final int dailyReminderId = 999;

    if (!enabled) {
      await _notificationsPlugin.cancel(dailyReminderId);
      debugPrint(
          "Cancelled daily reminder notification (ID: $dailyReminderId)");
      return;
    }

    try {
      // Cancel first to avoid duplicates
      await _notificationsPlugin.cancel(dailyReminderId);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // 9:00 AM
        0,
      );

      // If 9:00 AM has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'daily_reminder_channel_id',
        'التذكير اليومي بالورد والأذكار',
        channelDescription:
            'تنبيه يومي لقراءة الورد القرآني وأذكار الصباح والمساء',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@drawable/ic_notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          '📖 الورد اليومي والأذكار',
          'لا تنسَ قراءة وردك اليومي وأذكار الصباح والمساء لتنعم بذكر الله 📿',
          scheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint("Scheduled daily reminder (exact) at $scheduledTime");
      } catch (e) {
        debugPrint(
            "Failed to schedule daily reminder (exact), retrying inexact: $e");
        await _notificationsPlugin.zonedSchedule(
          dailyReminderId,
          '📖 الورد اليومي والأذكار',
          'لا تنسَ قراءة وردك اليومي وأذكار الصباح والمساء لتنعم بذكر الله 📿',
          scheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint("Scheduled daily reminder (inexact) at $scheduledTime");
      }
    } catch (e) {
      debugPrint("Error scheduling daily reminder: $e");
    }
  }

  // --- Cancel only prayer alarms ---
  Future<void> _cancelPrayerAlarms() async {
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      for (int i = 0; i < 5; i++) {
        try {
          await _notificationsPlugin.cancel((dayOffset * 10) + i + 1000);
          await _notificationsPlugin.cancel((dayOffset * 10) + i + 2000);
        } catch (_) {}
      }
    }
  }

  // --- Cancel only smart daily reminders ---
  Future<void> _cancelSmartReminders() async {
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      try {
        await _notificationsPlugin.cancel((dayOffset * 10) + 3000);
        await _notificationsPlugin.cancel((dayOffset * 10) + 3010);
        await _notificationsPlugin.cancel((dayOffset * 10) + 3020);
        await _notificationsPlugin.cancel((dayOffset * 10) + 3030);
      } catch (_) {}
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
    if (kIsWeb || !_initialized || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      // Cancel previous scheduled prayer alarms to prevent duplicates
      await _cancelPrayerAlarms();

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
              body:
                  'الله أكبر، الله أكبر. حان الآن موعد الأذان لصلاة $label حسب توقيتك المحلي. أقم صلاتك تسعد حياتك 🤲',
              scheduledDate: prayerTime,
            );
          }

          // 2. Pre-Prayer Preparation Notification (إشعار الاستعداد قبل الصلاة)
          if (preAlarmsEnabled) {
            final DateTime preAlarmTime =
                prayerTime.subtract(Duration(minutes: preAlarmMinutes));
            if (preAlarmTime.isAfter(now)) {
              final int preNotificationId = (dayOffset * 10) + i + 2000;
              final String verse = prayerVerses[i % prayerVerses.length];

              await scheduleNotification(
                id: preNotificationId,
                title: 'تأهب لصلاة $label بعد $preAlarmMinutes دقيقة ⏱️',
                body:
                    'استعد للوقوف بين يدي الله سبحانه وتعالى لصلاة $label قريباً.\n$verse',
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

  // --- Schedule all smart daily reminders for the next 7 days ---
  Future<void> scheduleSmartReminders({
    required int wakeUpHour,
    required int wakeUpMinute,
    required int returnHour,
    required int returnMinute,
    required int sleepHour,
    required int sleepMinute,
    required int wakeUpDelayMins,
    required bool wakeUpRem1Enabled,
    required bool wakeUpRem2Enabled,
    required bool returnRemEnabled,
    required bool sleepRemEnabled,
    required String contentType,
  }) async {
    if (kIsWeb || !_initialized || Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      // 1. Cancel existing smart reminders first
      await _cancelSmartReminders();

      final random = Random();
      final now = tz.TZDateTime.now(tz.local);

      // Helper function to pick random content
      Map<String, String> getRandomContent(String type) {
        String selectedType = type;
        if (type == 'all') {
          final roll = random.nextInt(3);
          if (roll == 0)
            selectedType = 'verse';
          else if (roll == 1)
            selectedType = 'dhikr';
          else
            selectedType = 'hadith';
        }

        if (selectedType == 'verse') {
          final index =
              random.nextInt(PeriodicNotificationHelper.verses.length);
          return {
            'title': '📖 آية قرآنية للتأمل',
            'body': PeriodicNotificationHelper.verses[index],
            'payload': 'quran'
          };
        } else if (selectedType == 'dhikr') {
          final index =
              random.nextInt(PeriodicNotificationHelper.adhkar.length);
          return {
            'title': '📿 ذكر اليوم',
            'body': PeriodicNotificationHelper.adhkar[index],
            'payload': 'adhkar'
          };
        } else {
          final index =
              random.nextInt(PeriodicNotificationHelper.hadiths.length);
          return {
            'title': '📚 من الهدي النبوي',
            'body': PeriodicNotificationHelper.hadiths[index],
            'payload': 'home'
          };
        }
      }

      // Schedule alarms for the next 7 days
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        // Base dates
        final wakeUpBase = tz.TZDateTime(tz.local, now.year, now.month, now.day,
                wakeUpHour, wakeUpMinute)
            .add(Duration(days: dayOffset));
        final returnBase = tz.TZDateTime(tz.local, now.year, now.month, now.day,
                returnHour, returnMinute)
            .add(Duration(days: dayOffset));
        final sleepBase = tz.TZDateTime(
                tz.local, now.year, now.month, now.day, sleepHour, sleepMinute)
            .add(Duration(days: dayOffset));

        // 1. Wake Up - Reminder 1: X minutes after wake up (delay duration)
        if (wakeUpRem1Enabled) {
          final targetTime = wakeUpBase.add(Duration(minutes: wakeUpDelayMins));
          if (targetTime.isAfter(now)) {
            final content = getRandomContent(contentType);
            await scheduleNotificationDirect(
              id: (dayOffset * 10) + 3000,
              title: content['title'] ?? 'صباح الخير والبركة 🌅',
              body: content['body'] ?? 'اذكر الله يذكرك ويبارك في يومك.',
              scheduledDate: targetTime,
              payload: content['payload'] ?? 'home',
            );
          }
        }

        // 2. Wake Up - Reminder 2: 1 hour after wake up (Quran daily portion reminder)
        if (wakeUpRem2Enabled) {
          final targetTime = wakeUpBase.add(const Duration(hours: 1));
          if (targetTime.isAfter(now)) {
            await scheduleNotificationDirect(
              id: (dayOffset * 10) + 3010,
              title: '📖 وردك القرآني اليومي',
              body:
                  'لا تنسَ قراءة وردك اليومي من كتاب الله، رتب وقتك لتنعم ببركة القرآن في يومك 🌿',
              scheduledDate: targetTime,
              payload: 'quran',
            );
          }
        }

        // 3. Return from Work: reminder of portion, evening dhikr, or blessings campaign
        if (returnRemEnabled) {
          final targetTime = returnBase;
          if (targetTime.isAfter(now)) {
            // Pick a message topic randomly
            final topic = random.nextInt(3);
            String title = '🏢 عوداً حميداً من العمل';
            String body =
                'تقبل الله طاعتك. لا تنسَ قراءة أذكار المساء لتكون في حفظ الله 📿';
            String payload = 'adhkar';

            if (topic == 0) {
              title = '📖 هل أكملت وردك اليوم؟';
              body =
                  'خصص دقائق من وقتك الآن لإتمام وردك اليومي من القرآن الكريم وتدبر آياته 🤲';
              payload = 'quran';
            } else if (topic == 1) {
              title = 'ﷻ الصلاة على النبي ﷺ';
              body =
                  'شارك الآن مع آلاف المسلمين في مبادرة مليونية الصلاة على الرسول ﷺ 🕌';
              payload =
                  'home'; // HomeScreen contains the blessings campaign card
            }

            await scheduleNotificationDirect(
              id: (dayOffset * 10) + 3020,
              title: title,
              body: body,
              scheduledDate: targetTime,
              payload: payload,
            );
          }
        }

        // 4. Bedtime: 30 minutes before sleep
        if (sleepRemEnabled) {
          final targetTime = sleepBase.subtract(const Duration(minutes: 30));
          if (targetTime.isAfter(now)) {
            // Get random content
            final content = getRandomContent(contentType);
            String body =
                'استعد للنوم بقراءة أذكار النوم وسورة الملك. طابت ليلتك في حفظ الرحمن 🌙\n${content['body']}';

            await scheduleNotificationDirect(
              id: (dayOffset * 10) + 3030,
              title: '🌙 أذكار النوم والاستعداد',
              body: body,
              scheduledDate: targetTime,
              payload: 'adhkar',
            );
          }
        }
      }
      debugPrint("Smart daily reminders scheduled for the next 7 days.");
    } catch (e) {
      debugPrint("Error scheduling smart reminders: $e");
    }
  }

  // --- Internal helper to schedule directly with a specific payload ---
  Future<void> scheduleNotificationDirect({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    if (kIsWeb || !_initialized || Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final tz.TZDateTime tzDateTime = scheduledDate is tz.TZDateTime
          ? scheduledDate as tz.TZDateTime
          : tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint("Warning: Direct scheduled date $tzDateTime (ID: $id) is in the past. Skipping.");
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'smart_reminders_channel_id',
        'التذكيرات الذكية اليومية',
        channelDescription:
            'تنبيهات مخصصة لمرافقتك طوال اليوم من الاستيقاظ إلى النوم',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@drawable/ic_notification',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );
        debugPrint("Scheduled direct exact notification '$title' (ID: $id) for $tzDateTime");
      } catch (e) {
        debugPrint("Failed to schedule direct exact notification, trying inexact fallback: $e");
        try {
          await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tzDateTime,
            platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
          debugPrint("Scheduled direct inexact notification '$title' (ID: $id) for $tzDateTime");
        } catch (innerErr) {
          debugPrint("Failed to schedule direct inexact fallback (ID: $id): $innerErr");
        }
      }
    } catch (e) {
      debugPrint("Error in scheduleNotificationDirect: $e");
    }
  }

  // --- Show instant system notification immediately ---
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST') ||
        (!Platform.isAndroid && !Platform.isIOS)) return;
    if (!_initialized) {
      await init();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_channel_id',
      'تنبيهات الأذان والصلوات',
      channelDescription: 'تنبهات مواقيت الصلاة والأذان المكتوب',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      debugPrint("Instant notification presented successfully.");
    } catch (e) {
      debugPrint("Error displaying instant notification: $e");
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
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
