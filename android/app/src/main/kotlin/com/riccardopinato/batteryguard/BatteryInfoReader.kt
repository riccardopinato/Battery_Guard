package com.riccardopinato.batteryguard

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import kotlin.math.abs

object BatteryInfoReader {
    fun read(context: Context, sourceIntent: Intent? = null): Map<String, Any> {
        val observedAt = System.currentTimeMillis()
        val batteryIntent =
            if (sourceIntent?.action == Intent.ACTION_BATTERY_CHANGED) {
                sourceIntent
            } else {
                context.registerReceiver(
                    null,
                    IntentFilter(Intent.ACTION_BATTERY_CHANGED),
                )
            }

        if (batteryIntent == null) return emptySnapshot(observedAt)

        val levelRaw =
            batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale =
            batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
                .coerceAtLeast(1)
        val levelAvailable = levelRaw >= 0
        val level =
            if (levelAvailable) {
                ((levelRaw * 100f) / scale).toInt().coerceIn(0, 100)
            } else {
                0
            }

        val temperatureAvailable =
            batteryIntent.hasExtra(BatteryManager.EXTRA_TEMPERATURE)
        val voltageAvailable =
            batteryIntent.hasExtra(BatteryManager.EXTRA_VOLTAGE)
        val temperatureC =
            if (temperatureAvailable) {
                batteryIntent.getIntExtra(
                    BatteryManager.EXTRA_TEMPERATURE,
                    0,
                ) / 10.0
            } else {
                0.0
            }
        val voltageMv =
            if (voltageAvailable) {
                batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0)
            } else {
                0
            }

        val statusCode = batteryIntent.getIntExtra(
            BatteryManager.EXTRA_STATUS,
            BatteryManager.BATTERY_STATUS_UNKNOWN,
        )
        val healthCode = batteryIntent.getIntExtra(
            BatteryManager.EXTRA_HEALTH,
            BatteryManager.BATTERY_HEALTH_UNKNOWN,
        )
        val pluggedCode =
            batteryIntent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val rawTechnology =
            batteryIntent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)
                .orEmpty()
        val technologyAvailable = rawTechnology.isNotBlank()
        val technology = rawTechnology.ifBlank { "—" }
        val statusAvailable =
            statusCode != BatteryManager.BATTERY_STATUS_UNKNOWN
        val healthAvailable =
            healthCode != BatteryManager.BATTERY_HEALTH_UNKNOWN

        val isCharging =
            statusCode == BatteryManager.BATTERY_STATUS_CHARGING ||
                statusCode == BatteryManager.BATTERY_STATUS_FULL
        val isPlugged = pluggedCode != 0

        val manager =
            context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val currentUa = try {
            manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } catch (_: Throwable) {
            Int.MIN_VALUE
        }
        val currentAvailable = currentUa != Int.MIN_VALUE
        val currentMa =
            if (currentAvailable) currentUa / 1000.0 else 0.0

        val chargeCounterUaH = try {
            manager.getIntProperty(
                BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER,
            )
        } catch (_: Throwable) {
            Int.MIN_VALUE
        }
        val chargeCounterAvailable =
            chargeCounterUaH != Int.MIN_VALUE && chargeCounterUaH > 0
        val chargeCounterMah =
            if (chargeCounterAvailable) chargeCounterUaH / 1000.0 else 0.0

        val cycleCount =
            if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
                batteryIntent.hasExtra(BatteryManager.EXTRA_CYCLE_COUNT)
            ) {
                batteryIntent.getIntExtra(BatteryManager.EXTRA_CYCLE_COUNT, -1)
            } else {
                -1
            }
        val cycleCountAvailable = cycleCount >= 0

        val powerAvailable =
            currentAvailable && voltageAvailable && voltageMv > 0
        val powerW =
            if (powerAvailable) {
                abs(voltageMv * currentMa) / 1_000_000.0
            } else {
                0.0
            }

        val powerManager =
            context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val screenInteractive = powerManager.isInteractive

        val signals = linkedMapOf<String, Map<String, Any>>(
            "level" to meta(
                levelAvailable,
                "system_reported",
                "high",
                observedAt,
            ),
            "temperature" to meta(
                temperatureAvailable,
                "system_reported",
                "high",
                observedAt,
            ),
            "voltage" to meta(
                voltageAvailable,
                "system_reported",
                "high",
                observedAt,
            ),
            "current" to meta(
                currentAvailable,
                "system_reported",
                "medium",
                observedAt,
            ),
            "power" to meta(
                powerAvailable,
                "calculated",
                "medium",
                observedAt,
            ),
            "chargeCounter" to meta(
                chargeCounterAvailable,
                "system_reported",
                "medium",
                observedAt,
            ),
            "cycleCount" to meta(
                cycleCountAvailable,
                "system_reported",
                "high",
                observedAt,
            ),
            "status" to meta(
                statusAvailable,
                "system_reported",
                "high",
                observedAt,
            ),
            "health" to meta(
                healthAvailable,
                "system_reported",
                "medium",
                observedAt,
            ),
            "technology" to meta(
                technologyAvailable,
                "system_reported",
                "medium",
                observedAt,
            ),
            "plugType" to meta(
                true,
                "system_reported",
                "high",
                observedAt,
            ),
            "screenState" to meta(
                true,
                "system_reported",
                "high",
                observedAt,
            ),
        )

        return mapOf(
            "level" to level,
            "temperatureC" to temperatureC,
            "voltageMv" to voltageMv,
            "currentMa" to currentMa,
            "powerW" to powerW,
            "temperatureAvailable" to temperatureAvailable,
            "voltageAvailable" to voltageAvailable,
            "currentAvailable" to currentAvailable,
            "powerAvailable" to powerAvailable,
            "chargeCounterAvailable" to chargeCounterAvailable,
            "chargeCounterMah" to chargeCounterMah,
            "cycleCount" to cycleCount,
            "status" to statusLabel(statusCode),
            "health" to healthLabel(healthCode),
            "technology" to technology,
            "isCharging" to isCharging,
            "isPlugged" to isPlugged,
            "plugType" to plugTypeLabel(pluggedCode),
            "isPowerSaveMode" to powerManager.isPowerSaveMode,
            "screenInteractive" to screenInteractive,
            "screenStateAvailable" to true,
            "timestamp" to observedAt,
            "signals" to signals,
        )
    }

    private fun meta(
        available: Boolean,
        source: String,
        confidence: String,
        observedAt: Long,
    ): Map<String, Any> {
        return mapOf(
            "available" to available,
            "source" to if (available) source else "unavailable",
            "confidence" to if (available) confidence else "unknown",
            "observedAt" to observedAt,
        )
    }

    private fun emptySnapshot(observedAt: Long): Map<String, Any> {
        val unavailableSignals = linkedMapOf<String, Map<String, Any>>()
        listOf(
            "level",
            "temperature",
            "voltage",
            "current",
            "power",
            "chargeCounter",
            "cycleCount",
            "status",
            "health",
            "technology",
            "plugType",
            "screenState",
        ).forEach { key ->
            unavailableSignals[key] = meta(
                false,
                "unavailable",
                "unknown",
                observedAt,
            )
        }

        return mapOf(
            "level" to 0,
            "temperatureC" to 0.0,
            "voltageMv" to 0,
            "currentMa" to 0.0,
            "powerW" to 0.0,
            "temperatureAvailable" to false,
            "voltageAvailable" to false,
            "currentAvailable" to false,
            "powerAvailable" to false,
            "chargeCounterAvailable" to false,
            "chargeCounterMah" to 0.0,
            "cycleCount" to -1,
            "status" to "Sconosciuto",
            "health" to "Sconosciuta",
            "technology" to "—",
            "isCharging" to false,
            "isPlugged" to false,
            "plugType" to "Nessuno",
            "isPowerSaveMode" to false,
            "screenInteractive" to false,
            "screenStateAvailable" to false,
            "timestamp" to observedAt,
            "signals" to unavailableSignals,
        )
    }

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
        BatteryManager.BATTERY_PLUGGED_DOCK -> "Dock"
        else -> "Nessuno"
    }
}
