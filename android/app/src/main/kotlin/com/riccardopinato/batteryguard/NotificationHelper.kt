package com.riccardopinato.batteryguard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color

object NotificationHelper {
    const val MONITOR_NOTIFICATION_ID = 1001
    private const val MONITOR_CHANNEL = "battery_guard_monitor"
    private const val ALERT_CHANNEL = "battery_guard_alerts"
    private const val QUIET_CHANNEL = "battery_guard_quiet_alerts"

    fun createChannels(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val monitor = NotificationChannel(
            MONITOR_CHANNEL,
            "Monitoraggio Battery Guard",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Notifica persistente mentre Battery Guard controlla la batteria"
            setShowBadge(false)
        }

        val alerts = NotificationChannel(
            ALERT_CHANNEL,
            "Avvisi batteria",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Avvisi di soglia, temperatura e ricarica"
            enableVibration(true)
        }

        val quiet = NotificationChannel(
            QUIET_CHANNEL,
            "Avvisi silenziosi notturni",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Avvisi visibili ma silenziosi durante la modalità notte"
            setSound(null, null)
            enableVibration(false)
        }

        manager.createNotificationChannels(listOf(monitor, alerts, quiet))
    }

    fun monitorNotification(context: Context, snapshot: Map<String, Any>): Notification {
        createChannels(context)
        val level = snapshot["level"] as? Int ?: 0
        val temperature = (snapshot["temperatureC"] as? Number)?.toDouble() ?: 0.0
        val status = snapshot["status"]?.toString() ?: "Monitoraggio"

        return Notification.Builder(context, MONITOR_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_battery_guard)
            .setContentTitle("Battery Guard attivo")
            .setContentText("$level% • ${"%.1f".format(temperature)} °C • $status")
            .setContentIntent(openAppIntent(context))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setColor(Color.rgb(33, 163, 102))
            .build()
    }

    fun showAlert(
        context: Context,
        title: String,
        message: String,
        snapshot: Map<String, Any>,
        notificationId: Int,
        saveToHistory: Boolean = true,
    ) {
        createChannels(context)
        val quiet = MonitoringPreferences.isQuietNow(context)
        val channel = if (quiet) QUIET_CHANNEL else ALERT_CHANNEL

        val notification = Notification.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_battery_guard)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setContentIntent(openAppIntent(context))
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setColor(Color.rgb(33, 163, 102))
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)

        if (saveToHistory) {
            HistoryStore.addAlert(context, title, message, snapshot)
        }
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
