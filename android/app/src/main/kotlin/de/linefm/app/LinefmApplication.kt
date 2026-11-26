package de.linefm.app

import android.app.Application
import android.content.Context

/**
 * Seeds the browse root extras of audio_service before any service starts.
 *
 * audio_service answers `onGetRoot` synchronously from its SharedPreferences.
 * Dart only writes `androidBrowsableRootExtras` there in `AudioService.init`,
 * which runs after Android Auto has already bound the service and fetched the
 * root. Without this seed the first connection after an install or update
 * gets no (or stale) extras, so Android Auto hides the search button.
 *
 * [ROOT_EXTRAS_JSON] must match `BrowseTree.rootExtras`; a Dart test checks it.
 */
class LinefmApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_ROOT_EXTRAS, ROOT_EXTRAS_JSON)
            .apply()
    }

    companion object {
        private const val PREFS = "audio_service_preferences"
        private const val KEY_ROOT_EXTRAS = "androidBrowsableRootExtras"
        const val ROOT_EXTRAS_JSON =
            "{\"android.media.browse.SEARCH_SUPPORTED\":true," +
                "\"android.media.browse.CONTENT_STYLE_BROWSABLE_HINT\":1," +
                "\"android.media.browse.CONTENT_STYLE_PLAYABLE_HINT\":2}"
    }
}
