package com.riccardopinato.batteryguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object HistoryStore {
    private const val FILE = "battery_guard_history"
    private const val KEY = "entries"
    private const val LAST_SAMPLE = "last_sample_time"
    private const val MAX_ENTRIES = 220
    private const val SAMPLE_INTERVAL_MS = 15 * 60 * 1000L
    private val lock = Any()

    fun addAlert(
        context: Context,
        title: String,
        message: String,
        snapshot: Map<String, Any>,
    ) {
        add(
            context = context,
            type = "alert",
            title = title,
            message = message,
            snapshot = snapshot,
        )
    }

    fun addSample(context: Context, snapshot: Map<String, Any>) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val last = prefs.getLong(LAST_SAMPLE, 0L)
            if (now - last < SAMPLE_INTERVAL_MS) return
            prefs.edit().putLong(LAST_SAMPLE, now).apply()
        }
        add(
            context = context,
            type = "sample",
            title = "",
            message = "",
            snapshot = snapshot,
        )
    }

    private fun add(
        context: Context,
        type: String,
        title: String,
        message: String,
        snapshot: Map<String, Any>,
    ) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parse(prefs.getString(KEY, null))
            val item = JSONObject().apply {
                put("type", type)
                put("title", title)
                put("message", message)
                put("level", snapshot["level"] ?: 0)
                put("temperatureC", snapshot["temperatureC"] ?: 0.0)
                put("isCharging", snapshot["isCharging"] ?: false)
                put("timestamp", System.currentTimeMillis())
            }
            array.put(item)

            val trimmed = JSONArray()
            val start = (array.length() - MAX_ENTRIES).coerceAtLeast(0)
            for (i in start until array.length()) {
                trimmed.put(array.get(i))
            }
            prefs.edit().putString(KEY, trimmed.toString()).apply()
        }
    }

    fun getAll(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parse(prefs.getString(KEY, null))
            val result = ArrayList<Map<String, Any?>>(array.length())
            for (i in array.length() - 1 downTo 0) {
                val item = array.optJSONObject(i) ?: continue
                result.add(
                    mapOf(
                        "type" to item.optString("type", "sample"),
                        "title" to item.optString("title", ""),
                        "message" to item.optString("message", ""),
                        "level" to item.optInt("level", 0),
                        "temperatureC" to item.optDouble("temperatureC", 0.0),
                        "isCharging" to item.optBoolean("isCharging", false),
                        "timestamp" to item.optLong("timestamp", 0L),
                    ),
                )
            }
            return result
        }
    }

    fun clear(context: Context) {
        synchronized(lock) {
            context.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().clear().apply()
        }
    }

    private fun parse(raw: String?): JSONArray {
        if (raw.isNullOrBlank()) return JSONArray()
        return try {
            JSONArray(raw)
        } catch (_: Throwable) {
            JSONArray()
        }
    }
}
