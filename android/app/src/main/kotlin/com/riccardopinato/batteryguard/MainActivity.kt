package com.riccardopinato.batteryguard

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val controlChannel = "com.riccardopinato.batteryguard/control"
    private val eventChannel = "com.riccardopinato.batteryguard/events"
    private val notificationRequestCode = 4401
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NotificationHelper.createChannels(this)
        if (MonitoringPreferences.get(this).enabled) {
            MonitoringService.sync(this)
        }
        BatteryGuardWidgetProvider.updateAll(this, force = true)
        QuickSettingsTileService.requestRefresh(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controlChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSnapshot" -> result.success(BatteryInfoReader.read(this))
                    "getConfig" -> result.success(MonitoringPreferences.asMap(this))
                    "setConfig" -> {
                        val values =
                            call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        MonitoringPreferences.save(this, values)
                        MonitoringService.sync(this)
                        BatteryGuardWidgetProvider.updateAll(this, force = true)
                        QuickSettingsTileService.requestRefresh(this)
                        result.success(null)
                    }
                    "getHistory" -> result.success(HistoryStore.getAll(this))
                    "getChargingSessions" ->
                        result.success(ChargingSessionStore.getAll(this))
                    "getCurrentChargingSession" ->
                        result.success(ChargingSessionStore.getCurrent(this))
                    "clearHistory" -> {
                        HistoryStore.clear(this)
                        ChargingSessionStore.clearCompleted(this)
                        result.success(null)
                    }
                    "hasNotificationPermission" ->
                        result.success(hasNotificationPermission())
                    "requestNotificationPermission" ->
                        requestNotificationPermission(result)
                    "getReliabilityStatus" ->
                        result.success(reliabilityStatus())
                    "isOnboardingComplete" ->
                        result.success(appStatePrefs().getBoolean("onboardingComplete", false))
                    "setOnboardingComplete" -> {
                        val value = call.arguments as? Boolean ?: true
                        appStatePrefs().edit()
                            .putBoolean("onboardingComplete", value)
                            .apply()
                        result.success(null)
                    }
                    "repairMonitoring" -> {
                        MonitoringService.sync(this)
                        result.success(null)
                    }
                    "openBatterySettings" -> {
                        openBatterySettings()
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    "testAlert" -> {
                        val snapshot = BatteryInfoReader.read(this)
                        NotificationHelper.showAlert(
                            context = this,
                            title = "Battery Guard funziona",
                            message = "Questo è un avviso di prova.",
                            snapshot = snapshot,
                            notificationId = 2199,
                            saveToHistory = false,
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannel)
            .setStreamHandler(BatteryStreamHandler(this))
    }

    private fun appStatePrefs() =
        getSharedPreferences("battery_guard_app_state", Context.MODE_PRIVATE)

    private fun reliabilityStatus(): Map<String, Any> {
        val config = MonitoringPreferences.get(this)
        val runtime = getSharedPreferences(
            "battery_guard_runtime",
            Context.MODE_PRIVATE,
        )
        val heartbeat = runtime.getLong("lastHeartbeatAt", 0L)
        val failure = runtime.getLong("lastStartFailureAt", 0L)
        val heartbeatFresh =
            heartbeat > 0L &&
                System.currentTimeMillis() - heartbeat < 30 * 60 * 1000L

        val powerManager =
            getSystemService(Context.POWER_SERVICE) as PowerManager
        val optimizationIgnored =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                powerManager.isIgnoringBatteryOptimizations(packageName)
            } else {
                true
            }

        return mapOf(
            "notificationsGranted" to hasNotificationPermission(),
            "batteryOptimizationIgnored" to optimizationIgnored,
            "monitoringRequested" to config.enabled,
            "serviceHealthy" to (!config.enabled || heartbeatFresh),
            "lastHeartbeatAt" to heartbeat,
            "lastStartFailureAt" to failure,
            "manufacturer" to
                Build.MANUFACTURER.replaceFirstChar {
                    if (it.isLowerCase()) it.titlecase() else it.toString()
                },
        )
    }

    private fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            hasNotificationPermission()
        ) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationRequestCode) {
            val granted =
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun openBatterySettings() {
        val candidates = listOf(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            },
        )
        for (intent in candidates) {
            try {
                startActivity(intent)
                return
            } catch (_: Throwable) {
            }
        }
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        try {
            startActivity(intent)
        } catch (_: Throwable) {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
        }
    }

    private class BatteryStreamHandler(
        private val context: Context,
    ) : EventChannel.StreamHandler {
        private var sink: EventChannel.EventSink? = null
        private var registered = false

        private val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                sink?.success(
                    BatteryInfoReader.read(
                        context,
                        if (intent.action == Intent.ACTION_BATTERY_CHANGED) {
                            intent
                        } else {
                            null
                        },
                    ),
                )
            }
        }

        override fun onListen(
            arguments: Any?,
            events: EventChannel.EventSink?,
        ) {
            sink = events
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_BATTERY_CHANGED)
                addAction(Intent.ACTION_POWER_CONNECTED)
                addAction(Intent.ACTION_POWER_DISCONNECTED)
            }
            if (!registered) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.registerReceiver(
                        receiver,
                        filter,
                        Context.RECEIVER_NOT_EXPORTED,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    context.registerReceiver(receiver, filter)
                }
                registered = true
            }
            sink?.success(BatteryInfoReader.read(context))
        }

        override fun onCancel(arguments: Any?) {
            if (registered) {
                try {
                    context.unregisterReceiver(receiver)
                } catch (_: Throwable) {
                }
                registered = false
            }
            sink = null
        }
    }
}
