import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/data/api/laut_parsers.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Titelwechsel-Nachricht des WebSockets, bereits auf unsere Slugs gefiltert.
class SongChange {
  const SongChange({
    required this.stationSlug,
    required this.track,
    this.isLive = false,
  });

  final String stationSlug;
  final Track track;

  /// Sender laeuft gerade als Live-Sendung (siehe `LautSong`).
  final bool isLive;
}

/// Zustand der WebSocket-Verbindung.
enum SongChangeSocketState {
  /// Nicht verbunden und nicht gewuenscht.
  idle,
  connecting,
  connected,

  /// Verbindung verloren, naechster Versuch per Backoff geplant.
  reconnecting,

  /// Nach [WebSocketSongChangeSocket.maxFailures] Fehlschlaegen in Folge
  /// fuer [WebSocketSongChangeSocket.cooldown] aus; nur Polling.
  coolingDown,

  /// Traffic-Waechter hat abgeschaltet (Budget ueberschritten oder
  /// Plattform nicht freigegeben); nur Polling.
  blockedByTraffic,
}

/// WebSocket wss://api.laut.fm/song_change.ws.json mit Reconnect und
/// Traffic-Waechter (Spec 3.3).
abstract interface class SongChangeSocket {
  Stream<SongChange> get changes;

  Future<void> connect();

  Future<void> close();
}

class StubSongChangeSocket implements SongChangeSocket {
  const StubSongChangeSocket();

  @override
  Stream<SongChange> get changes => const Stream<SongChange>.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}
}

/// Traffic-Waechter fuer den Titelwechsel-WebSocket.
///
/// Messung 18.11.2026 (10 min, siehe P03-Bericht): Der Kanal liefert die
/// Wechsel ALLER laut.fm-Sender, ca. 1 Frame pro Sekunde mit im Mittel
/// ca. 37 KB, zusammen ca. 2,2 MB/min (etwa so viel wie der 256-kbit/s-
/// Audiostream selbst). Das liegt um mehr als das 20-Fache ueber der
/// Schwelle von 100 KB/min aus Spec 3.3.
///
/// Entscheidung des Inhabers (19.11.2026): Der WebSocket ist auf ALLEN
/// Plattformen aus (`WS_ENABLED=false`). Titelwechsel kommen aus
/// ends_at-Timer plus Polling. Der Code bleibt hinter dem Schalter; wird er
/// bewusst eingeschaltet, gilt zusaetzlich: auf Android und iOS (nativ und
/// mobiler Browser) nie, weil mobile Daten nicht erkennbar sind; auf
/// Desktop nur, solange das Volumen im gleitenden 60-s-Fenster unter
/// [maxKbPerMinute] bleibt.
class TrafficGuard {
  TrafficGuard({
    this.maxKbPerMinute = defaultDesktopBudgetKbPerMinute,
    bool? platformAllowed,
    this._clock = const SystemClock(),
  }) : platformAllowed = platformAllowed ?? platformAllowsWebSocket();

  /// Schwelle aus Spec 3.3 fuer getaktete (mobile) Verbindungen.
  static const int meteredThresholdKbPerMinute = 100;

  /// Budget auf Desktop: rund das Doppelte des gemessenen Volumens. Waechst
  /// der laut.fm-Kanal weiter, schaltet der Waechter auf Polling um.
  static const int defaultDesktopBudgetKbPerMinute = 4500;

  final int maxKbPerMinute;
  final bool platformAllowed;
  final Clock _clock;
  final List<(DateTime, int)> _samples = <(DateTime, int)>[];

  /// `true` nur auf Desktop-Plattformen (nativ oder Browser).
  static bool platformAllowsWebSocket([TargetPlatform? platform]) {
    switch (platform ?? defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void record(int bytes) {
    _samples.add((_clock.now(), bytes));
    _trim();
  }

  /// Bytes im gleitenden 60-s-Fenster, umgerechnet in KB/min.
  double get kbPerMinute {
    _trim();
    var sum = 0;
    for (final (_, bytes) in _samples) {
      sum += bytes;
    }
    return sum / 1024;
  }

  bool get exceeded => kbPerMinute > maxKbPerMinute;

  bool get allowed => platformAllowed && !exceeded;

  void reset() => _samples.clear();

  void _trim() {
    final cutoff = _clock.now().subtract(const Duration(minutes: 1));
    _samples.removeWhere((s) => s.$1.isBefore(cutoff));
  }
}

typedef WebSocketConnector = WebSocketChannel Function(Uri uri);

/// Echte WebSocket-Anbindung. Nur erzeugen, wenn `AppConfig.wsEnabled`
/// ausdruecklich `true` ist (Standard aus, siehe [TrafficGuard]).
///
/// - Frames sind JSONL (mehrere Wechsel je Frame); nur Zeilen unserer
///   Sender werden geparst.
/// - Reconnect mit exponentiellem Backoff 2 s -> 60 s plus Jitter; nach
///   [maxFailures] Fehlschlaegen in Folge [cooldown] Pause.
/// - [TrafficGuard] prueft Plattform und Volumen; bei Ueberschreitung wird
///   getrennt und erst nach [cooldown] erneut versucht.
class WebSocketSongChangeSocket implements SongChangeSocket {
  WebSocketSongChangeSocket({
    Uri? uri,
    Set<String>? slugs,
    WebSocketConnector? connector,
    TrafficGuard? guard,
    Random? random,
    this.minBackoff = const Duration(seconds: 2),
    this.maxBackoff = const Duration(seconds: 60),
    this.cooldown = const Duration(minutes: 10),
    this.maxFailures = 3,
  }) : uri = uri ?? Uri.parse('wss://api.laut.fm/song_change.ws.json'),
       _fixedSlugs = slugs,
       _connector = connector ?? WebSocketChannel.connect,
       guard = guard ?? TrafficGuard(),
       _random = random ?? Random();

  final Uri uri;

  /// Kuerzel, deren Titelwechsel zaehlen: fest (Tests) oder die aktuelle
  /// Senderliste (nachgeladene Sender eingeschlossen).
  Set<String> get slugs {
    final fixed = _fixedSlugs;
    if (fixed != null) return fixed;
    final list = stationsCatalog;
    if (!identical(list, _slugSource)) {
      _slugSource = list;
      _catalogSlugs = <String>{for (final s in list) s.slug};
    }
    return _catalogSlugs;
  }

  final Set<String>? _fixedSlugs;
  List<Object>? _slugSource;
  Set<String> _catalogSlugs = const <String>{};
  final TrafficGuard guard;
  final Duration minBackoff;
  final Duration maxBackoff;
  final Duration cooldown;
  final int maxFailures;
  final WebSocketConnector _connector;
  final Random _random;

  final StreamController<SongChange> _changes =
      StreamController<SongChange>.broadcast();
  final StreamController<SongChangeSocketState> _states =
      StreamController<SongChangeSocketState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _sub;
  Timer? _retry;
  bool _wanted = false;
  bool _receivedSinceOpen = false;
  int _failures = 0;
  SongChangeSocketState _state = SongChangeSocketState.idle;

  @override
  Stream<SongChange> get changes => _changes.stream;

  Stream<SongChangeSocketState> get states => _states.stream;

  SongChangeSocketState get state => _state;

  /// `true`, solange Titelwechsel live ankommen koennen.
  bool get isLive => _state == SongChangeSocketState.connected;

  @override
  Future<void> connect() async {
    _wanted = true;
    if (_channel != null || _retry != null) return;
    await _open();
  }

  @override
  Future<void> close() async {
    _wanted = false;
    _retry?.cancel();
    _retry = null;
    _failures = 0;
    await _teardown();
    _setState(SongChangeSocketState.idle);
  }

  /// Gibt alle Ressourcen frei; danach nicht mehr verwendbar.
  Future<void> dispose() async {
    await close();
    await _changes.close();
    await _states.close();
  }

  Future<void> _open() async {
    if (!_wanted) return;
    if (!guard.allowed) {
      _blockByTraffic();
      return;
    }
    _setState(SongChangeSocketState.connecting);
    _receivedSinceOpen = false;
    final WebSocketChannel channel;
    try {
      channel = _connector(uri);
      _channel = channel;
      await channel.ready;
    } on Object catch (e) {
      logError('WebSocket: Verbindung fehlgeschlagen', e);
      await _teardown();
      _onLost();
      return;
    }
    if (!_wanted || _channel != channel) {
      _closeQuietly(channel);
      return;
    }
    _setState(SongChangeSocketState.connected);
    _sub = channel.stream.listen(
      _onMessage,
      onError: (Object e) => logError('WebSocket: Fehler', e),
      onDone: () async {
        if (_channel != channel) return;
        await _teardown();
        _onLost();
      },
      cancelOnError: false,
    );
  }

  void _onMessage(Object? data) {
    final String text;
    if (data is String) {
      text = data;
    } else if (data is List<int>) {
      text = utf8.decode(data, allowMalformed: true);
    } else {
      return;
    }
    _receivedSinceOpen = true;
    _failures = 0;
    guard.record(text.length);
    if (guard.exceeded) {
      logInfo(
        'WebSocket: Traffic-Budget ueberschritten '
        '(${guard.kbPerMinute.round()} KB/min), wechsle auf Polling',
      );
      unawaited(_teardown().then((_) => _blockByTraffic()));
      return;
    }
    for (final song in LautParsers.parseSongChangeFrame(text, slugs)) {
      _changes.add(
        SongChange(
          stationSlug: song.stationSlug!,
          track: song.track,
          isLive: song.isLive,
        ),
      );
    }
  }

  void _onLost() {
    if (!_wanted) {
      _setState(SongChangeSocketState.idle);
      return;
    }
    _failures = _receivedSinceOpen ? 1 : _failures + 1;
    if (_failures >= maxFailures) {
      _failures = 0;
      _setState(SongChangeSocketState.coolingDown);
      _schedule(cooldown);
      return;
    }
    _setState(SongChangeSocketState.reconnecting);
    _schedule(backoffFor(_failures));
  }

  /// Wartezeit vor Versuch Nummer [failures] (ab 1), ohne Jitter gedeckelt.
  Duration backoffFor(int failures) {
    final factor = 1 << (failures - 1).clamp(0, 16);
    var delay = minBackoff * factor;
    if (delay > maxBackoff) delay = maxBackoff;
    final jitterMs = _random.nextInt(1000);
    return delay + Duration(milliseconds: jitterMs);
  }

  void _blockByTraffic() {
    _setState(SongChangeSocketState.blockedByTraffic);
    // Plattform gesperrt: kein erneuter Versuch. Budget: nach Pause neu.
    if (guard.platformAllowed && _wanted) {
      _schedule(cooldown, resetGuard: true);
    }
  }

  void _schedule(Duration delay, {bool resetGuard = false}) {
    _retry?.cancel();
    _retry = Timer(delay, () {
      _retry = null;
      if (resetGuard) guard.reset();
      unawaited(_open());
    });
  }

  Future<void> _teardown() async {
    final sub = _sub;
    final channel = _channel;
    _sub = null;
    _channel = null;
    await sub?.cancel();
    if (channel != null) _closeQuietly(channel);
  }

  /// Nicht abwarten: Bei nie zustande gekommener Verbindung kehrt
  /// `sink.close()` unter Umstaenden nie zurueck.
  static void _closeQuietly(WebSocketChannel channel) {
    unawaited(channel.sink.close().then<void>((_) {}, onError: (Object _) {}));
  }

  void _setState(SongChangeSocketState s) {
    if (_state == s) return;
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }
}
