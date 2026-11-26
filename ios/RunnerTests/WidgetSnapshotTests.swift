import SwiftUI
import Testing
import UIKit
import WidgetKit

/// Renders the home screen widget views with ImageRenderer in light and dark
/// mode, checks that the background follows the system appearance and, when
/// the environment variable WIDGET_SNAPSHOT_DIR is set, writes PNG files there
/// (CI passes it as TEST_RUNNER_WIDGET_SNAPSHOT_DIR and uploads the images).
///
/// ImageRenderer is used instead of a home screen UI test because WidgetKit
/// offers no API to place a widget on the simulator home screen; tapping
/// through the widget gallery is slow and breaks with every iOS release.
/// Outside WidgetKit `containerBackground` draws nothing, so the harness paints
/// the same `widget_background` color asset behind the view.
@MainActor
struct WidgetSnapshotTests {

  private static let sizes: [(WidgetFamily, String, CGSize)] = [
    (.systemSmall, "small", CGSize(width: 170, height: 170)),
    (.systemMedium, "medium", CGSize(width: 364, height: 170)),
  ]

  private static let playing = LinefmEntry(
    date: Date(),
    stationSlug: "linefm",
    stationName: "LineFM +MAIN",
    title: "Night Drive",
    artist: "Example Artist",
    playing: true,
    coverPath: nil,
    idleText: "LINEFM Radio"
  )

  private func render(
    _ family: WidgetFamily, size: CGSize, scheme: ColorScheme
  ) -> UIImage? {
    let view = LinefmWidgetView(entry: Self.playing, familyOverride: family)
      .padding(16)
      .frame(width: size.width, height: size.height)
      .background(Color("widget_background"))
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      .environment(\.colorScheme, scheme)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    return renderer.uiImage
  }

  /// Relative luminance of the pixel at (x, y) in points, 0 = black, 1 = white.
  private func luminance(_ image: UIImage, x: Int, y: Int) -> Double {
    guard let cg = image.cgImage else { return -1 }
    var pixel = [UInt8](repeating: 0, count: 4)
    let space = CGColorSpaceCreateDeviceRGB()
    guard
      let ctx = CGContext(
        data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return -1 }
    let scale = Int(image.scale)
    ctx.draw(
      cg,
      in: CGRect(
        x: -x * scale, y: -(cg.height - 1 - y * scale), width: cg.width, height: cg.height))
    return (0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1]) + 0.0722 * Double(pixel[2]))
      / 255
  }

  private func save(_ image: UIImage, name: String) throws {
    guard let dir = ProcessInfo.processInfo.environment["WIDGET_SNAPSHOT_DIR"], !dir.isEmpty
    else { return }
    let url = URL(fileURLWithPath: dir, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    let data = try #require(image.pngData())
    try data.write(to: url.appendingPathComponent("widget-\(name).png"))
  }

  @Test func widgetFollowsLightAndDarkMode() throws {
    for (family, name, size) in Self.sizes {
      let light = try #require(render(family, size: size, scheme: .light))
      let dark = try #require(render(family, size: size, scheme: .dark))
      try save(light, name: "\(name)-light")
      try save(dark, name: "\(name)-dark")

      // Background sampled near the bottom right corner, away from text.
      let x = Int(size.width) - 24
      let y = Int(size.height) - 24
      let lightBg = luminance(light, x: x, y: y)
      let darkBg = luminance(dark, x: x, y: y)
      #expect(lightBg > 0.7, "\(name): light background too dark (\(lightBg))")
      #expect(darkBg >= 0 && darkBg < 0.3, "\(name): dark background too light (\(darkBg))")
    }
  }
}
