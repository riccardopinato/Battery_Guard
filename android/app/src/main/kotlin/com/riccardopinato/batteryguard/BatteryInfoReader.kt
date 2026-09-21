package com.riccardopinato.batteryguard

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.PowerManager
import kotlin.math.abs

object BatteryInfoReader {
    fun read(context: Context, sourceIntent: Intent? = null): Map<String, Any> {
        val batteryIntent = if (sourceIntent?.action == Intent.ACTION_BATTERY_CHANGED) {
            sourceIntent
        } else {
            context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        }

        if (batteryIntent == null) {
            return emptySnapshot()
        }

        val levelRaw = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, 100).coerceAtLeast(1)
        val level = if (levelRaw >= 0) ((levelRaw * 100f) / scale).toInt().coerceIn(0, 100) else 0
        val temperatureC = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0
        val voltageMv = batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0)
        val statusCode = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, BatteryManager.BATTERY_STATUS_UNKNOWN)
        val healthCode = batteryIntent.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN)
        val pluggedCode = batteryIntent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val technology = batteryIntent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY).orEmpty().ifBlank { "—" }
        val isCharging = statusCode == BatteryManager.BATTERY_STATUS_CHARGING ||
            statusCode == BatteryManager.BATTERY_STATUS_FULL
        val isPlugged = pluggedCode != 0

        val manager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val currentUa = try {
            manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } catch (_: Throwable) {
            0
        }
        val currentMa = if (currentUa == Int.MIN_VALUE) 0.0 else currentUa / 1000.0
        val powerW = abs(voltageMv * currentMa) / 1_000_000.0

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        return mapOf(
            "level" to level,
            "temperatureC" to temperatureC,
            "voltageMv" to voltageMv,
            "currentMa" to currentMa,
            "powerW" to powerW,
            "status" to statusLabel(statusCode),
            "health" to healthLabel(healthCode),
            "technology" to technology,
            "isCharging" to isCharging,
            "isPlugged" to isPlugged,
            "plugType" to plugTypeLabel(pluggedCode),
            "isPowerSaveMode" to powerManager.isPowerSaveMode,
            "timestamp" to System.currentTimeMillis(),
        )
    }

    private fun emptySnapshot(): Map<String, Any> = mapOf(
        "level" to 0,
        "temperatureC" to 0.0,
        "voltageMv" to 0,
        "currentMa" to 0.0,
        "powerW" to 0.0,
        "status" to "Sconosciuto",
        "health" to "Sconosciuta",
        "technology" to "—",
        "isCharging" to false,
        "isPlugged" to false,
        "plugType" to "Nessuno",
        "isPowerSaveMode" to false,
        "timestamp" to System.currentTimeMillis(),
    )

    private fun statusLabel(status: Int): String = when (status) {
        BatteryManager.BATTERY_STATUS_CHARGING -> "In carica"
        BatteryManager.BATTERY_STATUS_DISCHARGING -> "In uso"
        BatteryManager.BATTERY_STATUS_FULL -> "Carica completa"
        BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Non in carica"
        else -> "Sconosciuto"
    }

    private fun healthLabel(health: Int): String = when (health) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "Buona"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Surriscaldata"
        BatteryManager.BATTERY_HEALTH_DEAD -> "Critica"
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Sovratensione"
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Anomalia"
        BatteryManager.BATTERY_HEALTH_COLD -> "Troppo fredda"
        else -> "Sconosciuta"
    }

    private fun plugTypeLabel(plugged: Int): String = when (plugged) {
        BatteryManager.BATTERY_PLUGGED_AC -> "Caricatore AC"
        BatteryManager.BATTERY_PLUGGED_USB -> "USB"
        BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Ricarica wireless"
        BatteryManager.BATTERY_PLUGGGED_DOCK -> "Dock"
        else -> "Nessuno"
    }
}
