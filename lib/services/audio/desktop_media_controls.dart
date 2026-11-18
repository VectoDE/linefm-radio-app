import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// SMTC (Windows) und MPRIS (Linux). Besitzer: P18.
abstract interface class DesktopMediaControls {
  Future<void> init();

  Future<void> update({
    required Station station,
    Track? track,
    required bool playing,
  });

  Future<void> dispose();
}

class NoopDesktopMediaControls implements DesktopMediaControls {
  const NoopDesktopMediaControls();

  @override
  Future<void> init() async {}

  @override
  Future<void> update({
    required Station station,
    Track? track,
    required bool playing,
  }) async {}

  @override
  Future<void> dispose() async {}
}
