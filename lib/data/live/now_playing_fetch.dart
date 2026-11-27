part of 'now_playing_repository.dart';

extension _NowPlayingFetch on LiveNowPlayingRepository {
  Future<void> _pollOnce({bool force = false, bool bypassGap = false}) async {
    if (_disposed) return;
    if (!_awake && !force) return;
    final jobs = <Future<void>>[
      _fetchActive(includeHistory: _foreground, bypassGap: bypassGap),
    ];
    // Auch bei verbundenem WebSocket: verpasste Nachrichten (z. B. vor dem
    // Verbinden) werden so spaetestens nach einem Intervall korrigiert.
    if (_foreground) {
      for (final s in _stations) {
        if (s != _active) {
          jobs.add(_fetchCurrent(s.slug, bypassGap: bypassGap));
        }
      }
    }
    await Future.wait(jobs);
  }

  Future<void> _fetchActive({
    required bool includeHistory,
    bool bypassGap = false,
  }) async {
    final slug = _active.slug;
    final generation = _activeGeneration;
    await Future.wait(<Future<void>>[
      _fetchCurrent(slug, bypassGap: bypassGap),
      if (includeHistory) _fetchHistory(slug, bypassGap: bypassGap),
      if (includeHistory) _fetchListeners(slug, bypassGap: bypassGap),
    ]);
    // Verspaetete Antwort fuer eine inzwischen abgewaehlte Station: Die
    // Daten bleiben beim eigenen Sender (Slug), den ends_at-Timer plant der
    // Abruf der neuen Station.
    if (generation != _activeGeneration) return;
    _scheduleEndsAt();
  }

  Future<void> _fetchCurrent(String slug, {bool bypassGap = false}) async {
    final track = await _guard(
      'current:$slug',
      () => _api.currentSong(slug),
      bypassGap: bypassGap,
    );
    if (track == null || _disposed) return;
    _applyTrack(slug, track.value);
  }

  Future<void> _fetchHistory(String slug, {bool bypassGap = false}) async {
    final list = await _guard(
      'last:$slug',
      () => _api.lastSongs(slug),
      bypassGap: bypassGap,
    );
    if (list == null || _disposed) return;
    // Keep covers already resolved for the same song; the API
    // list usually carries none.
    final previous = _last[slug] ?? const <Track>[];
    _last[slug] = <Track>[
      for (final t in list.value) _withKnownCover(t, previous),
    ];
    _emit();
    if (slug == _active.slug) _lookupHistoryCovers(slug);
  }

  /// Every history entry gets its own cover, looked up by its own
  /// artist and title (cached by the artwork service). Entries without a
  /// hit keep `artworkUrl == null`, so the UI falls back to the station logo.
  void _lookupHistoryCovers(String slug) {
    for (final t in _last[slug] ?? const <Track>[]) {
      if (t.artworkUrl == null) unawaited(_lookupEntryCover(slug, t));
    }
  }

  Future<void> _lookupEntryCover(String slug, Track track) async {
    final result = await _artwork.lookup(track);
    final url = result?.artworkUrl;
    if (url == null || _disposed) return;
    if (_patchHistoryCover(slug, track, url)) _emit();
  }

  /// Sets [url] on the history entry of [slug] that is the same song as
  /// [track] (and has no cover yet). Returns whether something changed.
  bool _patchHistoryCover(String slug, Track track, String url) {
    final last = _last[slug];
    if (last == null) return false;
    var changed = false;
    final next = <Track>[];
    for (final t in last) {
      if (t.artworkUrl == null && _sameSong(t, track)) {
        next.add(t.copyWith(artworkUrl: url));
        changed = true;
      } else {
        next.add(t);
      }
    }
    if (changed) _last[slug] = next;
    return changed;
  }

  Future<void> _fetchListeners(String slug, {bool bypassGap = false}) async {
    final n = await _guard(
      'listeners:$slug',
      () => _api.listeners(slug),
      bypassGap: bypassGap,
    );
    if (n == null || _disposed) return;
    if (_listeners[slug] == n.value) return;
    _listeners[slug] = n.value;
    _emit();
  }

  /// `null` bei Fehler oder wenn der Abruf zusammengefasst wurde (gleiche
  /// Adresse zuletzt vor weniger als [minRefetchGap]); sonst das Ergebnis in
  /// einer Huelle (auch fuer `null`-Werte der API). Ein laufender Abruf
  /// derselben Adresse wird mitbenutzt.
  Future<_Box<T>?> _guard<T>(
    String key,
    Future<T> Function() call, {
    bool bypassGap = false,
  }) {
    final running = _inFlight[key];
    if (running != null) return running.then((v) => v as _Box<T>?);
    final last = _fetchedAt[key];
    if (!bypassGap &&
        last != null &&
        _clock.now().difference(last) < minRefetchGap) {
      return Future<_Box<T>?>.value();
    }
    final future = _request(call).whenComplete(() {
      _inFlight.remove(key);
      _fetchedAt[key] = _clock.now();
    });
    _inFlight[key] = future;
    return future;
  }

  Future<_Box<T>?> _request<T>(Future<T> Function() call) async {
    try {
      final value = await call();
      _setOnline(true);
      return _Box<T>(value);
    } on LautApiException catch (e) {
      logError('laut.fm', e);
      _setOnline(true);
      return null;
    } on Object catch (e) {
      logError('laut.fm nicht erreichbar', e);
      _setOnline(false);
      return null;
    }
  }

  void _setOnline(bool value) {
    if (_online == value || _disposed) return;
    _online = value;
    _emit();
  }
}

extension _NowPlayingTrackUpdates on LiveNowPlayingRepository {
  void _onSongChange(SongChange change) {
    if (_disposed) return;
    final startedAt = change.track.startedAt;
    final now = _clock.now();
    if (startedAt != null && startedAt.isAfter(now)) {
      final wait = startedAt.difference(now);
      if (wait <= maxAnnounceDelay) {
        _announced.remove(change.stationSlug)?.cancel();
        _announced[change.stationSlug] = timer(wait, () {
          _announced.remove(change.stationSlug);
          _applyTrack(change.stationSlug, change.track);
          if (change.stationSlug == _active.slug) _scheduleEndsAt();
        });
        return;
      }
    }
    _applyTrack(change.stationSlug, change.track);
    if (change.stationSlug == _active.slug) _scheduleEndsAt();
  }

  void _applyTrack(String slug, Track? track) {
    if (_disposed) return;
    final old = _current[slug];
    if (track == null) {
      if (old == null && _current.containsKey(slug)) return;
      _current[slug] = null;
      _emit();
      return;
    }
    if (old != null && old.lastSeen) {
      // Restored track: live data replaces it. Same song keeps its cover.
      _current[slug] = _sameSong(old, track) && track.artworkUrl == null
          ? track.copyWith(artworkUrl: old.artworkUrl)
          : track;
      if (!_sameSong(old, track)) {
        final last = _last[slug] ?? const <Track>[];
        if (last.isEmpty || !_sameSong(last.first, old)) {
          _last[slug] = <Track>[
            old.copyWith(lastSeen: false),
            ...last,
          ].take(10).toList();
        }
      }
      _emit();
      final now = _current[slug]!;
      if (slug == _active.slug) unawaited(_lookupCover(slug, now));
      return;
    }
    if (old != null && _sameSong(old, track)) {
      // Gleicher Song: nur fehlende Details nachtragen (z. B. korrigiertes
      // Ende), Cover behalten.
      if (old.endsAt != track.endsAt && track.endsAt != null) {
        _current[slug] = old.copyWith(endsAt: track.endsAt);
        _emit();
      }
      return;
    }
    // Startet der "neue" Titel vor dem bekannten, ist es eine veraltete
    // Antwort (Cache); ignorieren.
    final oldStart = old?.startedAt;
    final newStart = track.startedAt;
    if (oldStart != null && newStart != null && newStart.isBefore(oldStart)) {
      return;
    }
    _current[slug] = track;
    if (old != null) {
      final last = _last[slug] ?? const <Track>[];
      if (last.isEmpty || !_sameSong(last.first, old)) {
        _last[slug] = <Track>[old, ...last].take(10).toList();
      }
    }
    _emit();
    if (slug == _active.slug) unawaited(_lookupCover(slug, track));
  }

  Future<void> _lookupCover(String slug, Track track) async {
    if (track.artworkUrl != null) return;
    final result = await _artwork.lookup(track, priority: true);
    final url = result?.artworkUrl;
    if (url == null || _disposed) return;
    final current = _current[slug];
    if (current == null || !_sameSong(current, track)) {
      // The song ended before its cover arrived: it is in the history now
      // and keeps its own cover there.
      if (_patchHistoryCover(slug, track, url)) _emit();
      return;
    }
    _current[slug] = current.copyWith(artworkUrl: url);
    _emit();
  }

  void _scheduleEndsAt() {
    _endsAtTimer?.cancel();
    _endsAtTimer = null;
    if (_disposed || !_awake) return;
    final endsAt = _current[_active.slug]?.endsAt;
    Duration delay;
    if (endsAt == null) {
      delay = unknownEndDelay;
    } else {
      delay = endsAt.add(endsAtLead).difference(_clock.now());
      if (delay < minEndsAtDelay) delay = minEndsAtDelay;
      if (delay > maxEndsAtDelay) delay = maxEndsAtDelay;
    }
    lastEndsAtDelay = delay;
    _endsAtTimer = timer(delay, () {
      _endsAtTimer = null;
      unawaited(_fetchActive(includeHistory: _foreground));
    });
  }
}
