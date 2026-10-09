package com.riccardopinato.batteryguard

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

object ChargeProtectionManager {
    private const val FILE = "battery_guard_charge_protection_runtime"

    fun capability(context: Context): Map<String, Any> {
        val manufacturer = Build.MANUFACTURER.orEmpty().trim()
        val brand = Build.BRAND.orEmpty().trim()
        val model = Build.MODEL.orEmpty().trim()
        val oem = "$manufacturer $brand".lowercase()
        val modelLower = model.lowercase()

        val pixelLimit =
            (oem.contains("google") || brand.equals("google", true)) &&
                supportsPixel80(modelLower) &&
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM

        return when {
            pixelLimit -> capabilityMap(
                adapterId = "google_pixel_charging_optimization",
                mode = "system_setting",
                systemLimitAvailable = true,
                supportedTargets = listOf(80),
                confidence = "high",
                guideCode = "pixel_80",
                manufacturer = manufacturer,
                model = model,
            )
            oem.contains("samsung") -> capabilityMap(
                adapterId = "samsung_battery_protection",
                mode = "system_setting",
                systemLimitAvailable = true,
                supportedTargets = listOf(80, 85, 90, 95),
                confidence = "medium",
                guideCode = "samsung_battery_protection",
                manufacturer = manufacturer,
                model = model,
            )
            oem.contains("xiaomi") ||
                oem.contains("redmi") ||
                oem.contains("poco") -> capabilityMap(
                adapterId = "xiaomi_battery_protection",
                mode = "system_setting",
                systemLimitAvailable = true,
                supportedTargets = listOf(80),
                confidence = "medium",
                guideCode = "xiaomi_battery_protection",
                manufacturer = manufacturer,
                model = model,
            )
            else -> capabilityMap(
                adapterId = "generic_android",
                mode = "alert_only",
                systemLimitAvailable = false,
                supportedTargets = emptyList(),
                confidence = "high",
                guideCode = "generic_alert_only",
                manufacturer = manufacturer,
                model = model,
            )
        }
    }

    fun applyLimit(context: Context, targetLevel: Int): Map<String, Any> {
        val capability = capability(context)
        val direct = capability["supportsDirectControl"] as? Boolean ?: false
        if (!direct) {
            return linkedMapOf(
                "commandSent" to false,
                "requiresUserAction" to
                    ((capability["mode"] as? String) == "system_setting"),
                "verification" to "unsupported",
                "targetLevel" to targetLevel.coerceIn(70, 100),
            )
        }

        return linkedMapOf(
            "commandSent" to false,
            "requiresUserAction" to false,
            "verification" to "failed",
            "targetLevel" to targetLevel.coerceIn(70, 100),
        )
    }

    fun observe(
        context: Context,
        snapshot: Map<String, Any>,
        enabled: Boolean,
        targetLevel: Int,
    ): Map<String, Any> {
        val target = targetLevel.coerceIn(70, 100)
        val level = (snapshot["level"] as? Number)?.toInt() ?: -1
        val isCharging = snapshot["isCharging"] as? Boolean ?: false
        val isPlugged = snapshot["isPlugged"] as? Boolean ?: false

        val verification = when {
            !enabled -> "disabled"
            target >= 100 -> "not_applicable"
            !isPlugged -> "unplugged"
            level < 0 -> "pending"
            level < target -> "below_target"
            !isCharging -> "verified_stopped"
            else -> "still_charging"
        }
        val now = System.currentTimeMillis()
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean("enabled", enabled)
            .putInt("targetLevel", target)
            .putString("verification", verification)
            .putInt("observedLevel", level)
            .putBoolean("observedIsCharging", isCharging)
            .putBoolean("observedIsPlugged", isPlugged)
            .putLong(
                "verifiedAt",
                if (verification == "verified_stopped") now
                else prefs.getLong("verifiedAt", 0L),
            )
            .apply()

        return state(context, target)
    }

    fun state(context: Context, targetLevel: Int): Map<String, Any> {
        val config = MonitoringPreferences.get(context)
        val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        val capability = capability(context)
        return linkedMapOf(
            "enabled" to config.chargeProtectionEnabled,
            "targetLevel" to targetLevel.coerceIn(70, 100),
            "verification" to
                (prefs.getString(
                    "verification",
                    if (config.chargeProtectionEnabled) "pending" else "disabled",
                ) ?: "pending"),
            "observedLevel" to prefs.getInt("observedLevel", -1),
            "observedIsCharging" to
                prefs.getBoolean("observedIsCharging", false),
            "observedIsPlugged" to
                prefs.getBoolean("observedIsPlugged", false),
            "verifiedAt" to prefs.getLong("verifiedAt", 0L),
            "commandSent" to false,
            "requiresUserAction" to
                config.chargeProtectionEnabled &&
                    ((capability["mode"] as? String) == "system_setting"),
        )
    }

    fun verifyNow(context: Context): Map<String, Any> {
        val config = MonitoringPreferences.get(context)
        return observe(
            context = context,
            snapshot = BatteryInfoReader.read(context),
            enabled = config.chargeProtectionEnabled,
            targetLevel = config.targetLevel,
        )
    }

    fun openSystemBatterySettings(context: Context): Boolean {
        val intents = listOf(
            Intent(Settings.ACTION_SETTINGS),
            Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS),
        )
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    return true
                }
            } catch (_: Throwable) {
            }
        }
        return false
    }

    private fun capabilityMap(
        adapterId: String,
        mode: String,
        systemLimitAvailable: Boolean,
        supportedTargets: List<Int>,
        confidence: String,
        guideCode: String,
        manufacturer: String,
        model: String,
    ): Map<String, Any> = linkedMapOf(
        "adapterId" to adapterId,
        "mode" to mode,
        "supportsDirectControl" to false,
        "systemLimitAvailable" to systemLimitAvailable,
        "supportedTargets" to supportedTargets,
        "confidence" to confidence,
        "guideCode" to guideCode,
        "manufacturer" to manufacturer,
        "model" to model,
    )

    private fun supportsPixel80(model: String): Boolean {
        if (model.contains("pixel 6a")) return true
        if (model.contains("pixel fold")) return true
        val match = Regex("""pixel\s+(\d+)""").find(model)
        val generation = match?.groupValues?.getOrNull(1)?.toIntOrNull()
        return generation != null && generation >= 7
    }
}
