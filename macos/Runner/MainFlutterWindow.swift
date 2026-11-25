import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // Brand ink (#0F1221), same as the splash screens and the in-app loader,
    // so the window is never white or black before the first Flutter frame.
    let ink = NSColor(srgbRed: 15 / 255, green: 18 / 255, blue: 33 / 255, alpha: 1)
    flutterViewController.backgroundColor = ink
    self.backgroundColor = ink
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    AirPlayRoutePicker.register(
      with: flutterViewController.registrar(forPlugin: "LinefmAirPlayRoutePicker"))

    super.awakeFromNib()
  }
}
