package com.riccardopinato.batteryguard

import android.os.Build

object DeviceIntelligence {
    fun identity(): Map<String, Any> {
        val modern = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        return linkedMapOf(
            "manufacturer" to clean(Build.MANUFACTURER),
            "brand" to clean(Build.BRAND),
            "model" to clean(Build.MODEL),
            "device" to clean(Build.DEVICE),
            "product" to clean(Build.PRODUCT),
            "hardware" to clean(Build.HARDWARE),
            "board" to clean(Build.BOARD),
            "sdkInt" to Build.VERSION.SDK_INT,
            "androidRelease" to clean(Build.VERSION.RELEASE),
            "sku" to if (modern) clean(Build.SKU) else "",
            "odmSku" to if (modern) clean(Build.ODM_SKU) else "",
            "socManufacturer" to if (modern) clean(Build.SOC_MANUFACTURER) else "",
            "socModel" to if (modern) clean(Build.SOC_MODEL) else "",
        )
    }

    private fun clean(value: String?): String {
        val raw = value.orEmpty().trim()
        return if (
            raw.equals(Build.UNKNOWN, ignoreCase = true) ||
            raw.equals("unknown", ignoreCase = true)
        ) {
            ""
        } else {
            raw
        }
    }
}
