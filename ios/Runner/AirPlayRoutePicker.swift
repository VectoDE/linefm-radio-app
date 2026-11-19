import AVKit
import Flutter
import UIKit

/// Native Seite des AirPlay-Knopfs (Issue #14/#51). Dart-Seite:
/// `lib/platform/airplay_button.dart`.
///
/// * MethodChannel `de.linefm.app/airplay`, Methode `isAvailable` -> true.
/// * PlatformView `de.linefm.app/airplay_route_picker` mit
///   `creationParams {tintColor: Int (ARGB), activeTintColor: Int (ARGB)}`.
///
/// just_audio spielt ueber AVPlayer; die Ausgabe auf ein AirPlay-Geraet
/// uebernimmt das System, sobald es im Picker gewaehlt ist.
enum AirPlayRoutePicker {
  static let channelName = "de.linefm.app/airplay"
  static let viewType = "de.linefm.app/airplay_route_picker"

  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(AirPlayRoutePickerFactory(), withId: viewType)
    FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
      .setMethodCallHandler { call, result in
        result(call.method == "isAvailable" ? true : FlutterMethodNotImplemented)
      }
  }
}

final class AirPlayRoutePickerFactory: NSObject, FlutterPlatformViewFactory {
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    AirPlayRoutePickerView(frame: frame, args: args as? [String: Any])
  }
}

final class AirPlayRoutePickerView: NSObject, FlutterPlatformView {
  private let picker: AVRoutePickerView

  init(frame: CGRect, args: [String: Any]?) {
    picker = AVRoutePickerView(frame: frame)
    super.init()
    picker.backgroundColor = .clear
    if #available(iOS 13.0, *) {
      picker.prioritizesVideoDevices = false
    }
    if let value = (args?["tintColor"] as? NSNumber)?.int64Value {
      picker.tintColor = UIColor(argb: value)
    }
    if let value = (args?["activeTintColor"] as? NSNumber)?.int64Value {
      picker.activeTintColor = UIColor(argb: value)
    }
  }

  func view() -> UIView { picker }
}

extension UIColor {
  /// Farbe aus einem ARGB-Wert (Dart `Color.toARGB32()`).
  convenience init(argb: Int64) {
    self.init(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }
}
