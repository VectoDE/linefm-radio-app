import Flutter
import UIKit
import UserNotifications

/// Einstieg der iOS-App.
///
/// Die FlutterEngine wird hier einmal erzeugt und sofort gestartet. Telefon-
/// Szene (SceneDelegate) und CarPlay-Szene (CarPlaySceneDelegate) teilen sich
/// diese Engine. So laeuft Dart auch dann, wenn die App nur ueber CarPlay
/// gestartet wird und das Telefon gesperrt ist (Spec 2.2 CarPlay).
@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Gemeinsame Engine fuer alle Szenen.
  lazy var flutterEngine: FlutterEngine = FlutterEngine(
    name: "linefm",
    project: nil,
    allowHeadlessExecution: true
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    registerNativeChannels(engine: flutterEngine)

    // Wecker-Mitteilungen: Antippen startet den Sender, im Vordergrund
    // trotzdem anzeigen. Alles andere geht an FlutterAppDelegate (Plugins).
    let center = UNUserNotificationCenter.current()
    AlarmNotifications.shared.fallbackDelegate = self
    center.delegate = AlarmNotifications.shared

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Eigene Kanaele der App (nicht ueber Plugins): CarPlay, Wecker, AirPlay.
  private func registerNativeChannels(engine: FlutterEngine) {
    let messenger = engine.binaryMessenger
    CarPlayChannel.shared.attach(messenger: messenger)
    AlarmNotifications.shared.attach(messenger: messenger)

    if let registrar = engine.registrar(forPlugin: "LinefmAirPlayRoutePicker") {
      AirPlayRoutePicker.register(with: registrar)
    }
  }
  // Szenen: Rollen (Telefon, CarPlay) stehen im Szenenmanifest der
  // Info.plist; UIKit waehlt die Konfiguration selbst.
}
