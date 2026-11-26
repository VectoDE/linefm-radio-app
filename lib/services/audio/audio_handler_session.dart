part of 'audio_handler.dart';

/// Interruption handling of the audio session.
extension _AudioHandlerSession on LinefmAudioHandler {
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
}
