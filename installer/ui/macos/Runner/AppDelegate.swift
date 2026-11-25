import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Cmd+Q goes through the same confirmation as the close button; the setup
  /// UI ends the process once nothing is running.
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    if let window = sender.windows.first(where: { $0 is MainFlutterWindow }) as? MainFlutterWindow,
       !window.windowShouldClose(window) {
      return .terminateCancel
    }
    return .terminateNow
  }
}
