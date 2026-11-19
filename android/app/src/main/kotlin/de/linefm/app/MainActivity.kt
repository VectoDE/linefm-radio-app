package de.linefm.app

import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Einzige Activity. audio_service verlangt [AudioServiceActivity] (geteilte
 * FlutterEngine mit dem Wiedergabedienst, auch fuer Android Auto).
 *
 * Deep Links `linefm://play?station=<slug>` (Homescreen-Widget, Wecker) und
 * `https://app.linefm.de/?station=<slug>` (geteilte Links) reicht die Activity ueber den Kanal `de.linefm.app/deep_links` an
 * Dart weiter:
 * - `getInitialLink` → Link, mit dem die App gestartet wurde (einmalig).
 * - `onLink(String)` → Link bei laufender App (onNewIntent).
 *
 * Flutters eingebautes Deep Linking ist aus ([shouldHandleDeeplinking]): Die
 * App hat keine benannten Routen, ein Link wuerde sonst als Route
 * `/?station=…` an den Navigator gehen und dort scheitern.
 */
class MainActivity : AudioServiceActivity() {
    private var channel: MethodChannel? = null
    private var alarmChannel: MethodChannel? = null
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (savedInstanceState == null) initialLink = linkFrom(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmChannel = AlarmChannel.register(flutterEngine, this)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        result.success(initialLink)
                        initialLink = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel?.setMethodCallHandler(null)
        channel = null
        alarmChannel?.setMethodCallHandler(null)
        alarmChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = linkFrom(intent) ?: return
        val active = channel
        if (active == null) {
            initialLink = link
        } else {
            active.invokeMethod("onLink", link)
        }
    }

    override fun shouldHandleDeeplinking(): Boolean = false

    companion object {
        const val CHANNEL = "de.linefm.app/deep_links"
        const val WEB_HOST = "app.linefm.de"

        /** Nur eigene Links; aus dem Verlauf neu geoeffnete Intents nicht erneut. */
        fun linkFrom(intent: Intent?): String? {
            if (intent == null || intent.action != Intent.ACTION_VIEW) return null
            if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
            val data = intent.data ?: return null
            val app = data.scheme == "linefm" && data.host == "play"
            val web = data.scheme == "https" && data.host == WEB_HOST
            if (!app && !web) return null
            return data.toString()
        }
    }
}
