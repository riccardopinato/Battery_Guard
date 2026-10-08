package com.riccardopinato.batteryguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object ChargeTestStore {
    private const val FILE = "battery_guard_charge_tests"
    private const val KEY = "tests"
    private const val MAX_TESTS = 50
    private val lock = Any()

    fun getAll(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(KEY, null))
            val result = ArrayList<Map<String, Any?>>(array.length())
            for (index in array.length() - 1 downTo 0) {
                val item = array.optJSONObject(index) ?: continue
                result.add(toMap(item))
            }
            return result
        }
    }

    fun add(context: Context, values: Map<*, *>) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(KEY, null))
            val item = JSONObject()
            for ((key, value) in values) {
                if (key is String && value != null) {
                    item.put(key, value)
                }
            }
            array.put(item)
            val trimmed = JSONArray()
            val start = (array.length() - MAX_TESTS).coerceAtLeast(0)
            for (index in start until array.length()) {
                trimmed.put(array.get(index))
            }
            prefs.edit().putString(KEY, trimmed.toString()).apply()
        }
    }

    fun clear(context: Context) {
        synchronized(lock) {
            context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
                .edit()
                .remove(KEY)
                .apply()
        }
    }

    private fun toMap(item: JSONObject): Map<String, Any?> = mapOf(
        "id" to item.optString("id", ""),
        "profileId" to item.optString("profileId", ""),
        "label" to item.optString("label", "Charge Test"),
        "chargerName" to item.optString("chargerName", ""),
        "cableName" to item.optString("cableName", ""),
        "startedAt" to item.optLong("startedAt", 0L),
        "endedAt" to item.optLong("endedAt", 0L),
        "startLevel" to item.optInt("startLevel", 0),
        "endLevel" to item.optInt("endLevel", 0),
        "averagePowerW" to item.optDouble("averagePowerW", 0.0),
        "peakPowerW" to item.optDouble("peakPowerW", item.optDouble("averagePowerW", 0.0)),
        "averageCurrentMa" to item.optDouble("averageCurrentMa", 0.0),
        "averageVoltageV" to item.optDouble("averageVoltageV", 0.0),
        "startTemperatureC" to item.optDouble("startTemperatureC", 0.0),
        "averageTemperatureC" to item.optDouble("averageTemperatureC", 0.0),
        "maxTemperatureC" to item.optDouble("maxTemperatureC", 0.0),
        "temperatureAvailable" to item.optBoolean(
            "temperatureAvailable",
            item.optDouble("maxTemperatureC", 0.0) > 0.0,
        ),
        "samples" to item.optInt("samples", 0),
        "source" to item.optString("source", "unknown"),
        "confidence" to item.optString("confidence", "low"),
        "powerCoefficientOfVariation" to
            item.optDouble("powerCoefficientOfVariation", 0.0),
        "powerDropCount" to item.optInt("powerDropCount", 0),
        "stressScore" to item.optDouble("stressScore", 0.0),
        "highSocMinutes" to item.optDouble("highSocMinutes", 0.0),
        "hotMinutes" to item.optDouble("hotMinutes", 0.0),
        "veryHotMinutes" to item.optDouble("veryHotMinutes", 0.0),
        "highVoltageMinutes" to item.optDouble("highVoltageMinutes", 0.0),
    )

    private fun parseArray(raw: String?): JSONArray {
        if (raw.isNullOrBlank()) return JSONArray()
        return try {
            JSONArray(raw)
        } catch (_: Throwable) {
            JSONArray()
        }
    }
}
