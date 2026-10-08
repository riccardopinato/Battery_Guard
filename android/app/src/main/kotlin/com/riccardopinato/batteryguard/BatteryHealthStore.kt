package com.riccardopinato.batteryguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

object BatteryHealthStore {
    private const val FILE = "battery_guard_health"
    private const val SAMPLES = "capacity_samples"
    private const val NOMINAL = "nominal_capacity_mah"
    private const val LAST_CYCLE = "last_cycle_count"
    private const val LAST_REPORTED_HEALTH = "last_reported_health"
    private const val LAST_REPORTED_HEALTH_AT = "last_reported_health_at"
    private const val MAX_SAMPLES = 1500
    private const val RECENT_ANALYSIS_SAMPLES = 60
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
            val now =
                (snapshot["timestamp"] as? Number)?.toLong()
                    ?: System.currentTimeMillis()

            val cycleCount =
                (snapshot["cycleCount"] as? Number)?.toInt() ?: -1
            val rawHealth = snapshot["health"]?.toString().orEmpty()
            val normalizedHealth = rawHealth.lowercase()
            val healthAvailable =
                rawHealth.isNotBlank() &&
                    !normalizedHealth.contains("sconosci") &&
                    normalizedHealth != "unknown"
            val metadata = snapshot["signals"] as? Map<*, *>
            val healthMeta = metadata?.get("health") as? Map<*, *>
            val healthSignalAvailable =
                healthMeta?.get("available") as? Boolean ?: healthAvailable

            val editor = prefs.edit()
            if (cycleCount >= 0) editor.putInt(LAST_CYCLE, cycleCount)
            if (healthAvailable && healthSignalAvailable) {
                editor
                    .putString(LAST_REPORTED_HEALTH, rawHealth)
                    .putLong(LAST_REPORTED_HEALTH_AT, now)
            }
            editor.apply()

            val available =
                snapshot["chargeCounterAvailable"] as? Boolean ?: false
            val level = (snapshot["level"] as? Number)?.toInt() ?: 0
            val chargeCounterMah =
                (snapshot["chargeCounterMah"] as? Number)?.toDouble() ?: 0.0
            val isPlugged = snapshot["isPlugged"] as? Boolean ?: false
            val isCharging = snapshot["isCharging"] as? Boolean ?: false

            // Capacity estimation is intentionally sampled while discharging.
            // A single sample is never treated as an OEM state-of-health value.
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
            val reportedHealth =
                prefs.getString(LAST_REPORTED_HEALTH, null).orEmpty()
            val reportedHealthAt =
                prefs.getLong(LAST_REPORTED_HEALTH_AT, 0L)
            val array = parseArray(prefs.getString(SAMPLES, null))

            data class Sample(
                val at: Long,
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
                        at = item.optLong("at", 0L),
                        estimateMah = estimate,
                        level = level,
                        temperatureC =
                            item.optDouble("temperatureC", 0.0),
                    ),
                )
            }

            val recent = samples.takeLast(RECENT_ANALYSIS_SAMPLES)
            val rawMedian = median(recent.map { it.estimateMah })
            val rawMad =
                median(recent.map { abs(it.estimateMah - rawMedian) })
            val toleranceMah =
                if (rawMedian > 0.0) {
                    max(rawMedian * 0.18, rawMad * 3.5)
                } else {
                    0.0
                }

            val filtered =
                if (rawMedian > 0.0) {
                    recent.filter {
                        abs(it.estimateMah - rawMedian) <= toleranceMah
                    }
                } else {
                    emptyList()
                }
            val outliers =
                if (rawMedian > 0.0) {
                    recent.filter {
                        abs(it.estimateMah - rawMedian) > toleranceMah
                    }
                } else {
                    emptyList()
                }

            val smoothed = mutableListOf<Pair<Sample, Double>>()
            for (index in filtered.indices) {
                val from = (index - 4).coerceAtLeast(0)
                val window = filtered.subList(from, index + 1)
                smoothed.add(
                    filtered[index] to median(window.map { it.estimateMah }),
                )
            }
            val estimated =
                if (smoothed.isEmpty()) 0.0 else smoothed.last().second
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
                    filtered.maxOf { it.level } - filtered.minOf { it.level }
                }
            val dispersionPercent =
                if (estimated > 0.0 && filtered.size >= 2) {
                    (
                        filtered.maxOf { it.estimateMah } -
                            filtered.minOf { it.estimateMah }
                        ) / estimated * 100.0
                } else {
                    0.0
                }

            val filteredMad =
                if (estimated > 0.0) {
                    median(filtered.map { abs(it.estimateMah - estimated) })
                } else {
                    0.0
                }
            val robustSigma = 1.4826 * filteredMad
            val uncertaintyPercent =
                if (estimated > 0.0 && filtered.isNotEmpty()) {
                    max(
                        0.5,
                        (1.96 * robustSigma /
                            sqrt(filtered.size.toDouble()) /
                            estimated * 100.0),
                    ).coerceAtMost(50.0)
                } else {
                    0.0
                }

            val now = System.currentTimeMillis()
            val lastSampleAt = filtered.lastOrNull()?.at ?: 0L
            val sampleScore =
                (filtered.size * 4.0).coerceIn(0.0, 35.0)
            val spreadScore =
                (levelSpread / 50.0 * 25.0).coerceIn(0.0, 25.0)
            val precisionScore =
                if (estimated > 0.0) {
                    (25.0 * (1.0 - uncertaintyPercent / 15.0))
                        .coerceIn(0.0, 25.0)
                } else {
                    0.0
                }
            val age = if (lastSampleAt > 0L) now - lastSampleAt else Long.MAX_VALUE
            val freshnessScore = when {
                age <= 2L * 24 * 60 * 60 * 1000 -> 15.0
                age <= 7L * 24 * 60 * 60 * 1000 -> 10.0
                age <= 30L * 24 * 60 * 60 * 1000 -> 5.0
                else -> 0.0
            }
            val confidenceScore =
                (sampleScore + spreadScore + precisionScore + freshnessScore)
                    .coerceIn(0.0, 100.0)
            val confidence = when {
                filtered.size >= 8 && confidenceScore >= 75.0 -> "high"
                filtered.size >= 4 && confidenceScore >= 50.0 -> "medium"
                else -> "low"
            }

            val trend =
                if (smoothed.size >= 8) {
                    val window = (smoothed.size / 4).coerceIn(2, 8)
                    val oldMedian =
                        median(smoothed.take(window).map { it.second })
                    val newMedian =
                        median(smoothed.takeLast(window).map { it.second })
                    if (oldMedian > 0.0) {
                        ((newMedian - oldMedian) / oldMedian) * 100.0
                    } else {
                        0.0
                    }
                } else {
                    0.0
                }
            val trendThreshold = max(1.0, uncertaintyPercent * 1.5)
            val trendDirection = when {
                smoothed.size < 8 -> "insufficient"
                trend > trendThreshold -> "up"
                trend < -trendThreshold -> "down"
                else -> "stable"
            }

            val temperatures =
                filtered.map { it.temperatureC }.filter { it > 0.0 }
            val trendPoints =
                smoothed.takeLast(30).map { (sample, value) ->
                    mapOf(
                        "at" to sample.at,
                        "rawCapacityMah" to sample.estimateMah,
                        "smoothedCapacityMah" to value,
                        "smoothedHealthPercent" to
                            if (nominal > 0) {
                                (value / nominal * 100.0)
                                    .coerceIn(0.0, 100.0)
                            } else {
                                0.0
                            },
                    )
                }
            val outlierMaps =
                outliers.takeLast(12).reversed().map { sample ->
                    mapOf(
                        "at" to sample.at,
                        "level" to sample.level,
                        "estimateMah" to sample.estimateMah,
                        "deviationPercent" to
                            if (rawMedian > 0.0) {
                                abs(sample.estimateMah - rawMedian) /
                                    rawMedian * 100.0
                            } else {
                                0.0
                            },
                    )
                }

            return mapOf(
                "estimatorVersion" to "health_lab_2",
                "nominalCapacityMah" to nominal,
                "estimatedFullCapacityMah" to estimated,
                "estimatedHealthPercent" to health,
                "reportedHealthStatus" to reportedHealth,
                "reportedHealthAvailable" to reportedHealth.isNotBlank(),
                "reportedHealthObservedAt" to reportedHealthAt,
                "confidence" to confidence,
                "confidenceScore" to confidenceScore,
                "sampleCount" to filtered.size,
                "totalSampleCount" to recent.size,
                "outlierCount" to outliers.size,
                "socSpread" to levelSpread,
                "dispersionPercent" to dispersionPercent,
                "uncertaintyPercent" to uncertaintyPercent,
                "cycleCount" to cycleCount,
                "trendPercent" to trend,
                "trendDirection" to trendDirection,
                "trendPoints" to trendPoints,
                "outliers" to outlierMaps,
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
