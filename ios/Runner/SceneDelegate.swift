import Flutter
import UIKit

/// Telefon-Szene. Zeigt die gemeinsame FlutterEngine aus dem AppDelegate
/// (statt einer eigenen Engine aus dem Storyboard), damit CarPlay und
/// Telefon dieselbe Dart-Instanz nutzen.
///
/// Die Basisklasse reicht Szenen-Ereignisse an die Plugins weiter und
/// stellt Links (`linefm://play?station=...`, spaeter Universal Links)
/// ueber Flutters Deep Linking als Routeninformation zu. Dort nimmt sie der
/// `DeepLinkObserver` (lib/platform/deep_links.dart) an. Damit Flutter die
/// Engine schon beim Verbinden kennt (Kaltstart-Link), wird das Fenster vor
/// dem Aufruf von `super` angelegt.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
    {
      let engine = appDelegate.flutterEngine
      let controller: FlutterViewController
      if let existing = engine.viewController {
        controller = existing
      } else {
        controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      }
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = controller
      self.window = window
      window.makeKeyAndVisible()
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    super.sceneDidDisconnect(scene)
    // Engine weiterlaufen lassen (Wiedergabe, CarPlay); nur die Ansicht
    // abgeben, damit eine neue Telefon-Szene sie wieder anzeigen kann.
    if let controller = window?.rootViewController as? FlutterViewController,
      let appDelegate = UIApplication.shared.delegate as? AppDelegate,
      appDelegate.flutterEngine.viewController === controller
    {
      appDelegate.flutterEngine.viewController = nil
    }
    window = nil
  }
}
