import Cocoa
import FlutterMacOS

/// Setup window: same client size as on Windows, not resizable, no native
/// title bar (the Flutter UI draws the custom LINEFM bar with its own
/// window buttons). Close and Cmd+Q are handed to the setup UI
/// (confirmation, cancel and rollback while the engine runs); the UI ends
/// the process itself.
class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var channel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.styleMask.remove(.resizable)
    self.styleMask.insert(.fullSizeContentView)
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
      self.standardWindowButton(kind)?.isHidden = true
    }
    self.setContentSize(NSSize(width: 844, height: 660))
    self.title = "LINEFM Radio Setup"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: "linefm_setup/native",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self, call.method == "window",
            let action = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch action {
      case "startDrag":
        if let event = NSApp.currentEvent { self.performDrag(with: event) }
      case "minimize":
        self.miniaturize(nil)
      default:
        break
      }
      result(nil)
    }
    self.channel = channel
    self.delegate = self

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard let channel = channel else { return true }
    channel.invokeMethod("closeRequested", arguments: nil)
    return false
  }
}
