import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Vereinfachte Sicht auf den Player-Zustand fuer Live-Radio.
enum RadioSignal {
  /// Kein Stream geladen (nach Stop).
  idle,

  /// Verbindet oder puffert.
  buffering,

  /// Ton laeuft.
  playing,

  /// Stream wurde vom Server beendet (bei Live-Radio = Verbindung weg).
  ended,

  /// Fehler beim Laden oder waehrend der Wiedergabe.
  error,
}

/// Schmale Huelle um den eigentlichen Player, damit der Audio-Handler
/// ohne Plattformkanaele testbar bleibt.
abstract interface class RadioPlayer {
  Stream<RadioSignal> get signals;

  /// Loads [url] without starting playback. Throws on load errors.
  ///
  /// Loading and starting are separate so the handler can check,
  /// after the (possibly slow) load, that this station is still the one the
  /// user wants before any sound starts.
  Future<void> load(Uri url);

  /// Starts playback of the loaded stream. Returns without waiting for the
  /// end of playback.
  Future<void> play();

  /// Gibt den Stream frei (Live-Radio: Stop statt Pause).
  Future<void> stop();

  /// 0.0 bis 1.0 auf Player-Ebene.
  Future<void> setVolume(double volume);

  Future<void> dispose();
}

/// [RadioPlayer] auf Basis von just_audio. Unter Windows/Linux greift
/// automatisch just_audio_media_kit (siehe audio_backend.dart).
class JustAudioRadioPlayer implements RadioPlayer {
  JustAudioRadioPlayer({AudioPlayer? player})
    : _player =
          player ??
          AudioPlayer(
            // Unterbrechungen (Anrufe, Ansagen) behandelt der Handler selbst,
            // weil Live-Radio nach einer Pause neu verbinden muss.
            handleInterruptions: false,
          ) {
    _stateSub = _player.playerStateStream.listen(
      _onState,
      onError: (Object _) => _emit(RadioSignal.error),
    );
    _eventSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object _) => _emit(RadioSignal.error),
    );
  }

  final AudioPlayer _player;
  final StreamController<RadioSignal> _signals =
      StreamController<RadioSignal>.broadcast();
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<PlaybackEvent> _eventSub;
  RadioSignal? _last;

  @override
  Stream<RadioSignal> get signals => _signals.stream;

  void _emit(RadioSignal signal) {
    // Fehler immer melden, sonst nur Wechsel.
    if (signal == _last && signal != RadioSignal.error) return;
    _last = signal;
    if (!_signals.isClosed) _signals.add(signal);
  }

  void _onState(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        _emit(RadioSignal.idle);
      case ProcessingState.loading:
      case ProcessingState.buffering:
        if (state.playing) _emit(RadioSignal.buffering);
      case ProcessingState.ready:
        _emit(state.playing ? RadioSignal.playing : RadioSignal.idle);
      case ProcessingState.completed:
        _emit(RadioSignal.ended);
    }
  }

  @override
  Future<void> load(Uri url) async {
    _last = null;
    await _player.setAudioSource(AudioSource.uri(url));
  }

  @override
  Future<void> play() async {
    // play() completes only on the next stop/pause, so do not await it.
    unawaited(
      _player.play().catchError((Object _) => _emit(RadioSignal.error)),
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0));

  @override
  Future<void> dispose() async {
    await _stateSub.cancel();
    await _eventSub.cancel();
    await _signals.close();
    await _player.dispose();
  }
}
