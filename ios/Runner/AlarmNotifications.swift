import Flutter
import UIKit
import UserNotifications

/// Native Seite des Kanals `de.linefm.app/alarm_ios` (Radiowecker iOS,
/// Spec 2.2). Vertrag: Doc-Kommentar von `IosAlarmPlatform` in
/// `lib/services/alarm/alarm_ios.dart`.
///
/// * `requestPermission` -> Bool (Mitteilungen mit Ton).
/// * `schedule` `{id, hour, minute, weekdays: [ISO 1 = Mo ... 7 = So],
///   title, body, url}`: ersetzt alle Mitteilungen dieser `id`. Je Wochentag
///   ein wiederholender `UNCalendarNotificationTrigger` mit Kennung
///   `id#<ISO-Wochentag>`; leere Wochentage = einmalig (`id#once`).
///   Ton: Systemton (`UNNotificationSound.default`, Entscheidung 40).
/// * `cancel` `{id}`: entfernt geplante und zugestellte Mitteilungen.
///
/// Antippen der Mitteilung oeffnet `url` (`linefm://play?station=slug`).
/// Der Link laeuft ueber das URL-Schema in die Szene und von dort ueber
/// Flutters Deep Linking an den `DeepLinkObserver`, der den Sender startet.
final class AlarmNotifications: NSObject, UNUserNotificationCenterDelegate {
  static let shared = AlarmNotifications()
  static let channelName = "de.linefm.app/alarm_ios"
  static let categoryIdentifier = "de.linefm.app.alarm"
  static let urlKey = "linefm_url"

  /// Bekommt alle Mitteilungen, die nicht vom Wecker stammen (Plugins ueber
  /// FlutterAppDelegate).
  weak var fallbackDelegate: UNUserNotificationCenterDelegate?

  private var channel: FlutterMethodChannel?
  private let center = UNUserNotificationCenter.current()

  private override init() {
    super.init()
  }

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    self.channel = channel
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    case "schedule":
      schedule(call.arguments as? [String: Any] ?? [:], result: result)
    case "cancel":
      guard let id = (call.arguments as? [String: Any])?["id"] as? String else {
        result(FlutterError(code: "bad_args", message: "id fehlt", details: nil))
        return
      }
      cancel(id: id)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Planen

  /// Alle Kennungen, die zu einer Wecker-ID gehoeren koennen.
  static func identifiers(for id: String) -> [String] {
    ["\(id)#once"] + (1...7).map { "\(id)#\($0)" }
  }

  /// ISO-Wochentag (1 = Montag ... 7 = Sonntag) -> Calendar-Wochentag
  /// (1 = Sonntag ... 7 = Samstag).
  static func calendarWeekday(iso: Int) -> Int {
    iso % 7 + 1
  }

  private func schedule(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let id = args["id"] as? String,
      let hour = args["hour"] as? Int,
      let minute = args["minute"] as? Int,
      (0...23).contains(hour), (0...59).contains(minute)
    else {
      result(FlutterError(code: "bad_args", message: "id/hour/minute fehlen", details: nil))
      return
    }
    let weekdays = (args["weekdays"] as? [Int] ?? []).filter { (1...7).contains($0) }
    let content = UNMutableNotificationContent()
    content.title = args["title"] as? String ?? "LINEFM Radio"
    content.body = args["body"] as? String ?? ""
    content.sound = .default
    content.categoryIdentifier = Self.categoryIdentifier
    if let url = args["url"] as? String {
      content.userInfo = [Self.urlKey: url]
    }

    var requests: [UNNotificationRequest] = []
    if weekdays.isEmpty {
      var date = DateComponents()
      date.hour = hour
      date.minute = minute
      let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
      requests.append(
        UNNotificationRequest(identifier: "\(id)#once", content: content, trigger: trigger))
    } else {
      for iso in Set(weekdays).sorted() {
        var date = DateComponents()
        date.weekday = Self.calendarWeekday(iso: iso)
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        requests.append(
          UNNotificationRequest(identifier: "\(id)#\(iso)", content: content, trigger: trigger))
      }
    }

    cancel(id: id)
    let group = DispatchGroup()
    let errors = ErrorBox()
    for request in requests {
      group.enter()
      center.add(request) { error in
        if let error { errors.record(error) }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      if let firstError = errors.first {
        result(
          FlutterError(
            code: "schedule_failed", message: firstError.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  private func cancel(id: String) {
    let ids = Self.identifiers(for: id)
    center.removePendingNotificationRequests(withIdentifiers: ids)
    center.removeDeliveredNotifications(withIdentifiers: ids)
  }

  // MARK: - UNUserNotificationCenterDelegate

  private func isAlarm(_ notification: UNNotification) -> Bool {
    notification.request.content.categoryIdentifier == Self.categoryIdentifier
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    guard isAlarm(notification) else {
      if let fallback = fallbackDelegate,
        fallback.responds(
          to: #selector(
            UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)
          ))
      {
        fallback.userNotificationCenter?(
          center, willPresent: notification, withCompletionHandler: completionHandler)
      } else {
        completionHandler([])
      }
      return
    }
    // Wecker auch bei offener App mit Ton anzeigen.
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let notification = response.notification
    guard isAlarm(notification) else {
      if let fallback = fallbackDelegate,
        fallback.responds(
          to: #selector(
            UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)
          ))
      {
        fallback.userNotificationCenter?(
          center, didReceive: response, withCompletionHandler: completionHandler)
      } else {
        completionHandler()
      }
      return
    }
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
      let raw = notification.request.content.userInfo[Self.urlKey] as? String,
      let url = URL(string: raw), url.scheme == "linefm"
    {
      // Eigenes URL-Schema: kommt ueber scene(_:openURLContexts:) bzw. beim
      // Kaltstart ueber die Verbindungsoptionen in Flutter an.
      DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
    completionHandler()
  }
}

/// Sammelt den ersten Fehler aus parallelen `add`-Callbacks (thread-sicher).
private final class ErrorBox: @unchecked Sendable {
  private let lock = NSLock()
  private var stored: Error?

  func record(_ error: Error) {
    lock.lock()
    if stored == nil { stored = error }
    lock.unlock()
  }

  var first: Error? {
    lock.lock()
    defer { lock.unlock() }
    return stored
  }
}
