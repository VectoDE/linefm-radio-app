package de.linefm.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Zeitzonen- oder Uhrzeitwechsel: Die geplanten Wecker liegen als absolute
 * Zeitpunkte im AlarmManager, "7:00 Ortszeit" stimmt danach nicht mehr. Ohne
 * Dart-Laufzeit laesst sich nicht neu planen und die App soll dafuer nicht
 * starten. Der Empfaenger merkt deshalb nur vor; die App plant beim naechsten
 * Start oder Oeffnen alles neu (AlarmBootstrap) und loescht das Merkzeichen.
 *
 * Grenze: Bis dahin klingeln die Wecker zum alten Zeitpunkt.
 */
class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_TIMEZONE_CHANGED && intent.action != Intent.ACTION_TIME_CHANGED) return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(FLAG, true)
            .apply()
    }

    companion object {
        // shared_preferences legt seine Schluessel unter "flutter." ab.
        const val PREFS = "FlutterSharedPreferences"
        const val FLAG = "flutter.linefm-alarm-needs-reschedule"
    }
}
