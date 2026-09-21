package com.riccardopinato.batteryguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            BatteryGuardWidgetProvider.ACTION_TOGGLE_MONITORING -> {
                MonitoringPreferences.toggleEnabled(context)
                MonitoringService.sync(context)
                QuickSettingsTileService.requestRefresh(context)
            }

            BatteryGuardWidgetProvider.ACTION_CYCLE_TARGET -> {
                MonitoringPreferences.cycleTargetLevel(context)
            }

            BatteryGuardWidgetProvider.ACTION_REFRESH -> {
                // Reading the latest sticky battery broadcast is enough.
            }

            else -> return
        }

        BatteryGuardWidgetProvider.updateAll(context, force = true)
    }
}
