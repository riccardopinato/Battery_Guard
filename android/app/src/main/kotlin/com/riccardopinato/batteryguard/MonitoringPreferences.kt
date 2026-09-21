package com.riccardopinato.batteryguard

import android.content.Context
import java.util.Calendar

object MonitoringPreferences {
    private const val FILE = "battery_guard_config"
    private val targetSteps = intArrayOf(80, 85, 90, 100)

    data class Config(
        val enabled: Boolean,
        val targetLevel: Int,
        val temperatureThresholdC: Double,
        val notifyFull: Boolean,
        val notifyUnplugged: Boolean,
        val nightMode: Boolean,
        val nightStartMinutes: Int,
        val nightEndMinutes: Int,
    )

    fun get(context: Context): Config {
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        return Config(
            enabled = prefs.getBoolean("enabled", false),
            targetLevel = prefs.getInt("targetLevel", 80).coerceIn(50, 100),
            temperatureThresholdC = prefs
                .getFloat("temperatureThresholdC", 42f)
                .toDouble()
                .coerceIn(35.0, 60.0),
            notifyFull = prefs.getBoolean("notifyFull", true),
            notifyUnplugged = prefs.getBoolean("notifyUnplugged", true),
            nightMode = prefs.getBoolean("nightMode", false),
            nightStartMinutes = prefs
                .getInt("nightStartMinutes", 23 * 60)
                .coerceIn(0, 1439),
            nightEndMinutes = prefs
                .getInt("nightEndMinutes", 7 * 60)
                .coerceIn(0, 1439),
        )
    }

    fun asMap(context: Context): Map<String, Any> {
        val config = get(context)
        return mapOf(
            "enabled" to config.enabled,
            "targetLevel" to config.targetLevel,
            "temperatureThresholdC" to config.temperatureThresholdC,
            "notifyFull" to config.notifyFull,
            "notifyUnplugged" to config.notifyUnplugged,
            "nightMode" to config.nightMode,
            "nightStartMinutes" to config.nightStartMinutes,
            "nightEndMinutes" to config.nightEndMinutes,
        )
    }

    fun save(context: Context, values: Map<*, *>) {
        val current = get(context)
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(
                "enabled",
                values["enabled"] as? Boolean ?: current.enabled,
            )
            .putInt(
                "targetLevel",
                (values["targetLevel"] as? Number)
                    ?.toInt()
                    ?.coerceIn(50, 100)
                    ?: current.targetLevel,
            )
            .putFloat(
                "temperatureThresholdC",
                (values["temperatureThresholdC"] as? Number)
                    ?.toFloat()
                    ?.coerceIn(35f, 60f)
                    ?: current.temperatureThresholdC.toFloat(),
            )
            .putBoolean(
                "notifyFull",
                values["notifyFull"] as? Boolean ?: current.notifyFull,
            )
            .putBoolean(
                "notifyUnplugged",
                values["notifyUnplugged"] as? Boolean ?: current.notifyUnplugged,
            )
            .putBoolean(
                "nightMode",
                values["nightMode"] as? Boolean ?: current.nightMode,
            )
            .putInt(
                "nightStartMinutes",
                (values["nightStartMinutes"] as? Number)
                    ?.toInt()
                    ?.coerceIn(0, 1439)
                    ?: current.nightStartMinutes,
            )
            .putInt(
                "nightEndMinutes",
                (values["nightEndMinutes"] as? Number)
                    ?.toInt()
                    ?.coerceIn(0, 1439)
                    ?: current.nightEndMinutes,
            )
            .apply()
    }

    fun setEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putBoolean("enabled", enabled)
            .apply()
    }

    fun toggleEnabled(context: Context): Boolean {
        val next = !get(context).enabled
        setEnabled(context, next)
        return next
    }

    fun setTargetLevel(context: Context, targetLevel: Int) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putInt("targetLevel", targetLevel.coerceIn(50, 100))
            .apply()
    }

    fun cycleTargetLevel(context: Context): Int {
        val current = get(context).targetLevel
        val currentIndex = targetSteps.indexOf(current)
        val next = if (currentIndex >= 0) {
            targetSteps[(currentIndex + 1) % targetSteps.size]
        } else {
            targetSteps.first()
        }
        setTargetLevel(context, next)
        return next
    }

    fun isQuietNow(context: Context): Boolean {
        val config = get(context)
        if (!config.nightMode) return false

        val calendar = Calendar.getInstance()
        val now =
            calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        val start = config.nightStartMinutes
        val end = config.nightEndMinutes

        return when {
            start == end -> true
            start < end -> now in start until end
            else -> now >= start || now < end
        }
    }
}
