package com.riccardopinato.batteryguard

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToInt

object ChargingSessionStore {
    private const val FILE = "battery_guard_charging_sessions"
    private const val ACTIVE = "active"
    private const val COMPLETED = "completed"
    private const val MAX_SESSIONS = 80
    private const val MIN_RATE_WINDOW_MS = 3 * 60 * 1000L
    private const val MIN_VALID_DURATION_MS = 3 * 60 * 1000L
    private const val MIN_VALID_SOC_DELTA = 5
    private const val SLOW_WINDOW_MS = 20 * 60 * 1000L
    private const val RAPID_TEMP_WINDOW_MS = 20 * 60 * 1000L
    private const val MAX_SESSION_GAP_MS = 45 * 60 * 1000L
    private const val OEM_PAUSE_DETECTION_MS = 8 * 60 * 1000L
    private const val CURVE_MIN_INTERVAL_MS = 30 * 1000L
    private const val CURVE_MAX_INTERVAL_MS = 2 * 60 * 1000L
    private const val MAX_CURVE_POINTS = 120
    private val lock = Any()

    data class UpdateResult(
        val current: Map<String, Any?>?,
        val rapidTemperatureAlert: Boolean,
        val slowChargingAlert: Boolean,
        val adaptiveSlowChargingAlert: Boolean,
        val adaptiveTemperatureAlert: Boolean,
        val baselineRate: Double,
        val baselineMaxTemperatureC: Double,
    )

    private data class Baseline(
        val count: Int,
        val temperatureCount: Int,
        val averageRate: Double,
        val averageMaxTemperatureC: Double,
    )

    fun update(
        context: Context,
        snapshot: Map<String, Any>,
        targetLevel: Int,
    ): UpdateResult {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val plugged = snapshot["isPlugged"] as? Boolean ?: false
            var active = parseObject(prefs.getString(ACTIVE, null))

            if (active != null) {
                migrateActive(active, now)
                val lastObserved = active.optLong("lastObservedAt", now)
                if (now - lastObserved > MAX_SESSION_GAP_MS) {
                    finalizeLocked(
                        prefs = prefs,
                        active = active,
                        endedAt = lastObserved,
                        completionReason = "MONITORING_GAP",
                        interrupted = true,
                    )
                    active = null
                }
            }

            if (!plugged) {
                if (active != null) {
                    active = updateObject(
                        active = active,
                        snapshot = snapshot,
                        targetLevel = targetLevel,
                        now = now,
                        includePowerSample = false,
                        forceCurvePoint = true,
                    )
                    finalizeLocked(
                        prefs = prefs,
                        active = active,
                        endedAt = now,
                        completionReason = "USER_UNPLUGGED",
                        interrupted = false,
                    )
                    prefs.edit().remove(ACTIVE).apply()
                }
                return emptyResult()
            }

            active = if (active == null) {
                createActive(snapshot, targetLevel, now)
            } else {
                updateObject(
                    active = active,
                    snapshot = snapshot,
                    targetLevel = targetLevel,
                    now = now,
                    includePowerSample = true,
                    forceCurvePoint = false,
                )
            }

            updateOemChargeLimitState(active, snapshot, now)

            val elapsed = now - active.optLong("startedAt", now)
            val currentTemp = active.optDouble("currentTemperatureC", 0.0)
            val startTemp = active.optDouble("startTemperatureC", currentTemp)
            val temperatureAvailable =
                active.optBoolean("temperatureAvailable", false)
            val currentLevel = active.optInt("currentLevel", 0)
            val rate = percentPerHour(active, now)
            val baseline = baselineFor(
                prefs = prefs,
                plugType = active.optString("plugType", ""),
            )

            val adaptiveSlowChargingAlert =
                !active.optBoolean("adaptiveSlowChargingAlerted", false) &&
                    elapsed >= SLOW_WINDOW_MS &&
                    currentLevel < 90 &&
                    baseline.count >= 3 &&
                    baseline.averageRate >= 8.0 &&
                    rate > 0.0 &&
                    rate < baseline.averageRate * 0.55

            val adaptiveTemperatureAlert =
                !active.optBoolean("adaptiveTemperatureAlerted", false) &&
                    temperatureAvailable &&
                    baseline.temperatureCount >= 3 &&
                    currentTemp >= 38.0 &&
                    currentTemp >= baseline.averageMaxTemperatureC + 4.0

            val rapidTemperatureAlert =
                !adaptiveTemperatureAlert &&
                    !active.optBoolean("rapidTemperatureAlerted", false) &&
                    temperatureAvailable &&
                    elapsed in 60_000L..RAPID_TEMP_WINDOW_MS &&
                    currentTemp >= 38.0 &&
                    currentTemp - startTemp >= 5.0

            val slowChargingAlert =
                !adaptiveSlowChargingAlert &&
                    !active.optBoolean("slowChargingAlerted", false) &&
                    elapsed >= SLOW_WINDOW_MS &&
                    currentLevel < 80 &&
                    rate > 0.0 &&
                    rate < 8.0

            prefs.edit().putString(ACTIVE, active.toString()).apply()
            return UpdateResult(
                current = toMap(active, now),
                rapidTemperatureAlert = rapidTemperatureAlert,
                slowChargingAlert = slowChargingAlert,
                adaptiveSlowChargingAlert = adaptiveSlowChargingAlert,
                adaptiveTemperatureAlert = adaptiveTemperatureAlert,
                baselineRate = baseline.averageRate,
                baselineMaxTemperatureC = baseline.averageMaxTemperatureC,
            )
        }
    }

    fun markAlertDelivered(
        context: Context,
        alertType: String,
    ) {
        val key = when (alertType) {
            "rapidTemperature" -> "rapidTemperatureAlerted"
            "slowCharging" -> "slowChargingAlerted"
            "adaptiveSlowCharging" -> "adaptiveSlowChargingAlerted"
            "adaptiveTemperature" -> "adaptiveTemperatureAlerted"
            else -> return
        }

        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val active = parseObject(prefs.getString(ACTIVE, null)) ?: return
            active.put(key, true)
            prefs.edit().putString(ACTIVE, active.toString()).apply()
        }
    }

    fun getCurrent(context: Context): Map<String, Any?>? {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val active = parseObject(prefs.getString(ACTIVE, null)) ?: return null
            migrateActive(active, System.currentTimeMillis())
            return toMap(active, System.currentTimeMillis())
        }
    }

    fun getAll(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(COMPLETED, null))
            val result = ArrayList<Map<String, Any?>>(array.length())
            for (index in array.length() - 1 downTo 0) {
                val item = array.optJSONObject(index) ?: continue
                migrateCompleted(item)
                result.add(
                    toMap(
                        item,
                        item.optLong("endedAt", System.currentTimeMillis()),
                    ),
                )
            }
            return result
        }
    }

    fun clearCompleted(context: Context) {
        synchronized(lock) {
            context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
                .edit()
                .remove(COMPLETED)
                .apply()
        }
    }

    private fun emptyResult() = UpdateResult(
        current = null,
        rapidTemperatureAlert = false,
        slowChargingAlert = false,
        adaptiveSlowChargingAlert = false,
        adaptiveTemperatureAlert = false,
        baselineRate = 0.0,
        baselineMaxTemperatureC = 0.0,
    )

    private fun createActive(
        snapshot: Map<String, Any>,
        targetLevel: Int,
        now: Long,
    ): JSONObject {
        val level = intValue(snapshot, "level")
        val temperature = doubleValue(snapshot, "temperatureC")
        val temperatureAvailable =
            snapshot["temperatureAvailable"] as? Boolean ?: false
        val powerAvailable = snapshot["powerAvailable"] as? Boolean ?: false
        val currentAvailable =
            snapshot["currentAvailable"] as? Boolean ?: false
        val power =
            if (powerAvailable) abs(doubleValue(snapshot, "powerW")) else 0.0
        val current =
            if (currentAvailable) abs(doubleValue(snapshot, "currentMa")) else 0.0

        return JSONObject().apply {
            put("id", now.toString())
            put("startedAt", now)
            put("lastObservedAt", now)
            put("endedAt", 0L)
            put("quality", "active")
            put("validity", "active")
            put("reasonCodes", JSONArray())
            put("startLevel", level)
            put("currentLevel", level)
            put("endLevel", level)
            put("startTemperatureC", temperature)
            put("currentTemperatureC", temperature)
            put("maxTemperatureC", temperature)
            put("temperatureAvailable", temperatureAvailable)
            put("powerSum", power)
            put("currentSum", current)
            put("powerSampleCount", if (powerAvailable) 1 else 0)
            put("currentSampleCount", if (currentAvailable) 1 else 0)
            put("plugType", snapshot["plugType"]?.toString() ?: "Sconosciuto")
            put("targetLevel", targetLevel.coerceIn(50, 100))
            put("rapidTemperatureAlerted", false)
            put("slowChargingAlerted", false)
            put("adaptiveSlowChargingAlerted", false)
            put("adaptiveTemperatureAlerted", false)
            put("notChargingSince", 0L)
            put("notChargingLevel", level)
            put("oemChargeLimitDetected", false)
            put("oemChargeLimitLevel", -1)
            put("curvePoints", JSONArray())
            appendCurvePoint(this, snapshot, now, force = true)
        }
    }

    private fun updateObject(
        active: JSONObject,
        snapshot: Map<String, Any>,
        targetLevel: Int,
        now: Long,
        includePowerSample: Boolean,
        forceCurvePoint: Boolean,
    ): JSONObject {
        val level = intValue(snapshot, "level")
        val temperatureAvailable =
            snapshot["temperatureAvailable"] as? Boolean ?: false
        val temperature = doubleValue(snapshot, "temperatureC")

        active.put("currentLevel", level)
        active.put("endLevel", level)
        active.put("lastObservedAt", now)
        active.put("targetLevel", targetLevel.coerceIn(50, 100))

        if (temperatureAvailable) {
            active.put("temperatureAvailable", true)
            active.put("currentTemperatureC", temperature)
            active.put(
                "maxTemperatureC",
                max(
                    active.optDouble("maxTemperatureC", temperature),
                    temperature,
                ),
            )
        }

        val plugType = snapshot["plugType"]?.toString().orEmpty()
        if (plugType.isNotBlank() && plugType != "Nessuno") {
            active.put("plugType", plugType)
        }

        if (includePowerSample) {
            if (snapshot["powerAvailable"] as? Boolean == true) {
                active.put(
                    "powerSum",
                    active.optDouble("powerSum", 0.0) +
                        abs(doubleValue(snapshot, "powerW")),
                )
                active.put(
                    "powerSampleCount",
                    active.optInt("powerSampleCount", 0) + 1,
                )
            }
            if (snapshot["currentAvailable"] as? Boolean == true) {
                active.put(
                    "currentSum",
                    active.optDouble("currentSum", 0.0) +
                        abs(doubleValue(snapshot, "currentMa")),
                )
                active.put(
                    "currentSampleCount",
                    active.optInt("currentSampleCount", 0) + 1,
                )
            }
        }

        appendCurvePoint(
            active = active,
            snapshot = snapshot,
            now = now,
            force = forceCurvePoint,
        )
        return active
    }

    private fun updateOemChargeLimitState(
        active: JSONObject,
        snapshot: Map<String, Any>,
        now: Long,
    ) {
        val plugged = snapshot["isPlugged"] as? Boolean ?: false
        val charging = snapshot["isCharging"] as? Boolean ?: false
        val level = intValue(snapshot, "level")

        if (!plugged || charging || level !in 60..99) {
            active.put("notChargingSince", 0L)
            active.put("notChargingLevel", level)
            return
        }

        val since = active.optLong("notChargingSince", 0L)
        if (since <= 0L) {
            active.put("notChargingSince", now)
            active.put("notChargingLevel", level)
            return
        }

        val initialLevel = active.optInt("notChargingLevel", level)
        if (abs(level - initialLevel) > 1) {
            active.put("notChargingSince", now)
            active.put("notChargingLevel", level)
            return
        }

        if (now - since >= OEM_PAUSE_DETECTION_MS) {
            active.put("oemChargeLimitDetected", true)
            active.put("oemChargeLimitLevel", level)
        }
    }

    private fun finalizeLocked(
        prefs: SharedPreferences,
        active: JSONObject,
        endedAt: Long,
        completionReason: String,
        interrupted: Boolean,
    ) {
        active.put("endedAt", endedAt)
        active.put("lastObservedAt", endedAt)
        active.put("quality", if (interrupted) "interrupted" else "completed")

        val reasons = JSONArray()
        val duration = endedAt - active.optLong("startedAt", endedAt)
        val gained =
            active.optInt("endLevel", 0) - active.optInt("startLevel", 0)

        if (duration < MIN_VALID_DURATION_MS) {
            reasons.put("TOO_SHORT")
        }
        if (gained < MIN_VALID_SOC_DELTA) {
            reasons.put("INSUFFICIENT_SOC_DELTA")
        }
        if (active.optInt("powerSampleCount", 0) <= 0) {
            reasons.put("POWER_DATA_MISSING")
        }
        if (active.optInt("currentSampleCount", 0) <= 0) {
            reasons.put("CURRENT_DATA_MISSING")
        }
        if (!active.optBoolean("temperatureAvailable", false)) {
            reasons.put("TEMPERATURE_DATA_MISSING")
        }
        if (active.optBoolean("oemChargeLimitDetected", false)) {
            reasons.put("OEM_CHARGE_LIMIT")
        }

        when (completionReason) {
            "MONITORING_GAP" -> {
                reasons.put("MONITORING_GAP")
                reasons.put("SYSTEM_INTERRUPTED")
            }
            "USER_UNPLUGGED" -> reasons.put("USER_UNPLUGGED")
        }

        val validity = when {
            interrupted -> "interrupted"
            duration < MIN_VALID_DURATION_MS || gained < MIN_VALID_SOC_DELTA ->
                "excluded"
            active.optInt("powerSampleCount", 0) <= 0 ||
                active.optInt("currentSampleCount", 0) <= 0 ||
                !active.optBoolean("temperatureAvailable", false) ->
                "partial"
            else -> "valid"
        }

        active.put("validity", validity)
        active.put("reasonCodes", reasons)
        addCompletedLocked(prefs, active)
    }

    private fun appendCurvePoint(
        active: JSONObject,
        snapshot: Map<String, Any>,
        now: Long,
        force: Boolean,
    ) {
        val points = active.optJSONArray("curvePoints") ?: JSONArray()
        val last =
            if (points.length() > 0) {
                points.optJSONObject(points.length() - 1)
            } else {
                null
            }

        val level = intValue(snapshot, "level")
        val isCharging = snapshot["isCharging"] as? Boolean ?: false
        val temperatureAvailable =
            snapshot["temperatureAvailable"] as? Boolean ?: false
        val voltageAvailable =
            snapshot["voltageAvailable"] as? Boolean ?: false
        val currentAvailable =
            snapshot["currentAvailable"] as? Boolean ?: false
        val powerAvailable =
            snapshot["powerAvailable"] as? Boolean ?: false
        val temperature = doubleValue(snapshot, "temperatureC")
        val voltageV = doubleValue(snapshot, "voltageMv") / 1000.0
        val current = abs(doubleValue(snapshot, "currentMa"))
        val power = abs(doubleValue(snapshot, "powerW"))

        val shouldRecord = if (last == null || force) {
            true
        } else {
            val elapsed = now - last.optLong("timestamp", now)
            val lastPowerAvailable = last.optBoolean("powerAvailable", false)
            val lastPower = last.optDouble("powerW", 0.0)
            val meaningfulPowerChange =
                powerAvailable &&
                    lastPowerAvailable &&
                    max(power, lastPower) > 0.5 &&
                    abs(power - lastPower) / max(power, lastPower) >= 0.15
            val meaningfulTemperatureChange =
                temperatureAvailable &&
                    last.optBoolean("temperatureAvailable", false) &&
                    abs(
                        temperature -
                            last.optDouble("temperatureC", temperature),
                    ) >= 0.5

            elapsed >= CURVE_MAX_INTERVAL_MS ||
                (
                    elapsed >= CURVE_MIN_INTERVAL_MS &&
                        (
                            level != last.optInt("level", level) ||
                                isCharging !=
                                    last.optBoolean("isCharging", isCharging) ||
                                meaningfulPowerChange ||
                                meaningfulTemperatureChange
                            )
                    )
        }

        if (!shouldRecord) return

        points.put(
            JSONObject().apply {
                put("timestamp", now)
                put("level", level)
                put("isCharging", isCharging)
                put(
                    "isPlugged",
                    snapshot["isPlugged"] as? Boolean ?: false,
                )
                put(
                    "screenStateAvailable",
                    snapshot["screenStateAvailable"] as? Boolean ?: false,
                )
                put(
                    "screenInteractive",
                    snapshot["screenInteractive"] as? Boolean ?: false,
                )
                put("temperatureAvailable", temperatureAvailable)
                put("temperatureC", if (temperatureAvailable) temperature else 0.0)
                put("voltageAvailable", voltageAvailable)
                put("voltageV", if (voltageAvailable) voltageV else 0.0)
                put("currentAvailable", currentAvailable)
                put("currentMa", if (currentAvailable) current else 0.0)
                put("powerAvailable", powerAvailable)
                put("powerW", if (powerAvailable) power else 0.0)
            },
        )

        active.put(
            "curvePoints",
            if (points.length() > MAX_CURVE_POINTS) {
                compactCurve(points)
            } else {
                points
            },
        )
    }

    private fun compactCurve(points: JSONArray): JSONArray {
        if (points.length() <= MAX_CURVE_POINTS) return points

        val compacted = JSONArray()
        compacted.put(points.optJSONObject(0))

        var index = 2
        while (index < points.length() - 1) {
            compacted.put(points.optJSONObject(index))
            index += 2
        }

        val last = points.optJSONObject(points.length() - 1)
        if (last != null) compacted.put(last)
        return compacted
    }

    private fun baselineFor(
        prefs: SharedPreferences,
        plugType: String,
    ): Baseline {
        if (plugType.isBlank() || plugType == "Nessuno") {
            return Baseline(0, 0, 0.0, 0.0)
        }

        val array = parseArray(prefs.getString(COMPLETED, null))
        var count = 0
        var rateSum = 0.0
        var temperatureSum = 0.0
        var temperatureCount = 0

        for (index in array.length() - 1 downTo 0) {
            if (count >= 20) break
            val item = array.optJSONObject(index) ?: continue
            migrateCompleted(item)
            if (item.optString("quality", "uncertain") != "completed") continue
            if (item.optString("validity", "uncertain") !in listOf("valid", "partial")) {
                continue
            }
            if (item.optString("plugType", "") != plugType) continue

            val endedAt = item.optLong("endedAt", 0L)
            val startedAt = item.optLong("startedAt", endedAt)
            if (endedAt <= startedAt) continue
            if (endedAt - startedAt > 8 * 60 * 60 * 1000L) continue

            val gained =
                item.optInt("endLevel", 0) - item.optInt("startLevel", 0)
            if (gained < MIN_VALID_SOC_DELTA) continue

            val rate = percentPerHour(item, endedAt)
            if (rate <= 0.0) continue

            rateSum += rate
            if (item.optBoolean("temperatureAvailable", false)) {
                temperatureSum += item.optDouble("maxTemperatureC", 0.0)
                temperatureCount += 1
            }
            count += 1
        }

        if (count == 0) return Baseline(0, 0, 0.0, 0.0)
        return Baseline(
            count = count,
            temperatureCount = temperatureCount,
            averageRate = rateSum / count,
            averageMaxTemperatureC =
                if (temperatureCount > 0) {
                    temperatureSum / temperatureCount
                } else {
                    0.0
                },
        )
    }

    private fun toMap(item: JSONObject, now: Long): Map<String, Any?> {
        val startedAt = item.optLong("startedAt", now)
        val endedAt = item.optLong("endedAt", 0L)
        val lastObservedAt = item.optLong(
            "lastObservedAt",
            if (endedAt > 0L) endedAt else now,
        )
        val effectiveEnd = if (endedAt > 0L) endedAt else now
        val powerSamples =
            item.optInt(
                "powerSampleCount",
                item.optInt("sampleCount", 0),
            )
        val currentSamples =
            item.optInt(
                "currentSampleCount",
                item.optInt("sampleCount", 0),
            )
        val averagePower =
            if (powerSamples > 0) {
                item.optDouble("powerSum", 0.0) / powerSamples
            } else {
                0.0
            }
        val averageCurrent =
            if (currentSamples > 0) {
                item.optDouble("currentSum", 0.0) / currentSamples
            } else {
                0.0
            }
        val rate = percentPerHour(item, effectiveEnd)
        val target = item.optInt("targetLevel", 80)
        val currentLevel = item.optInt("currentLevel", 0)
        val remaining = target - currentLevel
        val estimatedMinutes =
            if (remaining > 0 && rate > 0.0) {
                ((remaining / rate) * 60.0)
                    .roundToInt()
                    .coerceAtLeast(1)
            } else {
                -1
            }
        val quality = item.optString("quality", "uncertain")
        val reasonCodes = jsonArrayToStringList(
            item.optJSONArray("reasonCodes") ?: JSONArray(),
        )
        val curvePoints = jsonArrayToMapList(
            item.optJSONArray("curvePoints") ?: JSONArray(),
        )
        val oemLevel = item.optInt("oemChargeLimitLevel", -1)

        return mapOf(
            "id" to item.optString("id", startedAt.toString()),
            "startedAt" to startedAt,
            "endedAt" to endedAt,
            "lastObservedAt" to lastObservedAt,
            "quality" to quality,
            "validity" to item.optString(
                "validity",
                legacyValidity(quality),
            ),
            "reasonCodes" to reasonCodes,
            "startLevel" to item.optInt("startLevel", 0),
            "currentLevel" to currentLevel,
            "endLevel" to item.optInt("endLevel", currentLevel),
            "startTemperatureC" to item.optDouble("startTemperatureC", 0.0),
            "currentTemperatureC" to item.optDouble("currentTemperatureC", 0.0),
            "maxTemperatureC" to item.optDouble("maxTemperatureC", 0.0),
            "temperatureAvailable" to
                item.optBoolean(
                    "temperatureAvailable",
                    item.optDouble("maxTemperatureC", 0.0) != 0.0,
                ),
            "averagePowerW" to averagePower,
            "averageCurrentMa" to averageCurrent,
            "percentPerHour" to rate,
            "estimatedMinutesToTarget" to estimatedMinutes,
            "plugType" to item.optString("plugType", "Sconosciuto"),
            "targetLevel" to target,
            "completed" to (quality == "completed"),
            "oemChargeLimitDetected" to
                item.optBoolean("oemChargeLimitDetected", false),
            "oemChargeLimitLevel" to if (oemLevel >= 0) oemLevel else null,
            "curvePoints" to curvePoints,
        )
    }

    private fun percentPerHour(
        item: JSONObject,
        endTime: Long,
    ): Double {
        val startedAt = item.optLong("startedAt", endTime)
        val elapsed = (endTime - startedAt).coerceAtLeast(0L)
        if (elapsed < MIN_RATE_WINDOW_MS) return 0.0
        val gained =
            item.optInt("currentLevel", item.optInt("endLevel", 0)) -
                item.optInt("startLevel", 0)
        if (gained <= 0) return 0.0
        val hours = elapsed / 3_600_000.0
        return if (hours > 0.0) gained / hours else 0.0
    }

    private fun addCompletedLocked(
        prefs: SharedPreferences,
        item: JSONObject,
    ) {
        val array = parseArray(prefs.getString(COMPLETED, null))
        array.put(item)
        val trimmed = JSONArray()
        val start = (array.length() - MAX_SESSIONS).coerceAtLeast(0)
        for (index in start until array.length()) {
            trimmed.put(array.get(index))
        }
        prefs.edit().putString(COMPLETED, trimmed.toString()).apply()
    }

    private fun migrateActive(
        item: JSONObject,
        now: Long,
    ) {
        if (!item.has("lastObservedAt")) {
            item.put("lastObservedAt", item.optLong("startedAt", now))
        }
        if (!item.has("quality")) {
            item.put("quality", "active")
        }
        if (!item.has("validity")) {
            item.put("validity", "active")
        }
        if (!item.has("reasonCodes")) {
            item.put("reasonCodes", JSONArray())
        }
        if (!item.has("temperatureAvailable")) {
            item.put(
                "temperatureAvailable",
                item.optDouble("maxTemperatureC", 0.0) != 0.0,
            )
        }
        if (!item.has("powerSampleCount")) {
            item.put("powerSampleCount", item.optInt("sampleCount", 0))
        }
        if (!item.has("currentSampleCount")) {
            item.put("currentSampleCount", item.optInt("sampleCount", 0))
        }
        if (!item.has("notChargingSince")) {
            item.put("notChargingSince", 0L)
        }
        if (!item.has("notChargingLevel")) {
            item.put("notChargingLevel", item.optInt("currentLevel", 0))
        }
        if (!item.has("oemChargeLimitDetected")) {
            item.put("oemChargeLimitDetected", false)
        }
        if (!item.has("oemChargeLimitLevel")) {
            item.put("oemChargeLimitLevel", -1)
        }
        if (!item.has("curvePoints")) {
            item.put("curvePoints", JSONArray())
        }
    }

    private fun migrateCompleted(item: JSONObject) {
        if (!item.has("quality")) {
            item.put(
                "quality",
                if (item.optBoolean("completed", true)) {
                    "completed"
                } else {
                    "uncertain"
                },
            )
        }
        if (!item.has("validity")) {
            item.put(
                "validity",
                legacyValidity(item.optString("quality", "uncertain")),
            )
        }
        if (!item.has("reasonCodes")) {
            item.put("reasonCodes", JSONArray())
        }
        if (!item.has("lastObservedAt")) {
            item.put(
                "lastObservedAt",
                item.optLong("endedAt", item.optLong("startedAt", 0L)),
            )
        }
        if (!item.has("temperatureAvailable")) {
            item.put(
                "temperatureAvailable",
                item.optDouble("maxTemperatureC", 0.0) != 0.0,
            )
        }
        if (!item.has("oemChargeLimitDetected")) {
            item.put("oemChargeLimitDetected", false)
        }
        if (!item.has("oemChargeLimitLevel")) {
            item.put("oemChargeLimitLevel", -1)
        }
        if (!item.has("curvePoints")) {
            item.put("curvePoints", JSONArray())
        }
    }

    private fun legacyValidity(quality: String): String = when (quality) {
        "active" -> "active"
        "completed" -> "valid"
        "interrupted" -> "interrupted"
        else -> "uncertain"
    }

    private fun jsonArrayToStringList(array: JSONArray): List<String> {
        val result = ArrayList<String>(array.length())
        for (index in 0 until array.length()) {
            val value = array.optString(index, "")
            if (value.isNotBlank()) result.add(value)
        }
        return result
    }

    private fun jsonArrayToMapList(
        array: JSONArray,
    ): List<Map<String, Any?>> {
        val result = ArrayList<Map<String, Any?>>(array.length())
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            result.add(
                mapOf(
                    "timestamp" to item.optLong("timestamp", 0L),
                    "level" to item.optInt("level", 0),
                    "isCharging" to item.optBoolean("isCharging", false),
                    "isPlugged" to item.optBoolean("isPlugged", false),
                    "screenStateAvailable" to
                        item.optBoolean("screenStateAvailable", false),
                    "screenInteractive" to
                        item.optBoolean("screenInteractive", false),
                    "temperatureAvailable" to
                        item.optBoolean("temperatureAvailable", false),
                    "temperatureC" to item.optDouble("temperatureC", 0.0),
                    "voltageAvailable" to
                        item.optBoolean("voltageAvailable", false),
                    "voltageV" to item.optDouble("voltageV", 0.0),
                    "currentAvailable" to
                        item.optBoolean("currentAvailable", false),
                    "currentMa" to item.optDouble("currentMa", 0.0),
                    "powerAvailable" to
                        item.optBoolean("powerAvailable", false),
                    "powerW" to item.optDouble("powerW", 0.0),
                ),
            )
        }
        return result
    }

    private fun intValue(
        snapshot: Map<String, Any>,
        key: String,
    ): Int = (snapshot[key] as? Number)?.toInt() ?: 0

    private fun doubleValue(
        snapshot: Map<String, Any>,
        key: String,
    ): Double = (snapshot[key] as? Number)?.toDouble() ?: 0.0

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
