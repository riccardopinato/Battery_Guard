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
                // Receiver already unregistered.
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
            .putLong("lastHeartbeatAt", System.currentTimeMillis())
            .apply()

        val level = snapshot["level"] as? Int ?: 0
        val temperature = (snapshot["temperatureC"] as? Number)?.toDouble() ?: 0.0
        val isCharging = snapshot["isCharging"] as? Boolean ?: false
        val isPlugged = snapshot["isPlugged"] as? Boolean ?: false

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        manager.notify(
            NotificationHelper.MONITOR_NOTIFICATION_ID,
            NotificationHelper.monitorNotification(this, snapshot),
        )

        HistoryStore.addSample(this, snapshot)
        BatteryGuardWidgetProvider.updateAll(this, snapshot = snapshot)

        val sessionUpdate = ChargingSessionStore.update(
            context = this,
            snapshot = snapshot,
            targetLevel = config.targetLevel,
        )

        if (sessionUpdate.adaptiveTemperatureAlert) {
            NotificationHelper.showAlert(
                context = this,
                title = "Temperatura sopra la tua media",
                message = "Questa ricarica è a ${"%.1f".format(temperature)} °C, circa 4 °C o più sopra la temperatura massima media delle tue sessioni simili (${"%.1f".format(sessionUpdate.baselineMaxTemperatureC)} °C).",
                snapshot = snapshot,
                notificationId = 2108,
            )
        }

        if (sessionUpdate.adaptiveSlowChargingAlert) {
            val rate = (sessionUpdate.current?.get("percentPerHour") as? Number)
                ?.toDouble()
                ?: 0.0
            NotificationHelper.showAlert(
                context = this,
                title = "Ricarica più lenta del solito",
                message = "Velocità attuale circa ${"%.1f".format(rate)} %/h contro una media personale di ${"%.1f".format(sessionUpdate.baselineRate)} %/h con questa sorgente.",
                snapshot = snapshot,
                notificationId = 2107,
            )
        }

        if (sessionUpdate.rapidTemperatureAlert) {
            NotificationHelper.showAlert(
                context = this,
                title = "Temperatura in rapido aumento",
                message = "La batteria è salita rapidamente fino a ${"%.1f".format(temperature)} °C durante questa ricarica.",
                snapshot = snapshot,
                notificationId = 2105,
            )
        }

        if (sessionUpdate.slowChargingAlert) {
            val rate = (sessionUpdate.current?.get("percentPerHour") as? Number)
                ?.toDouble()
                ?: 0.0
            NotificationHelper.showAlert(
                context = this,
                title = "Ricarica insolitamente lenta",
                message = "Velocità media circa ${"%.1f".format(rate)} %/h. Verifica cavo e alimentatore; alcuni dispositivi possono limitare volontariamente la ricarica.",
                snapshot = snapshot,
                notificationId = 2106,
            )
        }

        var targetAlerted = runtimePrefs.getBoolean("targetAlerted", false)
        var fullAlerted = runtimePrefs.getBoolean("fullAlerted", false)
        var temperatureAlerted = runtimePrefs.getBoolean("temperatureAlerted", false)

        if (!isPlugged || level <= config.targetLevel - 3) {
            targetAlerted = false
        }
        if (!isPlugged || level < 98) {
            fullAlerted = false
        }
        if (temperature < config.temperatureThresholdC - 2) {
            temperatureAlerted = false
        }

        if (
            isCharging &&
            level >= config.targetLevel &&
            !targetAlerted &&
            canSendAlert("lastTargetAlertAt", 10 * 60 * 1000L)
        ) {
            NotificationHelper.showAlert(
                context = this,
                title = "Soglia raggiunta: ${level}%",
                message = if (config.targetLevel < 100) {
                    "La batteria ha raggiunto il ${config.targetLevel}%. Puoi scollegare il caricatore."
                } else {
                    "La batteria ha raggiunto il 100%."
                },
                snapshot = snapshot,
                notificationId = 2101,
            )
            targetAlerted = true
        }

        if (
            config.notifyFull &&
            isCharging &&
            level >= 100 &&
            !fullAlerted &&
            canSendAlert("lastFullAlertAt", 30 * 60 * 1000L)
        ) {
            NotificationHelper.showAlert(
                context = this,
                title = "Carica completa",
                message = "La batteria è al 100%. Puoi scollegare il caricatore.",
                snapshot = snapshot,
                notificationId = 2102,
            )
            fullAlerted = true
        }

        if (
            temperature >= config.temperatureThresholdC &&
            !temperatureAlerted &&
            canSendAlert("lastTemperatureAlertAt", 30 * 60 * 1000L)
        ) {
            NotificationHelper.showAlert(
                context = this,
                title = "Temperatura batteria elevata",
                message = "La batteria è a ${"%.1f".format(temperature)} °C. Controlla il telefono e la ricarica.",
                snapshot = snapshot,
                notificationId = 2103,
            )
            temperatureAlerted = true
        }

        val oldPlugged = previousPlugged
        if (
            oldPlugged == true &&
            !isPlugged &&
            config.notifyUnplugged &&
            canSendAlert("lastUnplugAlertAt", 5 * 60 * 1000L)
        ) {
            NotificationHelper.showAlert(
                context = this,
                title = "Cavo scollegato",
                message = "Ricarica interrotta con batteria al ${level}%.",
                snapshot = snapshot,
                notificationId = 2104,
            )
        }
        previousPlugged = isPlugged

        runtimePrefs.edit()
            .putBoolean("targetAlerted", targetAlerted)
            .putBoolean("fullAlerted", fullAlerted)
            .putBoolean("temperatureAlerted", temperatureAlerted)
            .apply()
    }

    private fun canSendAlert(
        key: String,
        cooldownMs: Long,
    ): Boolean {
        val now = System.currentTimeMillis()
        val last = runtimePrefs.getLong(key, 0L)
        if (last > 0L && now - last < cooldownMs) {
            return false
        }
        runtimePrefs.edit()
            .putLong(key, now)
            .apply()
        return true
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
