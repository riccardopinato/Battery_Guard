package com.riccardopinato.batteryguard

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object ChargingSetupStore {
    private const val FILE = "battery_guard_charging_setups"
    private const val KEY = "setups"
    private const val MAX_SETUPS = 30
    private val lock = Any()

    fun getAll(context: Context): List<Map<String, Any?>> {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(KEY, null))
            val result = ArrayList<Map<String, Any?>>(array.length())
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                result.add(toMap(item))
            }
            return result.sortedByDescending {
                (it["updatedAt"] as? Number)?.toLong() ?: 0L
            }
        }
    }

    fun save(context: Context, values: Map<*, *>) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(KEY, null))
            val id = values["id"]?.toString().orEmpty()
            if (id.isBlank()) return

            val next = JSONArray()
            var replaced = false
            for (index in 0 until array.length()) {
                val existing = array.optJSONObject(index) ?: continue
                if (existing.optString("id", "") == id) {
                    next.put(fromMap(values))
                    replaced = true
                } else {
                    next.put(existing)
                }
            }
            if (!replaced) next.put(fromMap(values))

            val trimmed = JSONArray()
            val start = (next.length() - MAX_SETUPS).coerceAtLeast(0)
            for (index in start until next.length()) {
                trimmed.put(next.get(index))
            }
            prefs.edit().putString(KEY, trimmed.toString()).apply()
        }
    }

    fun delete(context: Context, id: String) {
        if (id.isBlank()) return
        synchronized(lock) {
            val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            val array = parseArray(prefs.getString(KEY, null))
            val next = JSONArray()
            for (index in 0 until array.length()) {
                val existing = array.optJSONObject(index) ?: continue
                if (existing.optString("id", "") != id) {
                    next.put(existing)
                }
            }
            prefs.edit().putString(KEY, next.toString()).apply()
        }
    }

    private fun fromMap(values: Map<*, *>): JSONObject {
        val item = JSONObject()
        for ((key, value) in values) {
            if (key is String && value != null) {
                item.put(key, value)
            }
        }
        return item
    }

    private fun toMap(item: JSONObject): Map<String, Any?> = mapOf(
        "id" to item.optString("id", ""),
        "name" to item.optString("name", "Charging setup"),
        "chargerName" to item.optString("chargerName", ""),
        "cableName" to item.optString("cableName", ""),
        "source" to item.optString("source", "unknown"),
        "notes" to item.optString("notes", ""),
        "createdAt" to item.optLong("createdAt", 0L),
        "updatedAt" to item.optLong("updatedAt", 0L),
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
