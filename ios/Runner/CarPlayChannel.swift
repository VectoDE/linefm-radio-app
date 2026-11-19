import Flutter
import Foundation

/// Ein Sender im CarPlay-Menue (aus `AutoMenuFolder.toJson()` in Dart).
struct CarPlayStation: Equatable {
  let id: String
  let slug: String
  let title: String
  let logoUrl: String?
}

/// Ein Ordner des Auto-Menues (Favoriten-Sender, Stationen, Zuletzt gehoert).
struct CarPlayFolder: Equatable {
  let id: String
  let title: String
  let stations: [CarPlayStation]
}

/// Was gerade laeuft (Dart-Methode `nowPlaying`).
struct CarPlayNowPlaying: Equatable {
  let slug: String?
  let station: String?
  let title: String?
  let artist: String?
  let playing: Bool

  static let empty = CarPlayNowPlaying(
    slug: nil, station: nil, title: nil, artist: nil, playing: false)

  /// Detailtext fuer den laufenden Sender: "Kuenstler - Titel".
  var detailText: String? {
    switch (artist?.isEmpty == false ? artist : nil, title?.isEmpty == false ? title : nil) {
    case let (a?, t?): return "\(a) – \(t)"
    case let (nil, t?): return t
    case let (a?, nil): return a
    default: return nil
    }
  }
}

protocol CarPlayChannelListener: AnyObject {
  func carPlayMenuDidChange()
  func carPlayNowPlayingDidChange()
}

/// Native Seite des Kanals `de.linefm.app/carplay`. Vertrag: Doc-Kommentar in
/// `lib/platform/carplay_bridge.dart`.
///
/// Haelt den letzten Stand von Menue und laufendem Titel, damit eine
/// CarPlay-Szene, die sich spaeter verbindet, sofort etwas zeigen kann.
final class CarPlayChannel {
  static let shared = CarPlayChannel()
  static let channelName = "de.linefm.app/carplay"

  private var channel: FlutterMethodChannel?
  private(set) var folders: [CarPlayFolder] = []
  private(set) var nowPlaying = CarPlayNowPlaying.empty
  weak var listener: CarPlayChannelListener?

  private init() {}

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setMenu":
      updateMenu(call.arguments)
      result(nil)
    case "nowPlaying":
      updateNowPlaying(call.arguments)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Holt das Menue aktiv (z. B. beim Verbinden der CarPlay-Szene). Laeuft
  /// Dart noch nicht, kommt das Menue spaeter ueber `setMenu`.
  func requestMenu() {
    channel?.invokeMethod("getMenu", arguments: nil) { [weak self] value in
      guard let self, !(value is FlutterError), (value as? NSObject) !== FlutterMethodNotImplemented
      else { return }
      self.updateMenu(value)
    }
  }

  /// Startet einen Sender in Dart. `completion(true)`, wenn Dart den Start
  /// angenommen hat.
  func play(slug: String, completion: @escaping (Bool) -> Void) {
    guard let channel else {
      completion(false)
      return
    }
    channel.invokeMethod("play", arguments: ["slug": slug]) { value in
      completion((value as? Bool) ?? false)
    }
  }

  private func updateMenu(_ arguments: Any?) {
    guard let parsed = Self.parseFolders(arguments) else { return }
    if parsed == folders { return }
    folders = parsed
    listener?.carPlayMenuDidChange()
  }

  private func updateNowPlaying(_ arguments: Any?) {
    let map = arguments as? [String: Any] ?? [:]
    let next = CarPlayNowPlaying(
      slug: map["slug"] as? String,
      station: map["station"] as? String,
      title: map["title"] as? String,
      artist: map["artist"] as? String,
      playing: map["playing"] as? Bool ?? false
    )
    if next == nowPlaying { return }
    nowPlaying = next
    listener?.carPlayNowPlayingDidChange()
  }

  /// `{folders: [{id, title, stations: [{id, slug, title, logoAsset, logoUrl}]}]}`.
  static func parseFolders(_ arguments: Any?) -> [CarPlayFolder]? {
    guard let map = arguments as? [String: Any],
      let rawFolders = map["folders"] as? [[String: Any]]
    else { return nil }
    return rawFolders.compactMap { raw in
      guard let id = raw["id"] as? String, let title = raw["title"] as? String else {
        return nil
      }
      let stations = (raw["stations"] as? [[String: Any]] ?? []).compactMap {
        s -> CarPlayStation? in
        guard let slug = s["slug"] as? String, let name = s["title"] as? String else {
          return nil
        }
        return CarPlayStation(
          id: s["id"] as? String ?? slug,
          slug: slug,
          title: name,
          logoUrl: s["logoUrl"] as? String
        )
      }
      return CarPlayFolder(id: id, title: title, stations: stations)
    }
  }
}
