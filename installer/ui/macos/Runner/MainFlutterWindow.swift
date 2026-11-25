import Cocoa
import FlutterMacOS

/// Setup window: same client size as on Windows, not resizable. The close
/// button is handed to the setup UI (confirmation, cancel and rollback while
/// the engine runs); the UI ends the process itself.
class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var channel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setContentSize(NSSize(width: 844, height: 620))
    self.styleMask.remove(.resizable)
    self.title = "LINEFM Radio Setup"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    channel = FlutterMethodChannel(
      name: "linefm_setup/native",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    self.delegate = self

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard let channel = channel else { return true }
    channel.invokeMethod("closeRequested", arguments: nil)
    return false
  }
}
