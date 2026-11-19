import AVKit
import Cocoa
import FlutterMacOS

/// Native Seite des AirPlay-Knopfs unter macOS (Issue #14/#51). Gleicher
/// Kanal und Platform-View-Typ wie iOS; Dart-Seite:
/// `lib/platform/airplay_button.dart` (AppKitView).
///
/// Hinweis: `AVRoutePickerView` waehlt unter macOS die Ausgabe fuer einen
/// AVPlayer. just_audio legt seinen Player intern an; ob der Picker ohne
/// gesetzten `player` die Systemausgabe umschaltet, ist auf einem Mac noch
/// zu pruefen (kein Mac in der Entwicklung, siehe ios/README.md).
enum AirPlayRoutePicker {
  static let channelName = "de.linefm.app/airplay"
  static let viewType = "de.linefm.app/airplay_route_picker"

  static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(AirPlayRoutePickerFactory(), withId: viewType)
    FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
      .setMethodCallHandler { call, result in
        result(call.method == "isAvailable" ? true : FlutterMethodNotImplemented)
      }
  }
}

final class AirPlayRoutePickerFactory: NSObject, FlutterPlatformViewFactory {
  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    let picker = AVRoutePickerView(frame: .zero)
    picker.isRoutePickerButtonBordered = false
    let map = args as? [String: Any]
    if let value = (map?["tintColor"] as? NSNumber)?.int64Value {
      let color = NSColor(argb: value)
      picker.setRoutePickerButtonColor(color, for: .normal)
      picker.setRoutePickerButtonColor(color, for: .normalHighlighted)
    }
    if let value = (map?["activeTintColor"] as? NSNumber)?.int64Value {
      let color = NSColor(argb: value)
      picker.setRoutePickerButtonColor(color, for: .active)
      picker.setRoutePickerButtonColor(color, for: .activeHighlighted)
    }
    return picker
  }
}

extension NSColor {
  /// Farbe aus einem ARGB-Wert (Dart `Color.toARGB32()`).
  convenience init(argb: Int64) {
    self.init(
      srgbRed: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255
    )
  }
}
