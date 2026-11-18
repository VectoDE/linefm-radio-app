import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';

/// Wiedergabe-Logik (togglePlayback, selectStation, startStation,
/// shuffleStation der Web-App). Stub, ausgebaut in P11.
class PlayerController {
  PlayerController(this._ref);

  final Ref _ref;

  Future<void> selectStation(Station station) async {
    _ref.read(activeStationProvider.notifier).select(station);
  }

  Future<void> startStation(Station station) async {
    await selectStation(station);
    await _ref.read(playbackServiceProvider).playStation(station);
  }

  Future<void> togglePlayback() async {
    final service = _ref.read(playbackServiceProvider);
    if (service.state.isPlaying || service.state.isBusy) {
      await service.stopPlayback();
    } else {
      await startStation(_ref.read(activeStationProvider));
    }
  }

  Future<void> shuffleStation([Random? random]) async {
    final current = _ref.read(activeStationProvider);
    final others = stationsCatalog.where((s) => s != current).toList();
    final next = others[(random ?? Random()).nextInt(others.length)];
    await startStation(next);
  }

  Future<void> setVolume(double volume) =>
      _ref.read(playbackServiceProvider).setVolume(volume);
}
