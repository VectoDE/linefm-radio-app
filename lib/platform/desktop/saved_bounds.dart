import 'dart:ui';

/// Gemerkte Fenstergeometrie: `x;y;breite;hoehe;maximiert`.
class SavedBounds {
  const SavedBounds(this.rect, {this.maximized = false});

  final Rect rect;
  final bool maximized;

  String encode() =>
      '${rect.left.round()};${rect.top.round()};${rect.width.round()};'
      '${rect.height.round()};${maximized ? 1 : 0}';

  /// Liest den Text und verwirft unsinnige Werte (zu klein, riesig, weit
  /// ausserhalb jedes Bildschirms, z. B. nach einem abgesteckten Monitor).
  static SavedBounds? decode(String? text, {Size? minimum}) {
    if (text == null) return null;
    final parts = text.split(';');
    if (parts.length < 4) return null;
    final v = <double>[];
    for (final part in parts.take(4)) {
      final n = double.tryParse(part);
      if (n == null || !n.isFinite) return null;
      v.add(n);
    }
    final rect = Rect.fromLTWH(v[0], v[1], v[2], v[3]);
    final minW = minimum?.width ?? 200;
    final minH = minimum?.height ?? 100;
    if (rect.width < minW || rect.height < minH) return null;
    if (rect.width > 10000 || rect.height > 10000) return null;
    if (rect.left.abs() > 20000 || rect.top.abs() > 20000) return null;
    // Mindestens ein Stueck der Titelleiste muss auf dem (Haupt-)Bildschirm
    // erreichbar sein.
    final display = PlatformDispatcher.instance.displays.firstOrNull;
    if (display != null) {
      final w = display.size.width / display.devicePixelRatio;
      final h = display.size.height / display.devicePixelRatio;
      if (rect.left > w * 2 || rect.top > h * 2) return null;
      if (rect.right < -w || rect.bottom < -h) return null;
    }
    final maximized = parts.length > 4 && parts[4] == '1';
    return SavedBounds(rect, maximized: maximized);
  }
}
