package de.linefm.app

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Freigaben des Radioweckers (Dart-Seite: services/alarm/alarm_permissions.dart).
 *
 * - SCHEDULE_EXACT_ALARM (Android 12+): genaue Alarme.
 * - USE_FULL_SCREEN_INTENT (Android 14+): Vollbild-Wecken.
 * - POST_NOTIFICATIONS (Android 13+): Weck-Benachrichtigung.
 * - Merkzeichen von [TimeChangeReceiver]: Zeitzone/Uhrzeit hat sich geaendert.
 */
object AlarmChannel {
    const val NAME = "de.linefm.app/alarm_android"
    private const val NOTIFICATION_REQUEST = 4711

    /** Der Aufrufer loest den Handler in cleanUpFlutterEngine wieder. */
    fun register(engine: FlutterEngine, activity: Activity): MethodChannel {
        // Reine Abfragen laufen ueber den Anwendungskontext, nicht ueber die Activity.
        val app = activity.applicationContext
        return MethodChannel(engine.dartExecutor.binaryMessenger, NAME).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "canScheduleExactAlarms" -> {
                        val manager = app.getSystemService(AlarmManager::class.java)
                        result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms())
                    }
                    "openExactAlarmSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            open(activity, Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        }
                        result.success(null)
                    }
                    "canUseFullScreenIntent" -> {
                        val manager = app.getSystemService(NotificationManager::class.java)
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ||
                                manager.canUseFullScreenIntent()
                        )
                    }
                    "openFullScreenIntentSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                            open(activity, Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                        }
                        result.success(null)
                    }
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                            activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            activity.requestPermissions(
                                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_REQUEST
                            )
                        }
                        result.success(null)
                    }
                    "consumeRescheduleFlag" -> {
                        val prefs = app.getSharedPreferences(TimeChangeReceiver.PREFS, Context.MODE_PRIVATE)
                        val set = prefs.getBoolean(TimeChangeReceiver.FLAG, false)
                        if (set) prefs.edit().remove(TimeChangeReceiver.FLAG).apply()
                        result.success(set)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** Oeffnet die App-spezifische Systemeinstellung, sonst die App-Details. */
    private fun open(activity: Activity, action: String) {
        val uri = Uri.parse("package:" + activity.packageName)
        try {
            activity.startActivity(Intent(action, uri))
        } catch (e: ActivityNotFoundException) {
            activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri))
        }
    }
}
