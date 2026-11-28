import 'dart:async';

import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

/// Sleeptimer mit Ausblenden und "Ende des Songs" (Spec 4.2 Nr. 9).
abstract interface class SleepTimerService {
  SleepTimerState get state;

  Stream<SleepTimerState> get states;

  Future<void> start(SleepTimerMode mode, {Track? currentTrack});

  Future<void> cancel();

  Future<void> dispose();
}

/// Ist "Ende des Songs" moeglich? Nur, wenn der laufende Titel ein bekanntes
/// Ende in der Zukunft hat. Bei Live-Sendungen (`live: true`) kennt laut.fm
/// die Laenge nicht; der Parser verwirft dort den Platzhalter-`ends_at`, der
/// Titel hat dann kein Ende und die Option bleibt gesperrt.
bool sleepTimerEndOfSongAvailable(Track? track, DateTime now) {
  final end = track?.endsAt;
  return end != null && end.isAfter(now);
}

/// Echter Sleeptimer: zaehlt gegen die [Clock], blendet die Lautstaerke in
/// den letzten [SleepTimerLogic.fadeLead] linear aus, stoppt die Wiedergabe
/// und stellt danach die Lautstaerke wieder her, damit der naechste Start
/// nicht stumm ist. Nach Ablauf bleibt der Zustand "abgelaufen" stehen
/// (Endzeit in der Vergangenheit), bis der Nutzer neu waehlt oder abbricht.
///
/// "Ende des Songs": [tracks] meldet Titelwechsel. Wechselt der Titel, ist der
/// Song zu Ende (auch wenn `ends_at` etwas abwich), und es wird gestoppt;
/// bleibt es derselbe Song mit neuem `ends_at`, wird die Endzeit korrigiert.
class DefaultSleepTimerService implements SleepTimerService {
  DefaultSleepTimerService({
    required this._clock,
    required this._playback,
    Stream<Track?>? tracks,
    this._tick = const Duration(seconds: 1),
  }) {
    _trackSub = tracks?.listen(_onTrack);
  }

  final Clock _clock;
  final PlaybackService _playback;
  final Duration _tick;
  final StreamController<SleepTimerState> _controller =
      StreamController<SleepTimerState>.broadcast();
  StreamSubscription<Track?>? _trackSub;

  SleepTimerState _state = SleepTimerLogic.off;
  Timer? _timer;
  Track? _startTrack;

  /// Lautstaerke vor dem Ausblenden; `null`, solange nicht ausgeblendet wird.
  double? _baseVolume;
  bool _disposed = false;

  @override
  SleepTimerState get state => _state;

  @override
  Stream<SleepTimerState> get states => _controller.stream;

  @override
  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {
    await _restoreVolume();
    final now = _clock.now();
    if (mode is SleepTimerEndOfSong &&
        !sleepTimerEndOfSongAvailable(currentTrack, now)) {
      // Live-Sendung oder Songende unbekannt: nicht moeglich, kein Timer.
      _stopTicking();
      _startTrack = null;
      _emit(SleepTimerLogic.off);
      return;
    }
    _startTrack = mode is SleepTimerEndOfSong ? currentTrack : null;
    final next = SleepTimerLogic.start(mode, now, currentTrack: currentTrack);
    _emit(next);
    if (next.isActive) {
      _startTicking();
    } else {
      _stopTicking();
    }
  }

  @override
  Future<void> cancel() async {
    _stopTicking();
    _startTrack = null;
    await _restoreVolume();
    _emit(SleepTimerLogic.cancel());
  }

  /// Ein Zeitschritt: Ablauf pruefen, sonst ausblenden. Oeffentlich, damit
  /// Tests ohne echte Uhr einzelne Schritte ausloesen koennen.
  Future<void> tick() async {
    if (_disposed || !_state.isActive) return;
    final now = _clock.now();
    if (_state.endsAt == null) return;
    if (SleepTimerLogic.isExpired(_state, now)) {
      await _expire();
      return;
    }
    final factor = SleepTimerLogic.fadeFactor(_state, now);
    if (factor < 1) {
      final base = _baseVolume ??= _playback.state.volume;
      await _playback.setVolume(base * factor);
    }
  }

  Future<void> _expire() async {
    _stopTicking();
    _startTrack = null;
    final status = _playback.state.status;
    if (status != PlayerStatus.idle) {
      await _playback.stopPlayback();
    }
    await _restoreVolume();
    // Zustand bleibt "abgelaufen" (Endzeit erreicht), die UI zeigt das an.
    _emit(_state);
  }

  void _onTrack(Track? track) {
    // Nur bei laufendem Timer: nach Ablauf oder Abbruch ist der Titelwechsel
    // ohne Bedeutung (sonst stoppt ein spaeterer Start faelschlich erneut).
    if (_disposed || _timer == null || _state.mode is! SleepTimerEndOfSong) {
      return;
    }
    final started = _startTrack;
    if (started == null || track == null) return;
    final sameSong =
        track.artist == started.artist && track.title == started.title;
    if (!sameSong) {
      // Titelwechsel: der Song ist zu Ende.
      _state = _state.copyWith(endsAt: _clock.now());
      unawaited(tick());
      return;
    }
    final end = track.endsAt;
    if (end != null && end != _state.endsAt && end.isAfter(_clock.now())) {
      _emit(_state.copyWith(endsAt: end));
    }
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => unawaited(tick()));
  }

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _restoreVolume() async {
    final base = _baseVolume;
    if (base == null) return;
    _baseVolume = null;
    await _playback.setVolume(base);
  }

  void _emit(SleepTimerState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopTicking();
    await _trackSub?.cancel();
    await _controller.close();
  }
}
