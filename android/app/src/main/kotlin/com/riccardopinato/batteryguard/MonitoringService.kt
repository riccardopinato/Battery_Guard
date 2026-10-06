package com.riccardopinato.batteryguard

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.IBinder

class MonitoringService : Service() {
    private var registered = false
    private var previousPlugged: Boolean? = null

    private val runtimePrefs by lazy {
        getSharedPreferences("battery_guard_runtime", Context.MODE_PRIVATE)
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val snapshot = BatteryInfoReader.read(
                context,
                if (intent.action == Intent.ACTION_BATTERY_CHANGED) intent else null,
            )
            processSnapshot(snapshot)
        }
    }

    override fun onCreate() {
        super.onCreate()
        runtimePrefs.edit()
            .putLong("lastServiceStartAt", System.currentTimeMillis())
            .remove("lastStartFailureAt")
            .apply()
        NotificationHelper.createChannels(this)
        val initial = BatteryInfoReader.read(this)
        startForeground(
            NotificationHelper.MONITOR_NOTIFICATION_ID,
            NotificationHelper.monitorNotification(this, initial),
        )
        registerBatteryReceiver()
        processSnapshot(initial)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!MonitoringPreferences.get(this).enabled) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        processSnapshot(BatteryInfoReader.read(this))
        return START_STICKY
    }

    override fun onDestroy() {
        runtimePrefs.edit()
            .putLong("lastServiceStopAt", System.currentTimeMillis())
            .apply()
        if (registered) {
            try {
                unregisterReceiver(receiver)
            } catch (_: Throwable) {
            }
            registered = false
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerBatteryReceiver() {
        if (registered) return
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
        }
        registerReceiver(receiver, filter)
        registered = true
    }

    private fun processSnapshot(snapshot: Map<String, Any>) {
        val config = MonitoringPreferences.get(this)
        if (!config.enabled) return

        runtimePrefs.edit()
            .putLong("lastBatteryEventAt", System.currentTimeMillis())
            .apply()

        val level = snapshot["level"] as? Int ?: 0
        val temperature =
            (snapshot["temperatureC"] as? Number)?.toDouble() ?: 0.0
        val temperatureAvailable =
            snapshot["temperatureAvailable"] as? Boolean ?: false
        val isCharging = snapshot["isCharging"] as? Boolean ?: false
        val isPlugged = snapshot["isPlugged"] as? Boolean ?: false

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE)
                as android.app.NotificationManager
        manager.notify(
            NotificationHelper.MONITOR_NOTIFICATION_ID,
            NotificationHelper.monitorNotification(this, snapshot),
        )

        HistoryStore.addSample(this, snapshot)
        BatteryHealthStore.record(this, snapshot)
        BatteryGuardWidgetProvider.updateAll(this, snapshot = snapshot)

        val sessionUpdate = ChargingSessionStore.update(
            context = this,
            snapshot = snapshot,
            targetLevel = config.targetLevel,
        )

        if (sessionUpdate.adaptiveTemperatureAlert) {
            deliverSessionAlert(
                type = "adaptiveTemperature",
                title = "Temperatura sopra la tua media",
                message =
                    "Questa ricarica è a ${"%.1f".format(temperature)} °C, circa 4 °C o più sopra la temperatura massima media delle tue sessioni simili (${"%.1f".format(sessionUpdate.baselineMaxTemperatureC)} °C).",
                snapshot = snapshot,
                notificationId = 2108,
            )
        }

        if (sessionUpdate.adaptiveSlowChargingAlert) {
            val rate =
                (sessionUpdate.current?.get("percentPerHour") as? Number)
                    ?.toDouble()
                    ?: 0.0
            deliverSessionAlert(
                type = "adaptiveSlowCharging",
                title = "Ricarica più lenta del solito",
                message =
                    "Velocità attuale circa ${"%.1f".format(rate)} %/h contro una media personale di ${"%.1f".format(sessionUpdate.baselineRate)} %/h con questa sorgente.",
                snapshot = snapshot,
                notificationId = 2107,
            )
        }

        if (sessionUpdate.rapidTemperatureAlert) {
            deliverSessionAlert(
                type = "rapidTemperature",
                title = "Temperatura in rapido aumento",
                message =
                    "La batteria è salita rapidamente fino a ${"%.1f".format(temperature)} °C durante questa ricarica.",
                snapshot = snapshot,
                notificationId = 2105,
            )
        }

        if (sessionUpdate.slowChargingAlert) {
            val rate =
                (sessionUpdate.current?.get("percentPerHour") as? Number)
                    ?.toDouble()
                    ?: 0.0
            deliverSessionAlert(
                type = "slowCharging",
                title = "Ricarica insolitamente lenta",
                message =
                    "Velocità media circa ${"%.1f".format(rate)} %/h. Verifica cavo e alimentatore; alcuni dispositivi possono limitare volontariamente la ricarica.",
                snapshot = snapshot,
                notificationId = 2106,
            )
        }

        var lowAlerted =
            runtimePrefs.getBoolean("lowAlerted", false)
        var targetAlerted =
            runtimePrefs.getBoolean("targetAlerted", false)
        var fullAlerted =
            runtimePrefs.getBoolean("fullAlerted", false)
        var temperatureAlerted =
            runtimePrefs.getBoolean("temperatureAlerted", false)

        if (isPlugged || level >= config.lowLevel + 3) {
            lowAlerted = false
        }
        if (!isPlugged || level <= config.targetLevel - 3) {
            targetAlerted = false
        }
        if (!isPlugged || level < 98) {
            fullAlerted = false
        }
        if (
            !temperatureAvailable ||
            temperature < config.temperatureThresholdC - 2
        ) {
            temperatureAlerted = false
        }

        if (
            config.notifyLow &&
            !isPlugged &&
            level <= config.lowLevel &&
            !lowAlerted &&
            canAttemptAlert(
                "lastLowAlertAt",
                60 * 60 * 1000L,
                NotificationHelper.AlertKind.LOW_BATTERY,
            )
        ) {
            val sent = NotificationHelper.showAlert(
                context = this,
                title = "Batteria al $level%",
                message =
                    "Hai raggiunto il limite inferiore del ${config.lowLevel}%. È un buon momento per mettere il telefono in carica.",
                snapshot = snapshot,
                notificationId = 2110,
                kind = NotificationHelper.AlertKind.LOW_BATTERY,
            )
            if (sent) {
                recordAlertSent("lastLowAlertAt")
                lowAlerted = true
            }
        }

        if (
            isCharging &&
            level >= config.targetLevel &&
            !targetAlerted &&
            canAttemptAlert(
                "lastTargetAlertAt",
                10 * 60 * 1000L,
                NotificationHelper.AlertKind.HIGH_CHARGE,
            )
        ) {
            val sent = NotificationHelper.showAlert(
                context = this,
                title = "Soglia raggiunta: $level%",
                message =
                    if (config.targetLevel < 100) {
                        "La batteria ha raggiunto il ${config.targetLevel}%. Puoi scollegare il caricatore."
                    } else {
                        "La batteria ha raggiunto il 100%."
                    },
                snapshot = snapshot,
                notificationId = 2101,
                kind = NotificationHelper.AlertKind.HIGH_CHARGE,
            )
            if (sent) {
                recordAlertSent("lastTargetAlertAt")
                targetAlerted = true
            }
        }

        if (
            config.notifyFull &&
            isCharging &&
            level >= 100 &&
            !fullAlerted &&
            canAttemptAlert("lastFullAlertAt", 30 * 60 * 1000L)
        ) {
            if (
                NotificationHelper.showAlert(
                    context = this,
                    title = "Carica completa",
                    message =
                        "La batteria è al 100%. Puoi scollegare il caricatore.",
                    snapshot = snapshot,
                    notificationId = 2102,
                )
            ) {
                recordAlertSent("lastFullAlertAt")
                fullAlerted = true
            }
        }

        if (
            temperatureAvailable &&
            temperature >= config.temperatureThresholdC &&
            !temperatureAlerted &&
            canAttemptAlert(
                "lastTemperatureAlertAt",
                30 * 60 * 1000L,
            )
        ) {
            if (
                NotificationHelper.showAlert(
                    context = this,
                    title = "Temperatura batteria elevata",
                    message =
                        "La batteria è a ${"%.1f".format(temperature)} °C. Controlla il telefono e la ricarica.",
                    snapshot = snapshot,
                    notificationId = 2103,
                )
            ) {
                recordAlertSent("lastTemperatureAlertAt")
                temperatureAlerted = true
            }
        }

        val oldPlugged = previousPlugged
        if (
            oldPlugged == true &&
            !isPlugged &&
            config.notifyUnplugged &&
            canAttemptAlert("lastUnplugAlertAt", 5 * 60 * 1000L)
        ) {
            if (
                NotificationHelper.showAlert(
                    context = this,
                    title = "Cavo scollegato",
                    message =
                        "Ricarica interrotta con batteria al $level%.",
                    snapshot = snapshot,
                    notificationId = 2104,
                )
            ) {
                recordAlertSent("lastUnplugAlertAt")
            }
        }
        previousPlugged = isPlugged

        runtimePrefs.edit()
            .putBoolean("lowAlerted", lowAlerted)
            .putBoolean("targetAlerted", targetAlerted)
            .putBoolean("fullAlerted", fullAlerted)
            .putBoolean("temperatureAlerted", temperatureAlerted)
            .apply()
    }

    private fun deliverSessionAlert(
        type: String,
        title: String,
        message: String,
        snapshot: Map<String, Any>,
        notificationId: Int,
    ) {
        if (
            NotificationHelper.showAlert(
                context = this,
                title = title,
                message = message,
                snapshot = snapshot,
                notificationId = notificationId,
            )
        ) {
            ChargingSessionStore.markAlertDelivered(this, type)
        }
    }

    private fun canAttemptAlert(
        key: String,
        cooldownMs: Long,
        kind: NotificationHelper.AlertKind =
            NotificationHelper.AlertKind.GENERAL,
    ): Boolean {
        if (!NotificationHelper.canDeliverAlert(this, kind)) return false
        val now = System.currentTimeMillis()
        val last = runtimePrefs.getLong(key, 0L)
        return last <= 0L || now - last >= cooldownMs
    }

    private fun recordAlertSent(key: String) {
        runtimePrefs.edit()
            .putLong(key, System.currentTimeMillis())
            .apply()
    }

    companion object {
        fun sync(context: Context) {
            val intent = Intent(context, MonitoringService::class.java)
            if (MonitoringPreferences.get(context).enabled) {
                try {
                    context.startForegroundService(intent)
                } catch (_: RuntimeException) {
                    context.getSharedPreferences(
                        "battery_guard_runtime",
                        Context.MODE_PRIVATE,
                    ).edit()
                        .putLong(
                            "lastStartFailureAt",
                            System.currentTimeMillis(),
                        )
                        .apply()
                }
            } else {
                context.stopService(intent)
            }
        }
    }
}
