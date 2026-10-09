package com.riccardopinato.batteryguard

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class MonitoringService : Service() {
    private var registered = false
    private var previousPlugged: Boolean? = null
    private val samplingHandler = Handler(Looper.getMainLooper())
    private val samplingRunnable = object : Runnable {
        override fun run() {
            if (MonitoringPreferences.get(this@MonitoringService).enabled) {
                processSnapshot(BatteryInfoReader.read(this@MonitoringService))
                samplingHandler.postDelayed(this, PERIODIC_SAMPLE_MS)
            }
        }
    }

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
        samplingHandler.removeCallbacks(samplingRunnable)
        samplingHandler.postDelayed(samplingRunnable, PERIODIC_SAMPLE_MS)
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
        samplingHandler.removeCallbacks(samplingRunnable)
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
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
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
        IdleDrainStore.record(this, snapshot)
        val protectionState = ChargeProtectionManager.observe(
            context = this,
            snapshot = snapshot,
            enabled = config.chargeProtectionEnabled,
            targetLevel = config.targetLevel,
        )
        val protectionCapability = ChargeProtectionManager.capability(this)
        if (
            config.chargeProtectionEnabled &&
            level >= config.targetLevel &&
            isCharging &&
            protectionCapability["supportsDirectControl"] == true &&
            protectionState["verification"] == "still_charging"
        ) {
            val attempt = ChargeProtectionManager.applyLimit(
                this,
                config.targetLevel,
            )
            if (attempt["commandSent"] == true) {
                samplingHandler.postDelayed(
                    {
                        ChargeProtectionManager.observe(
                            context = this,
                            snapshot = BatteryInfoReader.read(this),
                            enabled = true,
                            targetLevel = config.targetLevel,
                        )
                    },
                    2_000L,
                )
            }
        }
        BatteryGuardWidgetProvider.updateAll(this, snapshot = snapshot)

        val sessionUpdate = ChargingSessionStore.update(
            context = this,
            snapshot = snapshot,
            targetLevel = config.targetLevel,
        )

        if (sessionUpdate.adaptiveTemperatureAlert) {
            deliverSessionAlert(
                type = "adaptiveTemperature",
                title = NativeStrings.adaptiveTemperatureTitle(this),
                message = NativeStrings.adaptiveTemperatureMessage(
                    this,
                    temperature,
                    sessionUpdate.baselineMaxTemperatureC,
                ),
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
                title = NativeStrings.adaptiveSlowTitle(this),
                message = NativeStrings.adaptiveSlowMessage(
                    this,
                    rate,
                    sessionUpdate.baselineRate,
                ),
                snapshot = snapshot,
                notificationId = 2107,
            )
        }

        if (sessionUpdate.rapidTemperatureAlert) {
            deliverSessionAlert(
                type = "rapidTemperature",
                title = NativeStrings.rapidTemperatureTitle(this),
                message = NativeStrings.rapidTemperatureMessage(
                    this,
                    temperature,
                ),
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
                title = NativeStrings.slowChargingTitle(this),
                message = NativeStrings.slowChargingMessage(this, rate),
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
                title = NativeStrings.lowTitle(this, level),
                message = NativeStrings.lowMessage(this, config.lowLevel),
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
                title = NativeStrings.highTitle(this, level),
                message = NativeStrings.highMessage(
                    this,
                    config.targetLevel,
                ),
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
            config.targetLevel < 100 &&
            isCharging &&
            level >= 100 &&
            !fullAlerted &&
            canAttemptAlert("lastFullAlertAt", 30 * 60 * 1000L)
        ) {
            if (
                NotificationHelper.showAlert(
                    context = this,
                    title = NativeStrings.fullTitle(this),
                    message = NativeStrings.fullMessage(this),
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
                    title = NativeStrings.temperatureTitle(this),
                    message = NativeStrings.temperatureMessage(
                        this,
                        temperature,
                    ),
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
                    title = NativeStrings.unplugTitle(this),
                    message = NativeStrings.unplugMessage(this, level),
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
        private const val PERIODIC_SAMPLE_MS = 60 * 1000L

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
