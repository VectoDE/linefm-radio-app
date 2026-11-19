import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/stations/favorite_stations.dart';
import 'package:linefm_radio/platform/deep_links.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

/// Grobe Klasse fuer die Hoerdauer beim Ereignis `stop` (keine genauen
/// Werte, Datensparsamkeit, Spec 2.3).
String secondsBucket(int seconds) {
  if (seconds < 10) return '<10';
  if (seconds < 60) return '10-59';
  if (seconds < 300) return '60-299';
  if (seconds < 900) return '300-899';
  if (seconds < 1800) return '900-1799';
  if (seconds < 3600) return '1800-3599';
  return '3600+';
}

/// Wiedergabe-Logik der App (Web-App: togglePlayback, selectStation,
/// startStation, shuffleStation) plus alles, was an der Wiedergabe haengt:
///
/// - Telemetrie `play`, `stop` {station, seconds_bucket} und `error_stream`
///   an genau EINER Stelle. Grundlage ist der Zustand des Audio-Dienstes,
///   deshalb zaehlen auch Starts ueber Benachrichtigung, Medientasten,
///   Android Auto, Wecker und Autoplay; Neuverbindungen zaehlen nicht doppelt.
/// - Startet das System (Android Auto, Medientasten) einen anderen Sender,
///   folgt die gewaehlte Station.
/// - Titel und Sender gehen an Benachrichtigung/Sperrbildschirm und das
///   Homescreen-Widget.
/// - Stream-URL aus der laut.fm-API (`stream_url`), Rueckfall
///   `https://stream.laut.fm/{slug}`.
/// - Start: gemerkte Lautstaerke, `?station=` im Link, Autoplay (abschaltbar;
///   im Web erst nach der ersten Nutzeraktion, Autoplay-Sperre der Browser).
class PlayerController {
  PlayerController(this._ref) {
    final service = _ref.read(playbackServiceProvider);
    _last = service.state;
    _stateSub = service.stateStream.listen(_onState);
    if (service is LinefmAudioHandler) {
      service
        ..streamUrlResolver = _resolveStreamUrl
        ..recentStation = _ref.read(activeStationProvider);
    }
    // Favoriten-Sender laden; der Notifier meldet sie beim Aufbau an den
    // Audio-Dienst (Android-Auto-Ordner), auch ohne Stations-Screen.
    _ref.read(favoriteStationsProvider);
    _ref
      ..listen<Station>(activeStationProvider, (_, next) {
        final s = _ref.read(playbackServiceProvider);
        if (s is LinefmAudioHandler) s.recentStation = next;
        _pushNowPlaying();
      })
      ..listen<AsyncValue<Track?>>(
        currentTrackProvider,
        (_, _) => _pushNowPlaying(),
      )
      ..onDispose(() {
        unawaited(_stateSub.cancel());
        unawaited(_deepLinkSub?.cancel());
        _autoplayTimer?.cancel();
      });
    _pushNowPlaying();
  }

  final Ref _ref;
  late final StreamSubscription<PlayerUiState> _stateSub;
  StreamSubscription<Uri>? _deepLinkSub;
  Timer? _autoplayTimer;

  late PlayerUiState _last;
  DateTime? _playStartedAt;
  bool _startedUp = false;
  bool _autoplayPending = false;
  bool _userStarted = false;
  (Station, Track?, bool)? _pushed;
  final Map<String, Uri> _streamUrls = <String, Uri>{};

  PlaybackService get _service => _ref.read(playbackServiceProvider);

  // ------------------------------------------------------------ Steuerung

  /// Waehlt die Station, ohne abzuspielen.
  Future<void> selectStation(Station station) async {
    _ref.read(activeStationProvider.notifier).select(station);
  }

  /// Waehlt die Station und spielt sie ab.
  Future<void> startStation(Station station) async {
    _userStarted = true;
    _autoplayPending = false;
    await selectStation(station);
    await _service.playStation(station);
  }

  /// Play/Stop fuer die gewaehlte Station (Live-Radio: Stop statt Pause).
  Future<void> togglePlayback() async {
    final state = _service.state;
    final active = _ref.read(activeStationProvider);
    final playingActive =
        (state.isPlaying || state.isBusy) &&
        (state.station == null || state.station == active);
    if (playingActive) {
      _userStarted = true;
      await _service.stopPlayback();
    } else {
      await startStation(active);
    }
  }

  Future<void> stop() => _service.stopPlayback();

  /// Spielt eine zufaellige ANDERE Station (Web-App-Verhalten).
  Future<void> shuffleStation([Random? random]) async {
    final current = _ref.read(activeStationProvider);
    final others = stationsCatalog.where((s) => s != current).toList();
    final next = others[(random ?? Random()).nextInt(others.length)];
    await startStation(next);
  }

  /// Lautstaerke 0.1 bis 1.0; gemerkt, wenn "Lautstaerke merken" an ist.
  Future<void> setVolume(double volume) async {
    await _service.setVolume(volume);
    if (_ref.read(settingsProvider).rememberVolume) {
      await _ref.read(prefsProvider).writeVolume(volume);
    }
  }

  // ---------------------------------------------------------------- Start

  /// Einmal beim Start der Shell. [launchUri]: Start-Link (Web `Uri.base`),
  /// [web]: Autoplay erst nach der ersten Nutzeraktion.
  Future<void> startup({Uri? launchUri, required bool web}) async {
    if (_startedUp) return;
    _startedUp = true;
    final settings = _ref.read(settingsProvider);
    if (settings.rememberVolume) {
      final volume = _ref.read(prefsProvider).readVolume();
      if (volume != null) await _service.setVolume(volume);
    }

    final linked = launchUri == null
        ? null
        : DeepLinks.stationFromUri(launchUri);
    if (linked != null) await selectStation(linked);

    _deepLinkSub = DeepLinks.stream.listen((uri) {
      final station = DeepLinks.stationFromUri(uri);
      if (station != null) unawaited(startStation(station));
    });

    if (!settings.autoplay) return;
    final state = _service.state;
    if (state.isPlaying || state.isBusy) return;
    if (web) {
      _autoplayPending = true;
      return;
    }
    await _service.playStation(_ref.read(activeStationProvider));
  }

  /// Erste Nutzeraktion im Web: Autoplay nachholen, sofern der Nutzer nicht
  /// selbst gerade etwas gestartet oder gestoppt hat. Kurze Verzoegerung,
  /// damit der Tipp zuerst seine eigene Aktion ausloesen kann; die
  /// Nutzeraktivierung des Browsers gilt einige Sekunden.
  void onUserInteraction() {
    if (!_autoplayPending) return;
    _autoplayPending = false;
    _autoplayTimer = Timer(const Duration(milliseconds: 350), () {
      final state = _service.state;
      if (_userStarted || state.isPlaying || state.isBusy) return;
      unawaited(_service.playStation(_ref.read(activeStationProvider)));
    });
  }

  /// Wartet auf eine Nutzeraktion fuer das Web-Autoplay (Tests/Diagnose).
  bool get autoplayPending => _autoplayPending;

  // ------------------------------------------------------------- intern

  void _onState(PlayerUiState next) {
    final prev = _last;
    _last = next;
    final wasActive = prev.isPlaying || prev.isBusy;
    final isActive = next.isPlaying || next.isBusy;
    final Station? before = prev.station;
    final Station after =
        next.station ?? before ?? _ref.read(activeStationProvider);
    final switched = before != null && before != after;

    if (wasActive && isActive && switched) {
      _stopEvent(before);
      _playEvent(after);
    } else if (!wasActive && isActive) {
      _playEvent(after);
    } else if (wasActive && !isActive) {
      if (next.status == PlayerStatus.error) {
        _playStartedAt = null;
      } else {
        _stopEvent(before ?? after);
      }
    }
    if (next.status == PlayerStatus.error &&
        prev.status != PlayerStatus.error) {
      _event('error_stream', <String, Object>{'station': after.slug});
    }

    // Vom System gestarteter Sender (Android Auto, Medientasten, Wecker):
    // die Auswahl folgt der Wiedergabe.
    if (isActive &&
        (switched || !wasActive) &&
        _ref.read(activeStationProvider) != after) {
      _ref.read(activeStationProvider.notifier).select(after);
    }
    if (prev.isPlaying != next.isPlaying) _pushNowPlaying();
  }

  void _playEvent(Station station) {
    _playStartedAt = _ref.read(clockProvider).now();
    _event('play', <String, Object>{'station': station.slug});
  }

  void _stopEvent(Station station) {
    final started = _playStartedAt;
    _playStartedAt = null;
    _event('stop', <String, Object>{
      'station': station.slug,
      if (started != null)
        'seconds_bucket': secondsBucket(
          _ref.read(clockProvider).now().difference(started).inSeconds,
        ),
    });
  }

  void _event(String name, Map<String, Object> props) {
    _ref.read(telemetryProvider).event(name, props).ignore();
  }

  void _pushNowPlaying() {
    final station = _ref.read(activeStationProvider);
    final track = _ref.read(currentTrackProvider).value;
    final playing = _last.isPlaying;
    final key = (station, track, playing);
    if (_pushed == key) return;
    _pushed = key;
    _service.updateNowPlaying(station, track).ignore();
    _ref
        .read(homeWidgetSyncProvider)
        .update(station: station, track: track, playing: playing)
        .ignore();
  }

  Future<Uri> _resolveStreamUrl(Station station) async {
    final known = _streamUrls[station.slug];
    if (known != null) return known;
    final fallback = Uri.parse(station.fallbackStreamUrl);
    try {
      final url = await _ref
          .read(lautApiProvider)
          .streamUrl(station.slug)
          .timeout(const Duration(seconds: 4));
      final uri = url == null ? null : Uri.tryParse(url);
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        _streamUrls[station.slug] = uri;
        return uri;
      }
    } on Object catch (e) {
      logError('stream_url nicht ermittelt, Rueckfall', e);
    }
    return fallback;
  }
}
