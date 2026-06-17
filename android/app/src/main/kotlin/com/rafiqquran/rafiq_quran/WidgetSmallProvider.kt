package com.rafiqquran.rafiq_quran

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetSmallProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        WidgetHelper.updateAllWidgets(context)
        WidgetHelper.startPeriodicUpdates(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetHelper.startPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetHelper.stopPeriodicUpdatesIfNoWidgets(context)
    }
}
