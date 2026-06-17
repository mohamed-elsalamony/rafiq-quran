import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq_quran/core/services/notification_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_timezone');
  const MethodChannel notificationsChannel = MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getLocalTimezone') {
        return 'Asia/Riyadh';
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  test('NotificationService initialization and scheduling test', () async {
    final service = NotificationService();
    
    await service.init();
    
    // Schedule a test notification
    final testTime = DateTime.now().add(const Duration(seconds: 5));
    await service.scheduleNotification(
      id: 777,
      title: 'Test Title',
      body: 'Test Body',
      scheduledDate: testTime,
    );
    
    // Verify daily reminder scheduling executes without throwing
    await service.scheduleDailyReminder(enabled: true);
    await service.scheduleDailyReminder(enabled: false);

    // Verify smart daily reminders scheduling executes without throwing
    await service.scheduleSmartReminders(
      wakeUpHour: 7,
      wakeUpMinute: 30,
      returnHour: 16,
      returnMinute: 45,
      sleepHour: 22,
      sleepMinute: 15,
      wakeUpDelayMins: 30,
      wakeUpRem1Enabled: true,
      wakeUpRem2Enabled: true,
      returnRemEnabled: true,
      sleepRemEnabled: true,
      contentType: 'verse',
    );
  });
}
