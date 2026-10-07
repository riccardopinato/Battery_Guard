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
    private const val MAX_SAMPLES = 1500
    private const val MIN_SAMPLE_GAP_MS = 6 * 60 * 60 * 1000L
    private const val LAST_SAMPLE_AT = "last_capacity_sample_at"
    private const val LAST_SAMPLE_LEVEL = "last_capacity_sample_level"
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
            val isPlugged = snapshot["isPlugged"] as? Boolean ?: false
            val isCharging = snapshot["isCharging"] as? Boolean ?: false

            // Capacity estimation is intentionally sampled while discharging:
            // this reduces transient lag between charge counter and rounded SoC.
            if (
                !available ||
                isPlugged ||
                isCharging ||
                level !in 20..90 ||
                chargeCounterMah <= 0.0
            ) {
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

            val lastAt = prefs.getLong(LAST_SAMPLE_AT, 0L)
            val lastLevel = prefs.getInt(LAST_SAMPLE_LEVEL, -100)
            if (
                lastAt > 0L &&
                now - lastAt < MIN_SAMPLE_GAP_MS &&
                abs(level - lastLevel) < 10
            ) {
                return
            }

            val array = parseArray(prefs.getString(SAMPLES, null))
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
            prefs.edit()
                .putString(SAMPLES, trimmed.toString())
                .putLong(LAST_SAMPLE_AT, now)
                .putInt(LAST_SAMPLE_LEVEL, level)
                .apply()
        }
    }

    fun report(context: Context): Map<String, Any> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val nominal = prefs.getInt(NOMINAL, 0)
            val cycleCount = prefs.getInt(LAST_CYCLE, -1)
            val array = parseArray(prefs.getString(SAMPLES, null))

            data class Sample(
                val estimateMah: Double,
                val level: Int,
                val temperatureC: Double,
            )

            val samples = mutableListOf<Sample>()
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val estimate = item.optDouble("estimateMah", 0.0)
                val level = item.optInt("level", 0)
                if (estimate <= 0 || level !in 20..90) continue
                samples.add(
                    Sample(
                        estimateMah = estimate,
                        level = level,
                        temperatureC =
                            item.optDouble("temperatureC", 0.0),
                    ),
                )
            }

            val recent = samples.takeLast(24)
            val rawMedian = median(recent.map { it.estimateMah })
            val filtered =
                if (rawMedian > 0) {
                    recent.filter {
                        abs(it.estimateMah - rawMedian) / rawMedian <= 0.18
                    }
                } else {
                    emptyList()
                }

            val estimated = median(filtered.map { it.estimateMah })
            val health =
                if (nominal > 0 && estimated > 0) {
                    (estimated / nominal * 100.0).coerceIn(0.0, 100.0)
                } else {
                    0.0
                }

            val levelSpread =
                if (filtered.isEmpty()) {
                    0
                } else {
                    (filtered.maxOf { it.level } -
                        filtered.minOf { it.level })
                }

            val relativeRange =
                if (estimated > 0 && filtered.size >= 2) {
                    (
                        filtered.maxOf { it.estimateMah } -
                            filtered.minOf { it.estimateMah }
                        ) / estimated
                } else {
                    Double.POSITIVE_INFINITY
                }

            val confidence = when {
                filtered.size >= 8 &&
                    levelSpread >= 40 &&
                    relativeRange <= 0.18 -> "high"
                filtered.size >= 4 &&
                    levelSpread >= 20 &&
                    relativeRange <= 0.30 -> "medium"
                else -> "low"
            }

            val allEstimates = samples.map { it.estimateMah }
            val trend =
                if (allEstimates.size >= 12) {
                    val window =
                        (allEstimates.size / 6)
                            .coerceIn(4, 30)
                    val oldMedian = median(allEstimates.take(window))
                    val newMedian = median(allEstimates.takeLast(window))
                    if (oldMedian > 0) {
                        ((newMedian - oldMedian) / oldMedian) * 100.0
                    } else {
                        0.0
                    }
                } else {
                    0.0
                }

            val temperatures =
                samples.map { it.temperatureC }.filter { it > 0 }

            return mapOf(
                "nominalCapacityMah" to nominal,
                "estimatedFullCapacityMah" to estimated,
                "estimatedHealthPercent" to health,
                "confidence" to confidence,
                "sampleCount" to filtered.size,
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
