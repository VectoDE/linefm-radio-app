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

    for area in areas {
      let tab = app.buttons[area].firstMatch
      XCTAssertTrue(tab.waitForExistence(timeout: 30), "navigation target \(area) not found")
      tab.tap()
      try audit(app, screen: area)
    }

    for row in settingsRows {
      app.buttons["Settings"].firstMatch.tap()
      let entry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", row)).firstMatch
      var swipes = 0
      while !entry.isHittable && swipes < 5 {
        app.swipeUp()
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
    try app.performAccessibilityAudit(for: types) { issue in
      XCTFail("\(screen): \(issue.auditType) \(issue.compactDescription) element: \(issue.element?.debugDescription ?? "none")")
      return true
    }
  }
}
