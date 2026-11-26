part of 'audio_handler.dart';

/// Connect, retry and state publishing of the playback pipeline.
extension _AudioHandlerPlayback on LinefmAudioHandler {
  Future<void> _connect(Station station, int gen) async {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(connectTimeout, () {
      if (gen == _generation) _onFailure('timeout');
    });
    try {
      final url = await streamUrlResolver(station);
      if (gen != _generation) return;
      await _player.load(url);
      // A newer switch (or stop) happened while this stream was
      // loading. Starting it now would play the old station under the UI of
      // the new one.
      if (gen != _generation) return;
      await _player.play();
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
      LinefmAudioHandler.playbackStateFor(
        _state.status,
        errorMessage: LinefmAudioHandler.userErrorMessage(),
      ),
    );
  }
}
