import 'dart:async';

import 'package:linefm_radio/services/cast/cast_service.dart';

/// Verbindungsphase der Cast-Sitzung.
enum CastLink { disconnected, connecting, connected, disconnecting }

/// Zustand der Sitzung samt Gerät (nur bei verbundener/verbindender Sitzung).
class CastLinkState {
  const CastLinkState(this.link, [this.device]);

  static const CastLinkState none = CastLinkState(CastLink.disconnected);

  final CastLink link;
  final CastDevice? device;

  @override
  bool operator ==(Object other) =>
      other is CastLinkState && other.link == link && other.device == device;

  @override
  int get hashCode => Object.hash(link, device);
}

/// Medium, das auf dem Cast-Gerät läuft: MP3-Live-Stream mit Metadaten.
class CastMedia {
  const CastMedia({
    required this.streamUrl,
    required this.title,
    required this.artist,
    required this.stationName,
    this.imageUrl,
  });

  final Uri streamUrl;
  final String title;
  final String artist;
  final String stationName;
  final Uri? imageUrl;

  @override
  bool operator ==(Object other) =>
      other is CastMedia &&
      other.streamUrl == streamUrl &&
      other.title == title &&
      other.artist == artist &&
      other.stationName == stationName &&
      other.imageUrl == imageUrl;

  @override
  int get hashCode =>
      Object.hash(streamUrl, title, artist, stationName, imageUrl);

  @override
  String toString() => 'CastMedia($artist - $title @ $stationName)';
}

/// Dünne Schicht über dem Cast-Plugin. Trennt die Logik ([ChromeCastService])
/// vom Plugin, damit sie ohne Gerät testbar ist.
abstract interface class CastBackend {
  List<CastDevice> get devices;

  Stream<List<CastDevice>> get devicesStream;

  CastLinkState get link;

  Stream<CastLinkState> get linkStream;

  /// [activeScan]: aktive Suche, solange der Geräte-Dialog offen ist
  /// (Android sucht sonst nur passiv).
  Future<void> startDiscovery({bool activeScan = false});

  Future<void> stopDiscovery();

  /// `false`, wenn die Sitzung nicht gestartet werden konnte.
  Future<bool> startSession(CastDevice device);

  Future<void> endSession();

  /// Lädt [media] als Live-Stream auf den Default Media Receiver und startet.
  Future<void> load(CastMedia media);

  /// Lautstärke des Cast-Geräts, 0.0 bis 1.0.
  void setVolume(double volume);

  Future<void> dispose();
}

/// Vom Start (`initCast`) gesetzt; `null` auf Plattformen ohne Cast, ohne
/// Google Play Services oder wenn die Initialisierung scheitert.
CastBackend? castBackend;
