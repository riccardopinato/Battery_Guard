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

            ACTION_DISABLE_MONITORING -> {
                MonitoringPreferences.setEnabled(context, false)
                MonitoringService.sync(context)
                QuickSettingsTileService.requestRefresh(context)
            }

            ACTION_SET_TARGET_80 -> {
                MonitoringPreferences.setTargetLevel(context, 80)
            }

            else -> return
        }

        BatteryGuardWidgetProvider.updateAll(context, force = true)
    }

    companion object {
        const val ACTION_DISABLE_MONITORING =
            "com.riccardopinato.batteryguard.action.DISABLE_MONITORING"
        const val ACTION_SET_TARGET_80 =
            "com.riccardopinato.batteryguard.action.SET_TARGET_80"
    }
}
