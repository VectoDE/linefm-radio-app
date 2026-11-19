import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:smtc_windows/smtc_windows.dart';

/// Windows/Linux: just_audio ueber media_kit (libmpv). Muss vor dem ersten
/// AudioPlayer laufen. Android/iOS/macOS bleiben auf den nativen Backends.
void initNativeAudioBackend() {
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(windows: true, linux: true);
    JustAudioMediaKit.title = 'LINEFM Radio';
  }
}

/// Windows: System Media Transport Controls (Medienflyout, Medientasten,
/// Sperrbildschirm). audio_service hat unter Windows kein Backend.
/// Linux braucht nichts: audio_service_mpris registriert sich selbst.
Future<Object?> attachDesktopMediaControls(AudioHandler handler) async {
  if (!Platform.isWindows) return null;
  try {
    await SMTCWindows.initialize();
    final bridge = WindowsSmtcBridge(handler);
    await bridge.start();
    return bridge;
  } on Object catch (e) {
    // Fehlt die native Bibliothek (Build ohne Rust), laeuft die App ohne
    // Medienflyout weiter.
    debugPrint('SMTC nicht verfuegbar: $e');
    return null;
  }
}

/// Spiegelt den audio_service-Zustand in die Windows-SMTC und leitet
/// Tastendruecke an den Handler weiter.
class WindowsSmtcBridge {
  WindowsSmtcBridge(this._handler);

  final AudioHandler _handler;
  late final SMTCWindows _smtc;
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];

  Future<void> start() async {
    _smtc = SMTCWindows(
      config: const SMTCConfig(
        playEnabled: true,
        pauseEnabled: true,
        stopEnabled: true,
        nextEnabled: true,
        prevEnabled: true,
        fastForwardEnabled: false,
        rewindEnabled: false,
      ),
      status: PlaybackStatus.stopped,
    );
    _subs
      ..add(_smtc.buttonPressStream.listen(_onButton))
      ..add(_handler.playbackState.listen(_onState))
      ..add(_handler.mediaItem.listen(_onItem));
  }

  void _onButton(PressedButton button) {
    switch (button) {
      case PressedButton.play:
        unawaited(_handler.play());
      case PressedButton.pause:
      case PressedButton.stop:
        unawaited(_handler.stop());
      case PressedButton.next:
      case PressedButton.channelUp:
        unawaited(_handler.skipToNext());
      case PressedButton.previous:
      case PressedButton.channelDown:
        unawaited(_handler.skipToPrevious());
      case PressedButton.fastForward:
      case PressedButton.rewind:
      case PressedButton.record:
        break;
    }
  }

  void _onState(PlaybackState state) {
    final status = switch (state.processingState) {
      AudioProcessingState.loading ||
      AudioProcessingState.buffering => PlaybackStatus.changing,
      AudioProcessingState.ready =>
        state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      AudioProcessingState.idle ||
      AudioProcessingState.completed ||
      AudioProcessingState.error => PlaybackStatus.stopped,
    };
    unawaited(_safe(() => _smtc.setPlaybackStatus(status)));
  }

  void _onItem(MediaItem? item) {
    if (item == null) return;
    final art = item.artUri;
    unawaited(
      _safe(
        () => _smtc.updateMetadata(
          MusicMetadata(
            title: item.title,
            artist: item.artist ?? item.album,
            album: item.album,
            albumArtist: item.album,
            thumbnail: art != null && art.scheme.startsWith('http')
                ? art.toString()
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      debugPrint('SMTC-Aktualisierung fehlgeschlagen: $e');
    }
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _smtc.dispose();
  }
}
