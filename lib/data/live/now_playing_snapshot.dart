part of 'now_playing_repository.dart';

extension _NowPlayingSnapshot on LiveNowPlayingRepository {
  /// Restores the last track and history per station. Everything restored
  /// is marked [Track.lastSeen] until live data replaces it.
  void _restore(String? json) {
    if (json == null || json.isEmpty) return;
    try {
      final data = jsonDecode(json);
      if (data is! Map || data['stations'] is! Map) return;
      for (final MapEntry(:key, :value) in (data['stations'] as Map).entries) {
        if (key is! String || value is! Map) continue;
        final current = Track.tryFromJson(value['current']);
        if (current != null) _current[key] = current.copyWith(lastSeen: true);
        final last = value['last'];
        if (last is List) {
          _last[key] = <Track>[
            for (final item in last.take(10))
              if (Track.tryFromJson(item) case final Track t)
                t.copyWith(lastSeen: true),
          ];
        }
      }
      _lastSnapshot = json;
    } on FormatException {
      return;
    }
  }

  /// JSON of the current state: active station first, at most
  /// [maxStoredHistory] history entries in total.
  String _snapshot() {
    final slugs = <String>{_active.slug, ..._current.keys, ..._last.keys};
    var budget = LiveNowPlayingRepository.maxStoredHistory;
    final stations = <String, Object?>{};
    for (final slug in slugs) {
      final current = _current[slug];
      final last = (_last[slug] ?? const <Track>[]).take(budget).toList();
      budget -= last.length;
      if (current == null && last.isEmpty) continue;
      stations[slug] = <String, Object?>{
        'current': current?.toJson(),
        'last': <Object?>[for (final t in last) t.toJson()],
      };
    }
    return jsonEncode(<String, Object?>{'v': 1, 'stations': stations});
  }

  void _persist() {
    final write = _writeSnapshot;
    if (write == null || _disposed) return;
    final json = _snapshot();
    if (json == _lastSnapshot) return;
    _lastSnapshot = json;
    unawaited(
      write(json).catchError((Object e, StackTrace s) {
        logError('Speichern fehlgeschlagen', e, s);
      }),
    );
  }
}
