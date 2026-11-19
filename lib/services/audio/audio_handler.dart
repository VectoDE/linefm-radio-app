import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/browse_tree.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/services/audio/radio_player.dart';
import 'package:linefm_radio/services/audio/reconnect_policy.dart';

/// Liefert die Stream-URL einer Station (Spec 3.3: `stream_url` aus der
/// API, Rueckfall `https://stream.laut.fm/{slug}`).
typedef StreamUrlResolver = Future<Uri> Function(Station station);

Future<Uri> _fallbackStreamUrl(Station station) async =>
    Uri.parse(station.fallbackStreamUrl);

/// Audio-Handler auf Basis audio_service + just_audio (Spec 2.2, 3.3).
///
/// Live-Radio: Stop statt Pause, Play verbindet neu. Verbinden zeigt
/// mindestens [minConnectDuration] den Status `connecting` (wie Web-App).
/// Nach Netzverlust bis zu 5 Neuverbindungen ([ReconnectPolicy]).
class LinefmAudioHandler extends BaseAudioHandler implements PlaybackService {
  LinefmAudioHandler({
    RadioPlayer? player,
    this.reconnectPolicy = const ReconnectPolicy(),
    this.minConnectDuration = const Duration(seconds: 1),
    this.connectTimeout = const Duration(seconds: 20),
    StreamUrlResolver? streamUrlResolver,
  }) : _player = player ?? JustAudioRadioPlayer(),
       streamUrlResolver = streamUrlResolver ?? _fallbackStreamUrl {
    _signalSub = _player.signals.listen(_onSignal);
    _publishPlaybackState();
  }

  final RadioPlayer _player;
  final ReconnectPolicy reconnectPolicy;
  final Duration minConnectDuration;
  final Duration connectTimeout;

  /// Kann von der App-Schicht (P11) gesetzt werden, um `stream_url` aus der
  /// laut.fm-API zu verwenden.
  StreamUrlResolver streamUrlResolver;

  late final StreamSubscription<RadioSignal> _signalSub;
  final StreamController<PlayerUiState> _controller =
      StreamController<PlayerUiState>.broadcast();
  final List<StreamSubscription<Object?>> _sessionSubs =
      <StreamSubscription<Object?>>[];

  PlayerUiState _state = const PlayerUiState();
  String? _errorMessage;

  /// Station, die laufen soll (null = gestoppt).
  Station? _desired;

  /// Zuletzt gespielte bzw. von der App gemeldete Station (Android Auto
  /// "recent", Play ohne Auswahl).
  Station? _recent;

  /// Letzter bekannter Titel je Station (Slug).
  final Map<String, Track?> _tracks = <String, Track?>{};

  /// Erhoeht sich bei jedem neuen Verbindungsauftrag; alte Auftraege
  /// erkennen daran, dass sie verworfen sind.
  int _generation = 0;
  int _reconnectAttempt = 0;
  DateTime? _connectStartedAt;
  Timer? _reconnectTimer;
  Timer? _timeoutTimer;
  Timer? _minDurationTimer;

  bool _ducked = false;
  bool _resumeAfterInterruption = false;

  // ------------------------------------------------------- PlaybackService

  @override
  PlayerUiState get state => _state;

  @override
  Stream<PlayerUiState> get stateStream => _controller.stream;

  /// Zuletzt gespielte Station (fuer Android Auto "recent").
  Station? get recentStation => _recent;

  /// Die App meldet die gespeicherte letzte Station, damit Android Auto und
  /// die Play-Taste ohne vorherige Auswahl einen Sender kennen.
  set recentStation(Station? station) {
    if (station == null) return;
    _recent = station;
    if (mediaItem.value == null) {
      mediaItem.add(
        BrowseTree.stationItem(station, track: _tracks[station.slug]),
      );
    }
  }

  /// Letzte Fehlermeldung (technisch, nicht fuer die UI gedacht).
  String? get lastError => _errorMessage;

  @override
  Future<void> playStation(Station station) async {
    final gen = ++_generation;
    _cancelTimers();
    _desired = station;
    _recent = station;
    _reconnectAttempt = 0;
    _resumeAfterInterruption = false;
    _errorMessage = null;
    mediaItem.add(
      BrowseTree.stationItem(station, track: _tracks[station.slug]),
    );
    _connectStartedAt = DateTime.now();
    _emit(_state.copyWith(status: PlayerStatus.connecting, station: station));
    await _connect(station, gen);
  }

  @override
  Future<void> stopPlayback() async {
    _generation++;
    _cancelTimers();
    _desired = null;
    _resumeAfterInterruption = false;
    _emit(_state.copyWith(status: PlayerStatus.idle));
    try {
      await _player.stop();
    } on Object catch (e) {
      _errorMessage = '$e';
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    _emit(_state.copyWith(volume: v));
    await _applyVolume();
  }

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async {
    _tracks[station.slug] = track;
    final current = _desired ?? _state.station ?? _recent;
    if (current == null || current == station) {
      mediaItem.add(BrowseTree.stationItem(station, track: track));
    }
  }

  @override
  Future<void> dispose() async {
    _generation++;
    _cancelTimers();
    for (final s in _sessionSubs) {
      await s.cancel();
    }
    await _signalSub.cancel();
    await _controller.close();
    await _player.dispose();
  }

  // --------------------------------------------------------- audio_service

  @override
  Future<void> play() async {
    final station =
        _desired ?? _recent ?? _state.station ?? stationsCatalog.first;
    await playStation(station);
  }

  /// Pause gibt es bei Live-Radio nicht: Benachrichtigung, Kopfhoerer- und
  /// Medientasten stoppen.
  @override
  Future<void> pause() => stopPlayback();

  @override
  Future<void> stop() => stopPlayback();

  @override
  Future<void> skipToNext() => _skip(1);

  @override
  Future<void> skipToPrevious() => _skip(-1);

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final station = stationBySlug(mediaId) ?? _recent ?? stationsCatalog.first;
    await playStation(station);
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final hits = BrowseTree.searchStations(query);
    final station = query.trim().isEmpty
        ? (_recent ?? stationsCatalog.first)
        : (hits.isEmpty ? (_recent ?? stationsCatalog.first) : hits.first);
    await playStation(station);
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final de = _isGerman();
    return BrowseTree.children(
      parentMediaId,
      recent: _recent,
      stationsTitle: de ? 'Stationen' : 'Stations',
      recentTitle: de ? 'Zuletzt gehört' : 'Recently played',
    );
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final station = stationBySlug(mediaId);
    return station == null
        ? null
        : BrowseTree.stationItem(station, track: _tracks[station.slug]);
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async => BrowseTree.search(query);

  @override
  Future<void> onTaskRemoved() => stopPlayback();

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    // MPRIS (Linux) meldet Lautstaerkeaenderungen als "dbusVolume".
    if (name == 'dbusVolume') {
      final value = extras?['value'];
      if (value is num) await setVolume(value.toDouble());
    }
    return null;
  }

  // ------------------------------------------------------- audio_session

  /// Konfiguriert die Audio-Sitzung (Musik, Unterbrechungen, Kopfhoerer
  /// abgezogen). Einmal nach dem Erzeugen aufrufen.
  Future<void> initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionSubs
      ..add(session.interruptionEventStream.listen(_onInterruption))
      ..add(session.becomingNoisyEventStream.listen((_) => stopPlayback()));
  }

  void _onInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _ducked = true;
          unawaited(_applyVolume());
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          final wasActive = _desired != null;
          if (wasActive) {
            final station = _desired;
            unawaited(stopPlayback());
            _recent = station;
          }
          _resumeAfterInterruption = wasActive;
      }
    } else {
      switch (event.type) {
        case AudioInterruptionType.duck:
          _ducked = false;
          unawaited(_applyVolume());
        case AudioInterruptionType.pause:
          if (_resumeAfterInterruption && _recent != null) {
            unawaited(playStation(_recent!));
          }
          _resumeAfterInterruption = false;
        case AudioInterruptionType.unknown:
          _resumeAfterInterruption = false;
      }
    }
  }

  /// Fuer Tests: simuliert ein Unterbrechungsereignis.
  void debugInterrupt({required bool begin, bool duck = false}) =>
      _onInterruption(
        AudioInterruptionEvent(
          begin,
          duck ? AudioInterruptionType.duck : AudioInterruptionType.pause,
        ),
      );

  // ------------------------------------------------------------- intern

  Future<void> _connect(Station station, int gen) async {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(connectTimeout, () {
      if (gen == _generation) _onFailure('timeout');
    });
    try {
      final url = await streamUrlResolver(station);
      if (gen != _generation) return;
      await _player.open(url);
    } on Object catch (e) {
      if (gen == _generation) _onFailure('$e');
    }
  }

  void _onSignal(RadioSignal signal) {
    if (_desired == null) return;
    switch (signal) {
      case RadioSignal.playing:
        _timeoutTimer?.cancel();
        _reconnectAttempt = 0;
        _markPlaying();
      case RadioSignal.buffering:
        // Kurzes Nachpuffern im laufenden Betrieb aendert den Status nicht.
        break;
      case RadioSignal.ended:
      case RadioSignal.error:
        _onFailure(signal.name);
      case RadioSignal.idle:
        break;
    }
  }

  void _markPlaying() {
    if (_state.status == PlayerStatus.playing) return;
    final gen = _generation;
    final started = _connectStartedAt;
    final elapsed = started == null
        ? minConnectDuration
        : DateTime.now().difference(started);
    final remaining = minConnectDuration - elapsed;
    if (_state.status == PlayerStatus.connecting && remaining > Duration.zero) {
      _minDurationTimer?.cancel();
      _minDurationTimer = Timer(remaining, () {
        if (gen == _generation && _desired != null) {
          _emit(_state.copyWith(status: PlayerStatus.playing));
        }
      });
      return;
    }
    _emit(_state.copyWith(status: PlayerStatus.playing));
  }

  void _onFailure(String reason) {
    final station = _desired;
    if (station == null) return;
    // Mehrfachmeldung desselben Abbruchs, Neuverbindung ist schon geplant.
    if (_reconnectTimer?.isActive ?? false) return;
    _errorMessage = reason;
    _timeoutTimer?.cancel();
    _minDurationTimer?.cancel();
    // Erstes Verbinden gescheitert: sofort Fehler (UI zeigt Retry).
    // Abbruch einer laufenden Wiedergabe: automatisch neu verbinden.
    final wasEstablished =
        _state.status == PlayerStatus.playing ||
        _state.status == PlayerStatus.reconnecting;
    final delay = wasEstablished
        ? reconnectPolicy.delayFor(_reconnectAttempt)
        : null;
    if (delay == null) {
      _generation++;
      _desired = null;
      _cancelTimers();
      _emit(_state.copyWith(status: PlayerStatus.error));
      unawaited(_player.stop().catchError((Object _) {}));
      return;
    }
    _reconnectAttempt++;
    final gen = ++_generation;
    _emit(_state.copyWith(status: PlayerStatus.reconnecting));
    unawaited(_player.stop().catchError((Object _) {}));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (gen == _generation && _desired == station) {
        unawaited(_connect(station, gen));
      }
    });
  }

  Future<void> _skip(int step) async {
    final current = _desired ?? _state.station ?? _recent;
    final index = current == null ? -1 : stationsCatalog.indexOf(current);
    final n = stationsCatalog.length;
    final next = stationsCatalog[((index < 0 ? 0 : index + step) % n + n) % n];
    await playStation(next);
  }

  Future<void> _applyVolume() async {
    final v = _ducked ? _state.volume * 0.3 : _state.volume;
    try {
      await _player.setVolume(v);
    } on Object catch (e) {
      _errorMessage = '$e';
    }
  }

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _timeoutTimer?.cancel();
    _minDurationTimer?.cancel();
  }

  void _emit(PlayerUiState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
    _publishPlaybackState();
  }

  void _publishPlaybackState() {
    playbackState.add(
      playbackStateFor(_state.status, errorMessage: _errorMessage),
    );
  }

  static bool _isGerman() =>
      PlatformDispatcher.instance.locale.languageCode == 'de';

  /// Abbildung auf den audio_service-Zustand (Benachrichtigung,
  /// Sperrbildschirm, Android Auto, Media Session, MPRIS).
  static PlaybackState playbackStateFor(
    PlayerStatus status, {
    String? errorMessage,
  }) {
    final active =
        status == PlayerStatus.playing ||
        status == PlayerStatus.connecting ||
        status == PlayerStatus.reconnecting;
    final processing = switch (status) {
      PlayerStatus.idle => AudioProcessingState.idle,
      PlayerStatus.connecting => AudioProcessingState.loading,
      PlayerStatus.reconnecting => AudioProcessingState.buffering,
      PlayerStatus.playing => AudioProcessingState.ready,
      PlayerStatus.error => AudioProcessingState.error,
    };
    return PlaybackState(
      controls: <MediaControl>[
        MediaControl.skipToPrevious,
        if (active) MediaControl.stop else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const <MediaAction>{
        MediaAction.playFromMediaId,
        MediaAction.playFromSearch,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
        MediaAction.playPause,
      },
      androidCompactActionIndices: const <int>[0, 1, 2],
      processingState: processing,
      playing: active,
      errorMessage: status == PlayerStatus.error ? errorMessage : null,
    );
  }
}
