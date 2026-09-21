package com.riccardopinato.batteryguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PowerEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (
            intent.action != Intent.ACTION_POWER_CONNECTED &&
            intent.action != Intent.ACTION_POWER_DISCONNECTED
        ) {
            return
        }

        if (MonitoringPreferences.get(context).enabled) {
            MonitoringService.sync(context)
        }
        BatteryGuardWidgetProvider.updateAll(context, force = true)
    }
}
