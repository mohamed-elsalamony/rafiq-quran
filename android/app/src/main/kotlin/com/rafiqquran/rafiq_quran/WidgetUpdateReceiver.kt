package com.rafiqquran.rafiq_quran

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetHelper.updateAllWidgets(context)
    }
}
