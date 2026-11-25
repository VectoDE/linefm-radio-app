import CarPlay
import UIKit

/// CarPlay-Audio-App (Spec 2.2, Entscheidung 49): drei Tabs
/// Favoriten-Sender, Stationen, Zuletzt gehoert. Antippen startet den Sender
/// in Dart und zeigt den Now-Playing-Bildschirm (Steuerung ueber
/// audio_service/MPRemoteCommandCenter).
///
/// Laeuft erst mit dem Entitlement `com.apple.developer.carplay-audio`
/// (Build-Schalter `CARPLAY_ENABLED`, siehe `ios/README.md`). Ohne
/// Entitlement verbindet iOS diese Szene nie; der Code ist dann inaktiv.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?
  private var tabBar: CPTabBarTemplate?
  private var lists: [CPListTemplate] = []

  // MARK: - CPTemplateApplicationSceneDelegate

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    let channel = CarPlayChannel.shared
    channel.listener = self

    lists = makeLists()
    let tabBar = CPTabBarTemplate(templates: lists)
    self.tabBar = tabBar
    interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)

    // Lief Dart schon (Telefon-App offen), sofort aktuelles Menue holen;
    // sonst kommt es mit dem ersten setMenu.
    channel.requestMenu()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    if CarPlayChannel.shared.listener === self {
      CarPlayChannel.shared.listener = nil
    }
    self.interfaceController = nil
    tabBar = nil
    lists = []
  }

  // MARK: - Listen

  private func makeLists() -> [CPListTemplate] {
    let folders = CarPlayChannel.shared.folders
    let source = folders.isEmpty ? Self.placeholderFolders : folders
    return source.prefix(CPTabBarTemplate.maximumTabCount).map(makeList)
  }

  private func makeList(_ folder: CarPlayFolder) -> CPListTemplate {
    let template = CPListTemplate(title: folder.title, sections: [section(for: folder)])
    template.tabTitle = folder.title
    template.tabImage = UIImage(systemName: Self.symbol(for: folder.id))
    template.emptyViewTitleVariants = [Self.emptyTitle(for: folder.id)]
    template.emptyViewSubtitleVariants = Self.emptySubtitle(for: folder.id).map { [$0] } ?? []
    return template
  }

  private func section(for folder: CarPlayFolder) -> CPListSection {
    let now = CarPlayChannel.shared.nowPlaying
    let items: [CPListItem] = folder.stations.map { station in
      let isCurrent = now.slug == station.slug
      let item = CPListItem(
        text: station.title,
        detailText: isCurrent ? now.detailText : nil,
        image: UIImage(named: "station_\(station.slug)")
      )
      item.userInfo = station.slug
      item.isPlaying = isCurrent && now.playing
      item.playingIndicatorLocation = .trailing
      item.handler = { [weak self] _, completion in
        CarPlayChannel.shared.play(slug: station.slug) { started in
          if started { self?.showNowPlaying() }
          completion()
        }
      }
      return item
    }
    return CPListSection(items: items)
  }

  private func reloadLists() {
    let folders = CarPlayChannel.shared.folders
    guard !folders.isEmpty, let interfaceController else { return }
    // Gleiche Ordner wie bisher: nur Inhalte tauschen (Tab bleibt gewaehlt,
    // ein geoeffnetes Now Playing bleibt stehen).
    if folders.count == lists.count {
      for (template, folder) in zip(lists, folders) {
        template.tabTitle = folder.title
        template.updateSections([section(for: folder)])
      }
      tabBar?.updateTemplates(lists)
      return
    }
    lists = makeLists()
    let tabBar = CPTabBarTemplate(templates: lists)
    self.tabBar = tabBar
    interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
  }

  /// Titelwechsel: nur Detailtext und Wiedergabe-Markierung der vorhandenen
  /// Eintraege setzen statt die Listen neu aufzubauen (CarPlay drosselt
  /// haeufige Template-Updates).
  private func updateNowPlayingItems() {
    let now = CarPlayChannel.shared.nowPlaying
    for template in lists {
      for section in template.sections {
        for case let item as CPListItem in section.items {
          let isCurrent = (item.userInfo as? String) == now.slug && now.slug != nil
          item.setDetailText(isCurrent ? now.detailText : nil)
          item.isPlaying = isCurrent && now.playing
        }
      }
    }
  }

  private func showNowPlaying() {
    guard let interfaceController else { return }
    let nowPlaying = CPNowPlayingTemplate.shared
    if interfaceController.topTemplate === nowPlaying { return }
    interfaceController.pushTemplate(nowPlaying, animated: true, completion: nil)
  }

  // MARK: - Texte und Symbole

  private static var german: Bool {
    Locale.preferredLanguages.first?.lowercased().hasPrefix("de") ?? false
  }

  /// Bis Dart das Menue liefert (Titel wie in lib/l10n: browse*).
  private static var placeholderFolders: [CarPlayFolder] {
    [
      CarPlayFolder(
        id: "favorite_stations", title: german ? "Favoriten-Sender" : "Favorite stations",
        stations: []),
      CarPlayFolder(id: "stations", title: german ? "Stationen" : "Stations", stations: []),
      CarPlayFolder(
        id: "recent", title: german ? "Zuletzt gehört" : "Recently played", stations: []),
    ]
  }

  private static func symbol(for folderId: String) -> String {
    switch folderId {
    case "favorite_stations": return "star.fill"
    case "stations": return "radio"
    default: return "clock"
    }
  }

  private static func emptyTitle(for folderId: String) -> String {
    switch folderId {
    case "favorite_stations":
      return german ? "Noch keine Favoriten-Sender" : "No favorite stations yet"
    case "stations":
      return german ? "Sender werden geladen …" : "Loading stations …"
    default:
      return german ? "Noch nichts gehört" : "Nothing played yet"
    }
  }

  private static func emptySubtitle(for folderId: String) -> String? {
    switch folderId {
    case "favorite_stations":
      return german
        ? "Markiere Sender in der App mit dem Stern."
        : "Mark stations with the star in the app."
    default:
      return nil
    }
  }
}

extension CarPlaySceneDelegate: CarPlayChannelListener {
  func carPlayMenuDidChange() {
    reloadLists()
  }

  func carPlayNowPlayingDidChange() {
    updateNowPlayingItems()
  }
}
