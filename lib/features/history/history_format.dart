/// Uhrzeit im Verlauf als `HH:mm` in lokaler Zeit (wie `formatTime` der
/// Web-App, aber unabhaengig von der Systemsprache immer 24-Stunden).
String formatClock(DateTime time) {
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}
