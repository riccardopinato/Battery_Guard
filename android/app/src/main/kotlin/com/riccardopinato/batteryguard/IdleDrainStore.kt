package com.riccardopinato.batteryguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.abs

object IdleDrainStore {
    private const val FILE = "battery_guard_idle_drain"
    private const val SEGMENTS = "segments"
    private const val ACTIVE = "active_segment"
    private const val MAX_SEGMENTS = 90
    private const val MIN_DURATION_MS = 30 * 60 * 1000L
    private const val MAX_DURATION_MS = 14 * 60 * 60 * 1000L
    private val lock = Any()

    fun record(
        context: Context,
        snapshot: Map<String, Any>,
    ) {
        synchronized(lock) {
            val level = (snapshot["level"] as? Number)?.toInt() ?: return
            if (level !in 1..100) return
            val now =
                (snapshot["timestamp"] as? Number)?.toLong()
                    ?: System.currentTimeMillis()
            val plugged = snapshot["isPlugged"] as? Boolean ?: false
            val charging = snapshot["isCharging"] as? Boolean ?: false
            val interactive =
                snapshot["screenInteractive"] as? Boolean ?: true
            val powerSaveMode =
                snapshot["isPowerSaveMode"] as? Boolean ?: false

            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val active = parseObject(prefs.getString(ACTIVE, null))

            if (plugged || charging) {
                if (active != null) {
                    prefs.edit().remove(ACTIVE).apply()
                }
                return
            }

            if (!interactive) {
                if (active == null) {
                    val started = JSONObject().apply {
                        put("startedAt", now)
                        put("startLevel", level)
                        put("powerSaveMode", powerSaveMode)
                    }
                    prefs.edit().putString(ACTIVE, started.toString()).apply()
                } else if (now - active.optLong("startedAt", now) > MAX_DURATION_MS) {
                    // A stale interval is not reliable evidence. Restart it
                    // instead of fabricating a very long idle segment.
                    val restarted = JSONObject().apply {
                        put("startedAt", now)
                        put("startLevel", level)
                        put("powerSaveMode", powerSaveMode)
                    }
                    prefs.edit().putString(ACTIVE, restarted.toString()).apply()
                }
                return
            }

            if (active == null) return
            prefs.edit().remove(ACTIVE).apply()

            val startedAt = active.optLong("startedAt", 0L)
            val startLevel = active.optInt("startLevel", -1)
            val duration = now - startedAt
            if (
                startedAt <= 0L ||
                startLevel !in 1..100 ||
                duration !in MIN_DURATION_MS..MAX_DURATION_MS
            ) {
                return
            }

            val drop = startLevel - level
            if (drop < 0 || drop > 50) return

            val hours = duration / 3_600_000.0
            if (hours <= 0.0) return
            val rate = drop / hours
            if (!rate.isFinite() || rate < 0.0 || rate > 15.0) return

            val segments = parseArray(prefs.getString(SEGMENTS, null))
            segments.put(
                JSONObject().apply {
                    put("startedAt", startedAt)
                    put("endedAt", now)
                    put("durationMinutes", (duration / 60_000L).toInt())
                    put("startLevel", startLevel)
                    put("endLevel", level)
                    put("ratePercentPerHour", rate)
                    put("powerSaveMode", active.optBoolean("powerSaveMode", false))
                },
            )
            val trimmed = JSONArray()
            val start = (segments.length() - MAX_SEGMENTS).coerceAtLeast(0)
            for (index in start until segments.length()) {
                trimmed.put(segments.get(index))
            }
            prefs.edit().putString(SEGMENTS, trimmed.toString()).apply()
        }
    }

    fun report(context: Context): Map<String, Any> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(SEGMENTS, null))
            val segments = mutableListOf<JSONObject>()
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val duration = item.optInt("durationMinutes", 0)
                val rate = item.optDouble("ratePercentPerHour", -1.0)
                if (duration >= 30 && rate in 0.0..15.0) {
                    segments.add(item)
                }
            }

            if (segments.size < 4) {
                return mapOf(
                    "status" to "insufficient",
                    "confidence" to "low",
                    "segmentCount" to segments.size,
                    "baselineRatePercentPerHour" to 0.0,
                    "recentRatePercentPerHour" to 0.0,
                    "deltaPercent" to 0.0,
                    "powerSaveMode" to false,
                    "recentSegments" to recentMaps(segments),
                )
            }

            val latestMode =
                segments.last().optBoolean("powerSaveMode", false)
            val comparable = segments.filter {
                it.optBoolean("powerSaveMode", false) == latestMode
            }
            if (comparable.size < 4) {
                return mapOf(
                    "status" to "insufficient",
                    "confidence" to "low",
                    "segmentCount" to comparable.size,
                    "baselineRatePercentPerHour" to 0.0,
                    "recentRatePercentPerHour" to 0.0,
                    "deltaPercent" to 0.0,
                    "powerSaveMode" to latestMode,
                    "recentSegments" to recentMaps(comparable),
                )
            }

            val recentCount = if (comparable.size >= 8) 3 else 2
            val recent = comparable.takeLast(recentCount)
            val baselinePool =
                comparable.dropLast(recentCount).takeLast(20)
            if (baselinePool.size < 2) {
                return mapOf(
                    "status" to "insufficient",
                    "confidence" to "low",
                    "segmentCount" to comparable.size,
                    "baselineRatePercentPerHour" to 0.0,
                    "recentRatePercentPerHour" to medianRates(recent),
                    "deltaPercent" to 0.0,
                    "powerSaveMode" to latestMode,
                    "recentSegments" to recentMaps(comparable),
                )
            }

            val baseline = medianRates(baselinePool)
            val recentRate = medianRates(recent)
            val deltaPercent =
                if (baseline >= 0.10) {
                    ((recentRate - baseline) / baseline) * 100.0
                } else {
                    0.0
                }

            val status = when {
                recentRate >= 2.5 &&
                    (baseline < 0.10 || recentRate >= baseline * 2.0) -> "high"
                recentRate >= 1.2 &&
                    (baseline < 0.10 || recentRate >= baseline * 1.5) -> "elevated"
                baseline >= 0.10 && deltaPercent >= 60.0 -> "elevated"
                else -> "normal"
            }

            val totalBaselineMinutes =
                baselinePool.sumOf { it.optInt("durationMinutes", 0) }
            val confidence = when {
                baselinePool.size >= 6 &&
                    recent.size >= 3 &&
                    totalBaselineMinutes >= 360 -> "high"
                baselinePool.size >= 3 &&
                    totalBaselineMinutes >= 180 -> "medium"
                else -> "low"
            }

            return mapOf(
                "status" to status,
                "confidence" to confidence,
                "segmentCount" to comparable.size,
                "baselineRatePercentPerHour" to baseline,
                "recentRatePercentPerHour" to recentRate,
                "deltaPercent" to deltaPercent,
                "powerSaveMode" to latestMode,
                "recentSegments" to recentMaps(comparable),
            )
        }
    }

    private fun recentMaps(
        segments: List<JSONObject>,
    ): List<Map<String, Any>> {
        return segments.takeLast(5).reversed().map { item ->
            mapOf(
                "endedAt" to item.optLong("endedAt", 0L),
                "durationMinutes" to item.optInt("durationMinutes", 0),
                "startLevel" to item.optInt("startLevel", 0),
                "endLevel" to item.optInt("endLevel", 0),
                "ratePercentPerHour" to
                    item.optDouble("ratePercentPerHour", 0.0),
                "powerSaveMode" to
                    item.optBoolean("powerSaveMode", false),
            )
        }
    }

    private fun medianRates(items: List<JSONObject>): Double {
        val values =
            items.map { it.optDouble("ratePercentPerHour", 0.0) }
                .filter { it >= 0.0 }
                .sorted()
        if (values.isEmpty()) return 0.0
        val middle = values.size / 2
        return if (values.size % 2 == 0) {
            (values[middle - 1] + values[middle]) / 2.0
        } else {
            values[middle]
        }
    }

    private fun parseObject(raw: String?): JSONObject? {
        if (raw.isNullOrBlank()) return null
        return try {
            JSONObject(raw)
        } catch (_: Throwable) {
            null
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
