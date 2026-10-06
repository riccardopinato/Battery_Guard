package com.riccardopinato.batteryguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.abs

object BatteryHealthStore {
    private const val FILE = "battery_guard_health"
    private const val SAMPLES = "capacity_samples"
    private const val NOMINAL = "nominal_capacity_mah"
    private const val LAST_CYCLE = "last_cycle_count"
    private const val MAX_SAMPLES = 60
    private const val MIN_SAMPLE_GAP_MS = 6 * 60 * 60 * 1000L
    private val lock = Any()

    fun setNominalCapacity(context: Context, value: Int) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit()
            .putInt(NOMINAL, value.coerceIn(0, 20_000))
            .apply()
    }

    fun record(
        context: Context,
        snapshot: Map<String, Any>,
    ) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val cycleCount =
                (snapshot["cycleCount"] as? Number)?.toInt() ?: -1
            if (cycleCount >= 0) {
                prefs.edit().putInt(LAST_CYCLE, cycleCount).apply()
            }

            val available =
                snapshot["chargeCounterAvailable"] as? Boolean ?: false
            val level = (snapshot["level"] as? Number)?.toInt() ?: 0
            val chargeCounterMah =
                (snapshot["chargeCounterMah"] as? Number)?.toDouble() ?: 0.0
            if (!available || level !in 15..95 || chargeCounterMah <= 0.0) {
                return
            }

            val estimate = chargeCounterMah * 100.0 / level
            if (estimate !in 300.0..20_000.0) return

            val now =
                (snapshot["timestamp"] as? Number)?.toLong()
                    ?: System.currentTimeMillis()
            val temperatureAvailable =
                snapshot["temperatureAvailable"] as? Boolean ?: false
            val temperature =
                (snapshot["temperatureC"] as? Number)?.toDouble() ?: 0.0

            val array = parseArray(prefs.getString(SAMPLES, null))
            val last =
                if (array.length() > 0) {
                    array.optJSONObject(array.length() - 1)
                } else {
                    null
                }
            val lastAt = last?.optLong("at", 0L) ?: 0L
            val lastLevel = last?.optInt("level", -100) ?: -100
            if (
                lastAt > 0L &&
                now - lastAt < MIN_SAMPLE_GAP_MS &&
                abs(level - lastLevel) < 10
            ) {
                return
            }

            array.put(
                JSONObject().apply {
                    put("at", now)
                    put("level", level)
                    put("estimateMah", estimate)
                    put(
                        "temperatureC",
                        if (temperatureAvailable) temperature else 0.0,
                    )
                },
            )

            val trimmed = JSONArray()
            val start = (array.length() - MAX_SAMPLES).coerceAtLeast(0)
            for (index in start until array.length()) {
                trimmed.put(array.get(index))
            }
            prefs.edit().putString(SAMPLES, trimmed.toString()).apply()
        }
    }

    fun report(context: Context): Map<String, Any> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val nominal = prefs.getInt(NOMINAL, 0)
            val cycleCount = prefs.getInt(LAST_CYCLE, -1)
            val array = parseArray(prefs.getString(SAMPLES, null))

            val estimates = mutableListOf<Double>()
            val temperatures = mutableListOf<Double>()
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val estimate = item.optDouble("estimateMah", 0.0)
                if (estimate > 0) estimates.add(estimate)
                val temperature = item.optDouble("temperatureC", 0.0)
                if (temperature > 0) temperatures.add(temperature)
            }

            val recent = estimates.takeLast(12)
            val estimated = median(recent)
            val health =
                if (nominal > 0 && estimated > 0) {
                    (estimated / nominal * 100.0).coerceIn(0.0, 120.0)
                } else {
                    0.0
                }

            val confidence = when {
                recent.size >= 8 -> "high"
                recent.size >= 3 -> "medium"
                else -> "low"
            }

            val trend =
                if (estimates.size >= 6) {
                    val window = (estimates.size / 3).coerceAtLeast(2)
                    val oldAverage = estimates
                        .take(window)
                        .average()
                    val newAverage = estimates
                        .takeLast(window)
                        .average()
                    if (oldAverage > 0) {
                        ((newAverage - oldAverage) / oldAverage) * 100.0
                    } else {
                        0.0
                    }
                } else {
                    0.0
                }

            return mapOf(
                "nominalCapacityMah" to nominal,
                "estimatedFullCapacityMah" to estimated,
                "estimatedHealthPercent" to health,
                "confidence" to confidence,
                "sampleCount" to estimates.size,
                "cycleCount" to cycleCount,
                "trendPercent" to trend,
                "averageTemperatureC" to
                    if (temperatures.isEmpty()) 0.0 else temperatures.average(),
                "maxTemperatureC" to
                    (temperatures.maxOrNull() ?: 0.0),
            )
        }
    }

    private fun median(values: List<Double>): Double {
        if (values.isEmpty()) return 0.0
        val sorted = values.sorted()
        val middle = sorted.size / 2
        return if (sorted.size % 2 == 0) {
            (sorted[middle - 1] + sorted[middle]) / 2.0
        } else {
            sorted[middle]
        }
    }

    private fun parseArray(raw: String?): JSONArray {
        if (raw.isNullOrBlank()) return JSONArray()
        return try {
            JSONArray(raw)
        } catch (_: Throwable) {
            JSONArray()
        }
    }
}
