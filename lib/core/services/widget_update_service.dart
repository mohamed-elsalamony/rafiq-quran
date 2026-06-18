import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:adhan/adhan.dart';
import 'prayer_service.dart';

class WidgetUpdateService {
  static const String androidWidgetSmall = 'com.rafiqquran.rafiq_quran.WidgetSmallProvider';
  static const String androidWidgetMedium = 'com.rafiqquran.rafiq_quran.WidgetMediumProvider';
  static const String androidWidgetLarge = 'com.rafiqquran.rafiq_quran.WidgetLargeProvider';
  static const String iOSWidget = 'RunnerWidget';

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static Future<void> updateWidget({
    required Coordinates coordinates,
    required CalculationMethod method,
    String? cityName,
    String? dailyAyah,
    String? dailyHadith,
  }) async {
    try {
      // Store App Group name for iOS sharing
      await HomeWidget.setAppGroupId('group.com.rafiqquran.rafiq_quran');

      // Calculate today's times for direct fallback keys
      final today = DateTime.now();
      final todayTimes =
          PrayerService.getPrayerTimes(coordinates, method, date: today);

      await HomeWidget.saveWidgetData<String>(
          'fajr_time', _formatTime(todayTimes.fajr.toLocal()));
      await HomeWidget.saveWidgetData<String>(
          'dhuhr_time', _formatTime(todayTimes.dhuhr.toLocal()));
      await HomeWidget.saveWidgetData<String>(
          'asr_time', _formatTime(todayTimes.asr.toLocal()));
      await HomeWidget.saveWidgetData<String>(
          'maghrib_time', _formatTime(todayTimes.maghrib.toLocal()));
      await HomeWidget.saveWidgetData<String>(
          'isha_time', _formatTime(todayTimes.isha.toLocal()));

      // Calculate and save times for the next 7 days indexed by date (yyyy-MM-dd)
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final dateKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final dayTimes =
            PrayerService.getPrayerTimes(coordinates, method, date: date);

        final timesStr = "${_formatTime(dayTimes.fajr.toLocal())},"
            "${_formatTime(dayTimes.dhuhr.toLocal())},"
            "${_formatTime(dayTimes.asr.toLocal())},"
            "${_formatTime(dayTimes.maghrib.toLocal())},"
            "${_formatTime(dayTimes.isha.toLocal())}";
        await HomeWidget.saveWidgetData<String>(
            'prayer_times_$dateKey', timesStr);
      }

      if (cityName != null) {
        await HomeWidget.saveWidgetData<String>('city_name', cityName);
      }

      if (dailyAyah != null) {
        await HomeWidget.saveWidgetData<String>('daily_ayah', dailyAyah);
      }

      if (dailyHadith != null) {
        await HomeWidget.saveWidgetData<String>('daily_hadith', dailyHadith);
      }

      // Trigger update for Small Widget
      await HomeWidget.updateWidget(
        name: androidWidgetSmall,
        androidName: androidWidgetSmall,
        iOSName: iOSWidget,
      );

      // Trigger update for Medium Widget
      await HomeWidget.updateWidget(
        name: androidWidgetMedium,
        androidName: androidWidgetMedium,
        iOSName: iOSWidget,
      );

      // Trigger update for Large Widget
      await HomeWidget.updateWidget(
        name: androidWidgetLarge,
        androidName: androidWidgetLarge,
        iOSName: iOSWidget,
      );
    } catch (e) {
      debugPrint("Error updating widget data: $e");
    }
  }
}
