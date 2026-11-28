part of 'audio_handler.dart';

/// Browse tree notifications and recent-station bookkeeping.
extension _AudioHandlerBrowse on LinefmAudioHandler {
  /// Gemerkter Titel der Station, aber nur, solange er laut `endsAt` noch
  /// laeuft. Ein abgelaufener Titel (z. B. Wechsel per Medientaste auf einen
  /// lange nicht gewaehlten Sender) wird nicht gezeigt; die App meldet den
  /// aktuellen nach.
  Track? _knownTrack(Station station) {
    final track = _tracks[station.slug];
    final endsAt = track?.endsAt;
    if (endsAt != null && endsAt.isBefore(DateTime.now())) return null;
    return track;
  }

  void _setRecent(Station station) {
    if (_recent == station) return;
    _recent = station;
    _notifyBrowseChanged(BrowseTree.recentId);
  }

  /// Meldet Android Auto ueber [subscribeToChildren], dass sich ein Ordner
  /// geaendert hat; audio_service ruft dann `notifyChildrenChanged` auf.
  void _notifyBrowseChanged(String parentMediaId) {
    final subject = _childrenSubjects[parentMediaId];
    if (subject != null && !subject.isClosed) {
      subject.add(const <String, dynamic>{});
    }
  }
}

/// Mapping onto the audio_service state (notification, lock screen,
/// Android Auto, media session, MPRIS).
PlaybackState _playbackStateFor(PlayerStatus status, {String? errorMessage}) {
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
