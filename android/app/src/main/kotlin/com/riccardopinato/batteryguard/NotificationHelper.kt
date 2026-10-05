package com.riccardopinato.batteryguard

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build

object NotificationHelper {
    const val MONITOR_NOTIFICATION_ID = 1001
    const val MONITOR_CHANNEL = "battery_guard_monitor"
    const val ALERT_CHANNEL = "battery_guard_alerts"
    const val QUIET_CHANNEL = "battery_guard_quiet_alerts"

    data class DeliveryState(
        val permissionGranted: Boolean,
        val globallyEnabled: Boolean,
        val monitorChannelEnabled: Boolean,
        val alertChannelEnabled: Boolean,
        val quietChannelEnabled: Boolean,
    ) {
        val alertReady: Boolean
            get() = permissionGranted && globallyEnabled && alertChannelEnabled

        val monitorReady: Boolean
            get() = permissionGranted && globallyEnabled && monitorChannelEnabled
    }

    fun createChannels(context: Context) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        val monitor = NotificationChannel(
            MONITOR_CHANNEL,
            "Monitoraggio Battery Guard",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description =
                "Notifica persistente mentre Battery Guard controlla la batteria"
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
            description =
                "Avvisi visibili ma silenziosi durante la modalità notte"
            setSound(null, null)
            enableVibration(false)
        }

        manager.createNotificationChannels(listOf(monitor, alerts, quiet))
    }

    fun deliveryState(context: Context): DeliveryState {
        createChannels(context)
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        val permissionGranted =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED

        fun channelEnabled(id: String): Boolean {
            val channel = manager.getNotificationChannel(id)
            return channel != null &&
                channel.importance != NotificationManager.IMPORTANCE_NONE
        }

        return DeliveryState(
            permissionGranted = permissionGranted,
            globallyEnabled = manager.areNotificationsEnabled(),
            monitorChannelEnabled = channelEnabled(MONITOR_CHANNEL),
            alertChannelEnabled = channelEnabled(ALERT_CHANNEL),
            quietChannelEnabled = channelEnabled(QUIET_CHANNEL),
        )
    }

    fun canDeliverAlert(context: Context): Boolean {
        val state = deliveryState(context)
        if (!state.permissionGranted || !state.globallyEnabled) return false
        return if (MonitoringPreferences.isQuietNow(context)) {
            state.quietChannelEnabled
        } else {
            state.alertChannelEnabled
        }
    }

    fun monitorNotification(
        context: Context,
        snapshot: Map<String, Any>,
    ): Notification {
        createChannels(context)
        val level = snapshot["level"] as? Int ?: 0
        val temperature =
            (snapshot["temperatureC"] as? Number)?.toDouble() ?: 0.0
        val temperatureAvailable =
            snapshot["temperatureAvailable"] as? Boolean ?: false
        val status = snapshot["status"]?.toString() ?: "Monitoraggio"
        val temperatureText =
            if (temperatureAvailable) {
                " • ${"%.1f".format(temperature)} °C"
            } else {
                ""
            }

        return Notification.Builder(context, MONITOR_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_battery_guard)
            .setContentTitle("Battery Guard attivo")
            .setContentText("$level%$temperatureText • $status")
            .setContentIntent(openAppIntent(context))
            .addAction(
                quickAction(
                    context,
                    "Target 80%",
                    WidgetActionReceiver.ACTION_SET_TARGET_80,
                    3301,
                ),
            )
            .addAction(
                quickAction(
                    context,
                    "Disattiva",
                    WidgetActionReceiver.ACTION_DISABLE_MONITORING,
                    3302,
                ),
            )
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
    ): Boolean {
        createChannels(context)
        if (!canDeliverAlert(context)) {
            recordDeliveryFailure(context, "notification_not_deliverable")
            return false
        }

        val quiet = MonitoringPreferences.isQuietNow(context)
        val channel = if (quiet) QUIET_CHANNEL else ALERT_CHANNEL

        return try {
            val notification = Notification.Builder(context, channel)
                .setSmallIcon(R.drawable.ic_stat_battery_guard)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(Notification.BigTextStyle().bigText(message))
                .setContentIntent(openAppIntent(context))
                .addAction(
                    quickAction(
                        context,
                        "Target 80%",
                        WidgetActionReceiver.ACTION_SET_TARGET_80,
                        3401 + notificationId,
                    ),
                )
                .addAction(
                    quickAction(
                        context,
                        "Disattiva",
                        WidgetActionReceiver.ACTION_DISABLE_MONITORING,
                        3501 + notificationId,
                    ),
                )
                .setAutoCancel(true)
                .setCategory(Notification.CATEGORY_ALARM)
                .setColor(Color.rgb(33, 163, 102))
                .build()

            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager
            manager.notify(notificationId, notification)

            context.getSharedPreferences(
                "battery_guard_runtime",
                Context.MODE_PRIVATE,
            ).edit()
                .putLong("lastSuccessfulAlertAttemptAt", System.currentTimeMillis())
                .remove("lastAlertFailureReason")
                .apply()

            if (saveToHistory) {
                HistoryStore.addAlert(context, title, message, snapshot)
            }
            true
        } catch (_: Throwable) {
            recordDeliveryFailure(context, "notification_manager_failure")
            false
        }
    }

    private fun recordDeliveryFailure(
        context: Context,
        reason: String,
    ) {
        context.getSharedPreferences(
            "battery_guard_runtime",
            Context.MODE_PRIVATE,
        ).edit()
            .putLong("lastAlertFailureAt", System.currentTimeMillis())
            .putString("lastAlertFailureReason", reason)
            .apply()
    }

    private fun quickAction(
        context: Context,
        title: String,
        action: String,
        requestCode: Int,
    ): Notification.Action {
        val intent = Intent(
            context,
            WidgetActionReceiver::class.java,
        ).setAction(action)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(
            R.drawable.ic_stat_battery_guard,
            title,
            pendingIntent,
        ).build()
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
