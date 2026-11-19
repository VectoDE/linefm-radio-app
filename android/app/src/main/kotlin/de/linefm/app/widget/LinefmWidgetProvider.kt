package de.linefm.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.KeyEvent
import android.view.View
import android.widget.RemoteViews
import de.linefm.app.MainActivity
import de.linefm.app.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Homescreen-Widget (Spec 2.2, Issue #15) in drei Groessen: 2x1, 4x1, 4x2.
 *
 * Die Daten schreibt die App ueber home_widget (`lib/services/widgets/
 * home_widget_sync.dart`, Schluessel siehe [WidgetKeys]). Das Widget selbst
 * fragt nichts aus dem Netz ab und aktualisiert sich nicht periodisch.
 *
 * Play/Stop:
 * - Spielt die App, schickt der Knopf die Medientaste STOP an den
 *   MediaButtonReceiver von audio_service.
 * - Sonst oeffnet er die App mit `linefm://play?station=<slug>`; die App
 *   startet den Sender (Deep Link, P21). Ein Start im Hintergrund ohne
 *   sichtbare App ist ab Android 12 fuer Vordergrunddienste nicht erlaubt.
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
        super.onReceive(context, intent)
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
            views.setImageViewResource(R.id.widget_logo, StationLogos.drawableFor(state.stationSlug))
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

    /** Startet die App mit Deep Link auf den Sender. */
    private fun playIntent(context: Context, slug: String?): PendingIntent {
        val uri = Uri.Builder()
            .scheme("linefm")
            .authority("play")
            .apply { if (!slug.isNullOrEmpty()) appendQueryParameter("station", slug) }
            .build()
        val intent = Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(context, REQUEST_PLAY, intent, IMMUTABLE_UPDATE)
    }

    /** Stop ueber dieses Widget (setzt den Status sofort zurueck). */
    private fun stopIntent(context: Context): PendingIntent {
        val intent = Intent(context, LinefmWidgetProvider::class.java).setAction(ACTION_STOP)
        return PendingIntent.getBroadcast(context, REQUEST_STOP, intent, IMMUTABLE_UPDATE)
    }

    companion object {
        const val ACTION_STOP = "de.linefm.app.widget.STOP"
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

/** Gebuendelte Senderlogos (auch fuer Android Auto, siehe keep.xml). */
internal object StationLogos {
    fun drawableFor(slug: String?): Int = when (slug) {
        "linefmrap" -> R.drawable.auto_station_linefmrap
        "linefmgaming" -> R.drawable.auto_station_linefmgaming
        "linefmlofi" -> R.drawable.auto_station_linefmlofi
        "radio3fm" -> R.drawable.auto_station_radio3fm
        "fobfm" -> R.drawable.auto_station_fobfm
        else -> R.drawable.auto_station_linefm
    }
}
