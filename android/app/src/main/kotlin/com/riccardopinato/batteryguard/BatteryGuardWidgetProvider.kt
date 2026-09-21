package com.riccardopinato.batteryguard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class BatteryGuardWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val snapshot = BatteryInfoReader.read(context)
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId, snapshot)
        }
        storeLastUpdate(context)
    }

    companion object {
        private const val WIDGET_PREFS = "battery_guard_widget_runtime"
        private const val LAST_UPDATE = "last_update"
        private const val MIN_BACKGROUND_UPDATE_MS = 60_000L

        const val ACTION_TOGGLE_MONITORING =
            "com.riccardopinato.batteryguard.widget.TOGGLE_MONITORING"
        const val ACTION_CYCLE_TARGET =
            "com.riccardopinato.batteryguard.widget.CYCLE_TARGET"
        const val ACTION_REFRESH =
            "com.riccardopinato.batteryguard.widget.REFRESH"

        fun updateAll(
            context: Context,
            snapshot: Map<String, Any>? = null,
            force: Boolean = false,
        ) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(
                context,
                BatteryGuardWidgetProvider::class.java,
            )
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) return

            val now = System.currentTimeMillis()
            val prefs = context.getSharedPreferences(
                WIDGET_PREFS,
                Context.MODE_PRIVATE,
            )
            val last = prefs.getLong(LAST_UPDATE, 0L)
            if (!force && now - last < MIN_BACKGROUND_UPDATE_MS) return

            val data = snapshot ?: BatteryInfoReader.read(context)
            ids.forEach { appWidgetId ->
                updateWidget(context, manager, appWidgetId, data)
            }
            prefs.edit().putLong(LAST_UPDATE, now).apply()
        }

        private fun storeLastUpdate(context: Context) {
            context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
                .edit()
                .putLong(LAST_UPDATE, System.currentTimeMillis())
                .apply()
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            snapshot: Map<String, Any>,
        ) {
            val config = MonitoringPreferences.get(context)
            val level = (snapshot["level"] as? Number)?.toInt() ?: 0
            val temperature =
                (snapshot["temperatureC"] as? Number)?.toDouble() ?: 0.0
            val status = snapshot["status"]?.toString() ?: "Sconosciuto"
            val plugType = snapshot["plugType"]?.toString() ?: "Nessuno"
            val isPlugged = snapshot["isPlugged"] as? Boolean ?: false

            val views = RemoteViews(
                context.packageName,
                R.layout.battery_guard_widget,
            )
            views.setTextViewText(R.id.widget_level, "$level%")
            views.setProgressBar(
                R.id.widget_progress,
                100,
                level.coerceIn(0, 100),
                false,
            )
            views.setTextViewText(
                R.id.widget_status,
                "${"%.1f".format(temperature)} °C • $status" +
                    if (isPlugged) " • $plugType" else "",
            )
            views.setTextViewText(
                R.id.widget_monitor_button,
                if (config.enabled) "Protezione ON" else "Protezione OFF",
            )
            views.setTextViewText(
                R.id.widget_target_button,
                "Target ${config.targetLevel}%",
            )

            views.setOnClickPendingIntent(
                R.id.widget_monitor_button,
                actionPendingIntent(
                    context,
                    ACTION_TOGGLE_MONITORING,
                    3101,
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_target_button,
                actionPendingIntent(
                    context,
                    ACTION_CYCLE_TARGET,
                    3102,
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_refresh_button,
                actionPendingIntent(
                    context,
                    ACTION_REFRESH,
                    3103,
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_root,
                openAppPendingIntent(context),
            )

            manager.updateAppWidget(appWidgetId, views)
        }

        private fun actionPendingIntent(
            context: Context,
            action: String,
            requestCode: Int,
        ): PendingIntent {
            val intent = Intent(
                context,
                WidgetActionReceiver::class.java,
            ).setAction(action)
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun openAppPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                3104,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
