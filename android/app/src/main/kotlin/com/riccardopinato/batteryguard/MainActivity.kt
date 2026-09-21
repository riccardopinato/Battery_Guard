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
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controlChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSnapshot" -> result.success(BatteryInfoReader.read(this))
                    "getConfig" -> result.success(MonitoringPreferences.asMap(this))
                    "setConfig" -> {
                        @Suppress("UNCHECKED_CAST")
                        val values = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        MonitoringPreferences.save(this, values)
                        MonitoringService.sync(this)
                        result.success(null)
                    }
                    "getHistory" -> result.success(HistoryStore.getAll(this))
                    "getChargingSessions" -> result.success(ChargingSessionStore.getAll(this))
                    "getCurrentChargingSession" -> result.success(ChargingSessionStore.getCurrent(this))
                    "clearHistory" -> {
                        HistoryStore.clear(this)
                        ChargingSessionStore.clearCompleted(this)
                        result.success(null)
                    }
                    "hasNotificationPermission" -> result.success(hasNotificationPermission())
                    "requestNotificationPermission" -> requestNotificationPermission(result)
                    "openBatterySettings" -> {
                        openBatterySettings()
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
                // Try the next system settings page.
            }
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
                        if (intent.action == Intent.ACTION_BATTERY_CHANGED) intent else null,
                    ),
                )
            }
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
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
                    // Ignore duplicated cleanup.
                }
                registered = false
            }
            sink = null
        }
    }
}
