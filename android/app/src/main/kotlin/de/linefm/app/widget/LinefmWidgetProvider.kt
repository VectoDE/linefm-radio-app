package de.linefm.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

// Stub: Homescreen-Widget (2x1, 4x1, 4x2). Wird in Paket P16 ausgebaut.
class LinefmWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // P16: RemoteViews mit den von home_widget geschriebenen Daten.
    }
}
