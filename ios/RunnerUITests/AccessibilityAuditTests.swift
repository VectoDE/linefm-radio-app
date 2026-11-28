import XCTest

/// Accessibility audit of the main screens in the iOS simulator.
///
/// Runs Apple's `performAccessibilityAudit()` (Xcode 15, iOS 17) on the
/// accessibility tree that VoiceOver reads. It finds missing labels, too
/// small hit regions, low contrast, clipped text and elements VoiceOver
/// cannot reach. It does not produce or check spoken VoiceOver output; that
/// stays a check on a real device.
///
/// The Dynamic Type audit is left out: Flutter scales text from the system
/// setting itself and does not use UIFont text styles, so the audit cannot
/// see that scaling. Text scaling is covered by the Flutter tests in
/// test/a11y/ (200 % on small screens).
final class AccessibilityAuditTests: XCTestCase {
  private let areas = ["Stations", "Player", "History", "Favorites", "Settings"]
  private let settingsRows = ["Alarm", "About LINEFM Radio"]

  override func setUpWithError() throws {
    continueAfterFailure = true
  }

  @MainActor
  func testMainScreensPassTheAccessibilityAudit() throws {
    guard #available(iOS 17.0, *) else {
      throw XCTSkip("performAccessibilityAudit needs iOS 17")
    }
    let app = XCUIApplication()
    app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()

    // A fresh install opens the storage notice over the app on first start.
    // Audit it as a screen of its own, then close it so the areas behind it
    // can be reached.
    let dismiss = app.buttons["Got it"].firstMatch
    if dismiss.waitForExistence(timeout: 30) {
      try audit(app, screen: "Storage notice")
      dismiss.tap()
    }

    for area in areas {
      let tab = app.buttons[area].firstMatch
      XCTAssertTrue(tab.waitForExistence(timeout: 30), "navigation target \(area) not found")
      tab.tap()
      try audit(app, screen: area)
    }

    for row in settingsRows {
      // The Settings button in the header toggles: on the Settings screen it
      // goes back. Tap it only when the screen heading is not shown yet.
      // After Back the page transition is still running, so wait briefly.
      if !app.descendants(matching: .any)["SETTINGS"].firstMatch.waitForExistence(timeout: 5) {
        app.buttons["Settings"].firstMatch.tap()
      }
      let entry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", row)).firstMatch
      var swipes = 0
      // Flutter reports its elements as not hittable, so the loop waits for
      // the row to exist; the lazy list drops rows that scrolled far away.
      while !entry.exists && swipes < 8 {
        // Slow drag: a normal swipe flings the lazy list past rows in the
        // middle, so only the last row was ever reached.
        app.swipeUp(velocity: .slow)
        swipes += 1
      }
      XCTAssertTrue(entry.waitForExistence(timeout: 10), "settings row \(row) not found")
      entry.tap()
      try audit(app, screen: row)
      let back = app.navigationBars.buttons.firstMatch
      if back.exists {
        back.tap()
      } else {
        app.buttons["Back"].firstMatch.tap()
      }
    }
  }

  @available(iOS 17.0, *)
  @MainActor
  private func audit(_ app: XCUIApplication, screen: String) throws {
    var types = XCUIAccessibilityAuditType.all
    types.remove(.dynamicType)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "screen-\(screen)"
    shot.lifetime = .keepAlways
    add(shot)
    try app.performAccessibilityAudit(for: types) { finding in
      if Self.isFlutterScrollContainer(finding, in: app) {
        return true
      }
      XCTFail("\(screen): \(finding.auditType) \(finding.compactDescription) element: \(finding.element?.debugDescription ?? "none")")
      return true
    }
  }

  /// Flutter exposes every scrollable (and the full-screen route that holds
  /// the player pager) as an unlabelled ScrollView or Other element. Such a
  /// container is not a control: VoiceOver never stops on it and reads the
  /// labelled children inside. Only the description audit on exactly these
  /// containers is skipped; every element inside is still audited, and a
  /// smaller unlabelled element still fails.
  @available(iOS 17.0, *)
  @MainActor
  private static func isFlutterScrollContainer(
    _ finding: XCUIAccessibilityAuditIssue, in app: XCUIApplication
  ) -> Bool {
    guard finding.auditType == .sufficientElementDescription,
      let element = finding.element, element.label.isEmpty
    else { return false }
    switch element.elementType {
    case .scrollView:
      return true
    case .other:
      return element.frame == app.frame
    default:
      return false
    }
  }
}
