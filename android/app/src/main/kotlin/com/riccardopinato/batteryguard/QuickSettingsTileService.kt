package com.riccardopinato.batteryguard

import android.content.ComponentName
import android.content.Context
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class QuickSettingsTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        renderState()
    }

    override fun onClick() {
        super.onClick()
        val enabled = MonitoringPreferences.toggleEnabled(this)
        MonitoringService.sync(this)
        BatteryGuardWidgetProvider.updateAll(this, force = true)
        renderState(enabled)
    }

    private fun renderState(
        enabled: Boolean = MonitoringPreferences.get(this).enabled,
    ) {
        qsTile?.apply {
            state = if (enabled) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            label = "Battery Guard"
            contentDescription = if (enabled) {
                "Battery Guard attivo"
            } else {
                "Battery Guard disattivato"
            }
            updateTile()
        }
    }

    companion object {
        fun requestRefresh(context: Context) {
            try {
                requestListeningState(
                    context,
                    ComponentName(context, QuickSettingsTileService::class.java),
                )
            } catch (_: Throwable) {
                // Some OEMs can ignore refresh requests while the panel is closed.
            }
        }
    }
}
