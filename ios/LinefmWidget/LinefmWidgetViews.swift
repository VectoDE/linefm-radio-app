import SwiftUI
import UIKit
import WidgetKit

// Entry model and views of the home screen widget. Compiled into the widget
// extension and into RunnerTests, where WidgetSnapshotTests renders the views
// in light and dark mode.

private enum WidgetKeys {
  static let appGroup = "group.de.linefm.app"
  static let stationSlug = "station_slug"
  static let stationName = "station_name"
  static let title = "title"
  static let artist = "artist"
  static let playing = "playing"
  static let coverPath = "cover_path"
  static let idleText = "idle_text"
}

struct LinefmEntry: TimelineEntry {
  let date: Date
  let stationSlug: String?
  let stationName: String?
  let title: String?
  let artist: String?
  let playing: Bool
  let coverPath: String?
  let idleText: String

  static let placeholder = LinefmEntry(
    date: Date(),
    stationSlug: "linefm",
    stationName: "LineFM +MAIN",
    title: nil,
    artist: nil,
    playing: false,
    coverPath: nil,
    idleText: "LINEFM Radio"
  )

  static func load(date: Date = Date()) -> LinefmEntry {
    let defaults = UserDefaults(suiteName: WidgetKeys.appGroup)
    func string(_ key: String) -> String? {
      guard let value = defaults?.string(forKey: key), !value.isEmpty else { return nil }
      return value
    }
    return LinefmEntry(
      date: date,
      stationSlug: string(WidgetKeys.stationSlug),
      stationName: string(WidgetKeys.stationName),
      title: string(WidgetKeys.title),
      artist: string(WidgetKeys.artist),
      playing: defaults?.bool(forKey: WidgetKeys.playing) ?? false,
      coverPath: string(WidgetKeys.coverPath),
      idleText: string(WidgetKeys.idleText) ?? "LINEFM Radio"
    )
  }

  /// Ziel beim Antippen.
  var url: URL? {
    guard let slug = stationSlug,
      let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else { return URL(string: "linefm://play") }
    return URL(string: "linefm://play?station=\(encoded)")
  }

  /// Cover des laufenden Titels, sonst nil (dann Senderlogo).
  var coverImage: UIImage? {
    guard playing, let path = coverPath else { return nil }
    return UIImage(contentsOfFile: path)
  }

  var logoImage: UIImage? {
    guard let slug = stationSlug else { return nil }
    return UIImage(named: "station_\(slug)")
  }
}

struct LinefmWidgetView: View {
  @Environment(\.widgetFamily) private var environmentFamily
  let entry: LinefmEntry
  /// Fixed family for snapshot rendering outside WidgetKit; nil in the widget.
  var familyOverride: WidgetFamily? = nil

  private var family: WidgetFamily { familyOverride ?? environmentFamily }

  private var artwork: some View {
    Group {
      if let image = entry.coverImage ?? entry.logoImage {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        Image(systemName: "radio")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding(12)
          .foregroundColor(Color("widget_muted"))
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .accessibilityHidden(true)
  }

  private var headline: String { entry.stationName ?? entry.idleText }

  private var trackLine: String? {
    guard entry.playing else { return nil }
    switch (entry.artist, entry.title) {
    case let (a?, t?): return "\(a) – \(t)"
    case let (nil, t?): return t
    case let (a?, nil): return a
    default: return nil
    }
  }

  var body: some View {
    Group {
      if family == .systemSmall {
        VStack(alignment: .leading, spacing: 6) {
          artwork.frame(width: 56, height: 56)
          Spacer(minLength: 0)
          Text(headline)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
          if let line = trackLine {
            Text(line).font(.caption2).lineLimit(2).foregroundColor(Color("widget_muted"))
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      } else {
        HStack(spacing: 12) {
          artwork.frame(width: 72, height: 72)
          VStack(alignment: .leading, spacing: 4) {
            Text(headline)
              .font(.headline)
              .lineLimit(1)
            Text(trackLine ?? entry.idleText)
              .font(.subheadline)
              .lineLimit(2)
              .foregroundColor(Color("widget_muted"))
          }
          Spacer(minLength: 0)
        }
      }
    }
    .foregroundColor(Color("widget_text"))
    .widgetURL(entry.url)
    .modifier(LinefmBackground())
  }
}

/// Hintergrund folgt dem System (Hell/Dunkel) ueber das Farb-Asset
/// `widget_background` (Token surface, Appearances Any/Dark in
/// `Shared/StationLogos.xcassets`).
struct LinefmBackground: ViewModifier {
  private let color = Color("widget_background")

  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 17.0, *) {
      content.containerBackground(color, for: .widget)
    } else {
      content
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
    }
  }
}

