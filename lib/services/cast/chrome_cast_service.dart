import 'dart:async';

import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';

/// Cast-Dienst über [CastBackend] (Default Media Receiver).
///
/// - Zustand = Geräteliste + Sitzung des Backends.
/// - [cast] lädt den MP3-Live-Stream samt Titel/Künstler/Cover. Der Default
///   Media Receiver kennt kein Metadaten-Update ohne neues Laden; [updateTrack]
///   lädt deshalb bei Titelwechsel neu (kurzes Neupuffern am Gerät).
/// - Ladevorgänge laufen nacheinander; veraltete Aufträge (Sender oder Titel
///   inzwischen geändert) werden verworfen.
class ChromeCastService implements CastService {
  ChromeCastService({required this._backend, required this._resolveStreamUrl}) {
    _state = _compose();
    _subs
      ..add(_backend.devicesStream.listen((_) => _refresh()))
      ..add(_backend.linkStream.listen(_onLink));
  }

  final CastBackend _backend;
  final Future<Uri> Function(Station station) _resolveStreamUrl;
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  final StreamController<CastState> _controller =
      StreamController<CastState>.broadcast();

  late CastState _state;
  Future<void>? _running;
  (Station, Track?)? _desired;
  Station? _castStation;
  bool _force = false;
  CastMedia? _loaded;
  bool _disposed = false;

  @override
  CastState get state => _state;

  @override
  Stream<CastState> get states {
    // Aktueller Zustand zuerst, danach lückenlos die Änderungen.
    late final StreamController<CastState> out;
    StreamSubscription<CastState>? inner;
    out = StreamController<CastState>(
      onListen: () {
        out.add(_state);
        inner = _controller.stream.listen(out.add, onDone: out.close);
      },
      onCancel: () => inner?.cancel(),
    );
    return out.stream;
  }

  CastState _compose() {
    final link = _backend.link;
    final connected = link.link == CastLink.connected ? link.device : null;
    return CastState(
      available: true,
      devices: List<CastDevice>.unmodifiable(_backend.devices),
      connectedDevice: connected,
      connecting: link.link == CastLink.connecting,
    );
  }

  void _refresh() {
    if (_disposed) return;
    final next = _compose();
    if (next == _state) return;
    _state = next;
    _controller.add(next);
  }

  void _onLink(CastLinkState link) {
    if (link.link != CastLink.connected) {
      // Sitzung weg: geladenes Medium und offene Wünsche vergessen.
      _desired = null;
      _castStation = null;
      _force = false;
      _loaded = null;
    }
    _refresh();
  }

  @override
  Future<void> startDiscovery({bool activeScan = false}) async {
    try {
      await _backend.startDiscovery(activeScan: activeScan);
    } on Object catch (e) {
      logError('Cast-Suche nicht gestartet', e);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _backend.stopDiscovery();
    } on Object catch (e) {
      logError('Cast-Suche nicht beendet', e);
    }
  }

  @override
  Future<void> connect(CastDevice device) async {
    if (_state.isCasting || _state.connecting) return;
    try {
      final started = await _backend.startSession(device);
      if (!started) logError('Cast-Sitzung nicht gestartet', device.name);
    } on Object catch (e) {
      logError('Cast-Verbindung fehlgeschlagen', e);
    }
  }

  @override
  Future<void> disconnect() async {
    _desired = null;
    _castStation = null;
    _loaded = null;
    try {
      await _backend.endSession();
    } on Object catch (e) {
      logError('Cast-Sitzung nicht beendet', e);
    }
  }

  @override
  Future<void> cast(Station station, Track? track) {
    _castStation = station;
    _desired = (station, track);
    _force = true;
    return _pump();
  }

  @override
  Future<void> updateTrack(Station station, Track? track) {
    // Nur nachziehen, wenn genau dieser Sender übergeben wurde.
    if (_castStation != station) return _running ?? Future<void>.value();
    _desired = (station, track);
    return _pump();
  }

  @override
  Future<void> setVolume(double volume) async {
    if (!_state.isCasting) return;
    try {
      _backend.setVolume(volume.clamp(0.0, 1.0));
    } on Object catch (e) {
      logError('Cast-Lautstärke nicht gesetzt', e);
    }
  }

  /// Lädt nacheinander, bis der gewünschte Stand läuft; Zwischenstände
  /// (schneller Titel- oder Senderwechsel) werden übersprungen.
  Future<void> _pump() => _running ??= _drain().whenComplete(() {
    _running = null;
  });

  Future<void> _drain() async {
    while (!_disposed) {
      final wanted = _desired;
      final force = _force;
      _desired = null;
      _force = false;
      if (wanted == null || !_state.isCasting) return;
      final (station, track) = wanted;
      try {
        final url = await _resolveStreamUrl(station);
        // Während der Auflösung neu gewünscht oder Sitzung beendet.
        if (_desired != null) {
          _force = _force || force;
          continue;
        }
        if (_disposed || !_state.isCasting) return;
        final media = buildCastMedia(station, track, url);
        if (!force && media == _loaded) continue;
        _loaded = media;
        await _backend.load(media);
      } on Object catch (e) {
        _loaded = null;
        logError('Cast-Wiedergabe nicht gestartet', e);
        if (_desired != null) continue;
        return;
      }
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _desired = null;
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _controller.close();
    await _backend.dispose();
  }
}

/// Metadaten für den Receiver: Titel/Künstler/Cover des Songs, sonst Sender
/// und Senderlogo. Nur https-Cover (Receiver und Mixed-Content).
CastMedia buildCastMedia(Station station, Track? track, Uri streamUrl) {
  Uri? https(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }

  return CastMedia(
    streamUrl: streamUrl,
    title: track?.title ?? station.displayName,
    artist: track?.artist ?? 'LINEFM',
    stationName: station.displayName,
    imageUrl: https(track?.artworkUrl) ?? https(station.logoUrl),
  );
}
