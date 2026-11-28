package de.linefm.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.SizeF
import android.view.KeyEvent
import android.view.View
import android.widget.RemoteViews
import de.linefm.app.MainActivity
import de.linefm.app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import com.ryanheise.audioservice.AudioService
import java.io.File

/**
 * Homescreen-Widget (Spec 2.2) in drei Groessen: 2x1, 4x1, 4x2.
 *
 * Die Daten schreibt die App ueber home_widget (`lib/services/widgets/
 * home_widget_sync.dart`, Schluessel siehe [WidgetKeys]). Das Widget selbst
 * fragt nichts aus dem Netz ab und aktualisiert sich nicht periodisch.
 *
 * Play/Stop:
 * - Spielt die App, schickt der Knopf die Medientaste STOP an den
 *   MediaButtonReceiver von audio_service.
 * - Sonst startet er den Sender im Hintergrund, ohne die App zu oeffnen:
 *   Der Broadcast verbindet sich mit dem Wiedergabedienst von audio_service
 *   und sendet `playFromMediaId(<slug>)`. Android erlaubt den Start eines
 *   Vordergrunddienstes aus dem Hintergrund, wenn der Nutzer ein Widget
 *   bedient (developer.android.com, "Restrictions on starting a foreground
 *   service from the background"). Antippen der Flaeche oeffnet die App.
 */
class LinefmWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val state = WidgetState.from(context, widgetData)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id, state))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Unter Android 12 waehlt das System das Layout selbst (Groessen-Map).
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            val state = WidgetState.from(context, HomeWidgetPlugin.getData(context))
            appWidgetManager.updateAppWidget(
                appWidgetId,
                buildViews(context, appWidgetManager, appWidgetId, state),
            )
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_STOP) {
            sendMediaStop(context)
            // Sofort als gestoppt zeigen; die App bestaetigt den Zustand.
            val data = HomeWidgetPlugin.getData(context)
            data.edit().putBoolean(WidgetKeys.PLAYING, false).apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, LinefmWidgetProvider::class.java))
            if (ids.isNotEmpty()) onUpdate(context, manager, ids, data)
            return
        }
        if (intent.action == ACTION_PLAY) {
            startPlayback(context, intent.getStringExtra(EXTRA_STATION), goAsync())
            return
        }
        super.onReceive(context, intent)
    }

    /**
     * Verbindet sich mit dem Wiedergabedienst und startet den Sender.
     *
     * Laeuft die App nicht, startet der Dienst erst die Dart-Seite (headless);
     * bis dahin verwirft audio_service Befehle. Darum wird der Befehl
     * wiederholt, bis der Wiedergabestatus nicht mehr leer/gestoppt ist. Die
     * Frist bleibt unter dem goAsync-Limit des Systems (rund 10 s).
     */
    private fun startPlayback(
        context: Context,
        slug: String?,
        pending: PendingResult,
    ) {
        val app = context.applicationContext
        val main = Handler(Looper.getMainLooper())
        var browser: MediaBrowserCompat? = null
        var controller: MediaControllerCompat? = null
        var finished = false

        fun finish() {
            if (finished) return
            finished = true
            main.removeCallbacksAndMessages(null)
            browser?.disconnect()
            pending.finish()
        }

        fun send() {
            val controls = controller?.transportControls ?: return
            if (slug.isNullOrEmpty()) controls.play() else controls.playFromMediaId(slug, null)
        }

        fun started(): Boolean = when (controller?.playbackState?.state) {
            PlaybackStateCompat.STATE_PLAYING,
            PlaybackStateCompat.STATE_BUFFERING,
            PlaybackStateCompat.STATE_CONNECTING,
            -> true
            else -> false
        }

        lateinit var retry: Runnable
        retry = Runnable {
            if (started()) {
                finish()
            } else {
                send()
                main.postDelayed(retry, RETRY_MS)
            }
        }

        val callback = object : MediaBrowserCompat.ConnectionCallback() {
            override fun onConnected() {
                val active = browser ?: return finish()
                controller = MediaControllerCompat(app, active.sessionToken)
                send()
                main.postDelayed(retry, RETRY_MS)
            }

            override fun onConnectionFailed() = finish()
        }
        val connecting = MediaBrowserCompat(app, ComponentName(app, AudioService::class.java), callback, null)
        browser = connecting
        main.postDelayed({ finish() }, DEADLINE_MS)
        connecting.connect()
    }

    private fun buildViews(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        state: WidgetState,
    ): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(
                mapOf(
                    SizeF(110f, 40f) to render(context, R.layout.linefm_widget_small, state),
                    SizeF(250f, 40f) to render(context, R.layout.linefm_widget, state),
                    SizeF(250f, 110f) to render(context, R.layout.linefm_widget_large, state),
                ),
            )
        }
        val options = manager.getAppWidgetOptions(widgetId)
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 40)
        val layout = when {
            width < 200 -> R.layout.linefm_widget_small
            height >= 110 -> R.layout.linefm_widget_large
            else -> R.layout.linefm_widget
        }
        return render(context, layout, state)
    }

    private fun render(context: Context, layout: Int, state: WidgetState): RemoteViews {
        val views = RemoteViews(context.packageName, layout)

        val cover = state.cover
        if (cover != null) {
            views.setImageViewBitmap(R.id.widget_logo, cover)
        } else {
            views.setImageViewResource(R.id.widget_logo, StationLogos.drawableFor(context, state.stationSlug))
        }

        views.setTextViewText(R.id.widget_station, state.stationName)
        if (layout != R.layout.linefm_widget_small) {
            views.setTextViewText(R.id.widget_title, state.title ?: state.idleText)
            if (state.artist.isNullOrEmpty()) {
                views.setViewVisibility(R.id.widget_artist, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_artist, state.artist)
                views.setViewVisibility(R.id.widget_artist, View.VISIBLE)
            }
        }

        views.setImageViewResource(
            R.id.widget_button,
            if (state.playing) R.drawable.ic_widget_stop else R.drawable.ic_widget_play,
        )
        views.setContentDescription(
            R.id.widget_button,
            if (state.playing) state.stopLabel else state.playLabel,
        )
        views.setOnClickPendingIntent(
            R.id.widget_button,
            if (state.playing) stopIntent(context) else playIntent(context, state.stationSlug),
        )
        views.setOnClickPendingIntent(R.id.widget_root, openIntent(context))
        return views
    }

    /** Oeffnet die App ohne Aktion. */
    private fun openIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return PendingIntent.getActivity(context, REQUEST_OPEN, intent, IMMUTABLE_UPDATE)
    }

    /** Startet den Sender im Hintergrund (Broadcast an dieses Widget). */
    private fun playIntent(context: Context, slug: String?): PendingIntent {
        val intent = Intent(context, LinefmWidgetProvider::class.java)
            .setAction(ACTION_PLAY)
            .apply { if (!slug.isNullOrEmpty()) putExtra(EXTRA_STATION, slug) }
        return PendingIntent.getBroadcast(context, REQUEST_PLAY, intent, IMMUTABLE_UPDATE)
    }

    /** Stop ueber dieses Widget (setzt den Status sofort zurueck). */
    private fun stopIntent(context: Context): PendingIntent {
        val intent = Intent(context, LinefmWidgetProvider::class.java).setAction(ACTION_STOP)
        return PendingIntent.getBroadcast(context, REQUEST_STOP, intent, IMMUTABLE_UPDATE)
    }

    companion object {
        const val ACTION_STOP = "de.linefm.app.widget.STOP"
        const val ACTION_PLAY = "de.linefm.app.widget.PLAY"
        const val EXTRA_STATION = "station"
        private const val RETRY_MS = 1000L
        private const val DEADLINE_MS = 9000L
        private const val REQUEST_OPEN = 1
        private const val REQUEST_PLAY = 2
        private const val REQUEST_STOP = 3
        private const val IMMUTABLE_UPDATE =
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT

        /** Medientaste STOP an audio_service (verarbeitet onMediaButtonEvent). */
        fun sendMediaStop(context: Context) {
            // audio_service wertet nur ACTION_DOWN aus.
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
                .setComponent(
                    ComponentName(context, com.ryanheise.audioservice.MediaButtonReceiver::class.java),
                )
                .putExtra(
                    Intent.EXTRA_KEY_EVENT,
                    KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_STOP),
                )
            context.sendBroadcast(intent)
        }
    }
}

/** Schluessel im Widget-Speicher; identisch mit `HomeWidgetKeys` in Dart. */
internal object WidgetKeys {
    const val STATION_SLUG = "station_slug"
    const val STATION_NAME = "station_name"
    const val TITLE = "title"
    const val ARTIST = "artist"
    const val PLAYING = "playing"
    const val COVER_PATH = "cover_path"
    const val IDLE_TEXT = "idle_text"
    const val PLAY_LABEL = "play_label"
    const val STOP_LABEL = "stop_label"
}

/** Gelesener Widget-Zustand mit Rueckfaellen auf die App-Ressourcen. */
internal class WidgetState(
    val stationSlug: String?,
    val stationName: String,
    val title: String?,
    val artist: String?,
    val playing: Boolean,
    val cover: Bitmap?,
    val idleText: String,
    val playLabel: String,
    val stopLabel: String,
) {
    companion object {
        /** Kantenlaenge, auf die das Cover beim Laden verkleinert wird. */
        private const val COVER_PX = 300

        fun from(context: Context, data: SharedPreferences): WidgetState {
            fun text(key: String): String? = (data.all[key] as? String)?.takeIf { it.isNotBlank() }
            return WidgetState(
                stationSlug = text(WidgetKeys.STATION_SLUG),
                stationName = text(WidgetKeys.STATION_NAME)
                    ?: context.getString(R.string.widget_default_station),
                title = text(WidgetKeys.TITLE),
                artist = text(WidgetKeys.ARTIST),
                playing = data.all[WidgetKeys.PLAYING] as? Boolean ?: false,
                cover = text(WidgetKeys.COVER_PATH)?.let(::loadCover),
                idleText = text(WidgetKeys.IDLE_TEXT) ?: context.getString(R.string.widget_idle),
                playLabel = text(WidgetKeys.PLAY_LABEL) ?: context.getString(R.string.widget_play),
                stopLabel = text(WidgetKeys.STOP_LABEL) ?: context.getString(R.string.widget_stop),
            )
        }

        /** Laedt das von der App gespeicherte Cover verkleinert (RemoteViews-Limit). */
        private fun loadCover(path: String): Bitmap? {
            val file = File(path)
            if (!file.isFile) return null
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, bounds)
                var sample = 1
                while (bounds.outWidth / (sample * 2) >= COVER_PX && bounds.outHeight / (sample * 2) >= COVER_PX) {
                    sample *= 2
                }
                BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
            } catch (_: Exception) {
                null
            }
        }
    }
}

/**
 * Gebuendelte Senderlogos (auch fuer Android Auto, siehe keep.xml).
 *
 * Keine eigene Senderliste: Die Senderliste steht nur in
 * config/stations.yaml. Hier wird nur das Format des Kuerzels geprueft
 * und das Drawable `auto_station_<kuerzel>` per Name gesucht; fehlt es (Sender
 * erst nachgeladen), erscheint das LINEFM-Logo.
 */
internal object StationLogos {
    private val SLUG = Regex("^[a-z0-9_-]{1,64}$")

    fun drawableFor(context: Context, slug: String?): Int {
        if (slug == null || !SLUG.matches(slug)) return R.drawable.auto_station_linefm
        val name = "auto_station_" + slug.replace(Regex("[^a-z0-9]"), "")
        @Suppress("DiscouragedApi") // Name kommt aus der Senderliste, nicht aus R.
        val id = context.resources.getIdentifier(name, "drawable", context.packageName)
        return if (id != 0) id else R.drawable.auto_station_linefm
    }
}
