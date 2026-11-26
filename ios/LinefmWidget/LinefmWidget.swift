import SwiftUI
import UIKit
import WidgetKit

/// Homescreen-Widget (Spec 2.2): Senderlogo bzw. Cover, Sender,
/// Titel und Kuenstler. Daten schreibt die App ueber home_widget in die App
/// Group (`lib/services/widgets/home_widget_sync.dart`, `HomeWidgetKeys`).
/// Antippen oeffnet `linefm://play?station=<slug>`.
/// Interaktiver Play-Knopf (iOS 17 `AudioPlaybackIntent`) ist v2.

struct LinefmProvider: TimelineProvider {
  func placeholder(in context: Context) -> LinefmEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (LinefmEntry) -> Void) {
    completion(context.isPreview ? .placeholder : .load())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<LinefmEntry>) -> Void) {
    // Die App stoesst Aktualisierungen an (WidgetCenter ueber home_widget);
    // zusaetzlich alle 30 Minuten neu lesen.
    let now = Date()
    let next = now.addingTimeInterval(30 * 60)
    completion(Timeline(entries: [.load(date: now)], policy: .after(next)))
  }
}

struct LinefmWidget: Widget {
  let kind = "LinefmWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LinefmProvider()) { entry in
      LinefmWidgetView(entry: entry)
    }
    .configurationDisplayName("LINEFM Radio")
    .description(
      Locale.preferredLanguages.first?.lowercased().hasPrefix("de") == true
        ? "Sender und aktueller Titel."
        : "Station and current track."
    )
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct LinefmWidgetBundle: WidgetBundle {
  var body: some Widget {
    LinefmWidget()
  }
}
