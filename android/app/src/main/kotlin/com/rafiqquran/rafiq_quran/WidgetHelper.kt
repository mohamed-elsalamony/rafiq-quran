package com.rafiqquran.rafiq_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.SystemClock
import android.widget.RemoteViews
import java.util.*

object WidgetHelper {
    private const val PREFS_NAME = "home_widget"

    fun updateAllWidgets(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val appWidgetManager = AppWidgetManager.getInstance(context)

        // 1. Calculate Next Prayer Info
        val nextPrayer = getNextPrayer(prefs)
        val prayerName = nextPrayer?.first ?: "--"
        val prayerTime = nextPrayer?.second ?: "--:--"
        val countdownStr = nextPrayer?.third ?: "--:--"

        // 2. Fetch today's times for large widget list
        val now = Calendar.getInstance()
        val fajr = getPrayerTimeForDate(prefs, now, 0, "fajr_time") ?: "--:--"
        val dhuhr = getPrayerTimeForDate(prefs, now, 1, "dhuhr_time") ?: "--:--"
        val asr = getPrayerTimeForDate(prefs, now, 2, "asr_time") ?: "--:--"
        val maghrib = getPrayerTimeForDate(prefs, now, 3, "maghrib_time") ?: "--:--"
        val isha = getPrayerTimeForDate(prefs, now, 4, "isha_time") ?: "--:--"

        // Fetch Ayah and Hadith
        val dailyAyah = prefs.getString("daily_ayah", "﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾") ?: ""
        val dailyHadith = prefs.getString("daily_hadith", "خيركم من تعلم القرآن وعلمه") ?: ""

        // 3. Update Small Widgets
        val smallWidget = ComponentName(context, WidgetSmallProvider::class.java)
        val smallViews = RemoteViews(context.packageName, R.layout.widget_small)
        smallViews.setTextViewText(R.id.widget_prayer_name, prayerName)
        smallViews.setTextViewText(R.id.widget_countdown, countdownStr)
        smallViews.setTextViewText(R.id.widget_prayer_time, "في $prayerTime")
        setupClickIntent(context, smallViews, R.id.widget_root)
        appWidgetManager.updateAppWidget(smallWidget, smallViews)

        // 4. Update Medium Widgets
        val mediumWidget = ComponentName(context, WidgetMediumProvider::class.java)
        val mediumViews = RemoteViews(context.packageName, R.layout.widget_medium)
        mediumViews.setTextViewText(R.id.widget_prayer_name, prayerName)
        mediumViews.setTextViewText(R.id.widget_countdown, countdownStr)
        mediumViews.setTextViewText(R.id.widget_prayer_time, "في $prayerTime")
        mediumViews.setTextViewText(R.id.widget_ayah, dailyAyah)
        setupClickIntent(context, mediumViews, R.id.widget_root)
        appWidgetManager.updateAppWidget(mediumWidget, mediumViews)

        // 5. Update Large Widgets
        val largeWidget = ComponentName(context, WidgetLargeProvider::class.java)
        val largeViews = RemoteViews(context.packageName, R.layout.widget_large)
        largeViews.setTextViewText(R.id.widget_prayer_name, prayerName)
        largeViews.setTextViewText(R.id.widget_countdown, countdownStr)
        largeViews.setTextViewText(R.id.widget_fajr_time, fajr)
        largeViews.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
        largeViews.setTextViewText(R.id.widget_asr_time, asr)
        largeViews.setTextViewText(R.id.widget_maghrib_time, maghrib)
        largeViews.setTextViewText(R.id.widget_isha_time, isha)
        largeViews.setTextViewText(R.id.widget_ayah, dailyAyah)
        largeViews.setTextViewText(R.id.widget_hadith, dailyHadith)
        setupClickIntent(context, largeViews, R.id.widget_root)
        appWidgetManager.updateAppWidget(largeWidget, largeViews)
    }

    private fun setupClickIntent(context: Context, views: RemoteViews, viewId: Int) {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(viewId, pendingIntent)
        }
    }

    private fun getPrayerTimeForDate(prefs: SharedPreferences, cal: Calendar, prayerIndex: Int, defaultKey: String): String? {
        val dateKey = String.format(Locale.US, "%d-%02d-%02d", cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH))
        val timesStr = prefs.getString("prayer_times_$dateKey", null)
        if (timesStr != null) {
            val times = timesStr.split(",")
            if (times.size == 5) {
                return times[prayerIndex].trim()
            }
        }
        return prefs.getString(defaultKey, null)
    }

    private fun getNextPrayer(prefs: SharedPreferences): Triple<String, String, String>? {
        val now = Calendar.getInstance()
        val prayers = listOf(
            Pair("الفجر", "fajr_time"),
            Pair("الظهر", "dhuhr_time"),
            Pair("العصر", "asr_time"),
            Pair("المغرب", "maghrib_time"),
            Pair("العشاء", "isha_time")
        )

        val list = ArrayList<Pair<String, Calendar>>()
        for (i in prayers.indices) {
            val p = prayers[i]
            // Try fetching time for today
            val todayCal = Calendar.getInstance()
            val timeStr = getPrayerTimeForDate(prefs, todayCal, i, p.second) ?: continue
            val parts = timeStr.split(":")
            if (parts.size >= 2) {
                try {
                    todayCal.set(Calendar.HOUR_OF_DAY, parts[0].trim().toInt())
                    todayCal.set(Calendar.MINUTE, parts[1].trim().toInt())
                    todayCal.set(Calendar.SECOND, 0)
                    todayCal.set(Calendar.MILLISECOND, 0)
                    
                    if (todayCal.before(now)) {
                        // If it has passed, load tomorrow's times for this prayer
                        val tomorrowCal = Calendar.getInstance()
                        tomorrowCal.add(Calendar.DAY_OF_YEAR, 1)
                        val tomorrowTimeStr = getPrayerTimeForDate(prefs, tomorrowCal, i, p.second) ?: timeStr
                        val tomorrowParts = tomorrowTimeStr.split(":")
                        if (tomorrowParts.size >= 2) {
                            tomorrowCal.set(Calendar.HOUR_OF_DAY, tomorrowParts[0].trim().toInt())
                            tomorrowCal.set(Calendar.MINUTE, tomorrowParts[1].trim().toInt())
                            tomorrowCal.set(Calendar.SECOND, 0)
                            tomorrowCal.set(Calendar.MILLISECOND, 0)
                            list.add(Pair(p.first, tomorrowCal))
                        }
                    } else {
                        list.add(Pair(p.first, todayCal))
                    }
                } catch (e: Exception) {
                    // Ignore parsing errors
                }
            }
        }

        if (list.isEmpty()) return null

        list.sortBy { it.second.timeInMillis }
        val next = list[0]

        val diffMs = next.second.timeInMillis - now.timeInMillis
        val diffMins = (diffMs / 1000 / 60)
        val hours = diffMins / 60
        val mins = diffMins % 60
        val countdownStr = String.format("%02d:%02d", hours, mins)

        val hourStr = String.format("%02d:%02d", next.second.get(Calendar.HOUR_OF_DAY), next.second.get(Calendar.MINUTE))

        return Triple(next.first, hourStr, countdownStr)
    }

    fun startPeriodicUpdates(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetUpdateReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            1001,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val interval = 60 * 1000L
        alarmManager.setRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + interval,
            interval,
            pendingIntent
        )
    }

    fun stopPeriodicUpdates(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetUpdateReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            1001,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    fun stopPeriodicUpdatesIfNoWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val smallIds = appWidgetManager.getAppWidgetIds(ComponentName(context, WidgetSmallProvider::class.java))
        val mediumIds = appWidgetManager.getAppWidgetIds(ComponentName(context, WidgetMediumProvider::class.java))
        val largeIds = appWidgetManager.getAppWidgetIds(ComponentName(context, WidgetLargeProvider::class.java))

        if (smallIds.isEmpty() && mediumIds.isEmpty() && largeIds.isEmpty()) {
            stopPeriodicUpdates(context)
        }
    }
}
