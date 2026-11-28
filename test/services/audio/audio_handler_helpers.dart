import 'dart:async';

import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/radio_player.dart';
import 'package:linefm_radio/services/audio/reconnect_policy.dart';

class FakeRadioPlayer implements RadioPlayer {
  final StreamController<RadioSignal> _signals =
      StreamController<RadioSignal>.broadcast(sync: true);
  final List<Uri> opened = <Uri>[];
  int stops = 0;
  double? volume;
  bool failOpen = false;

  /// Meldet nach play() automatisch "playing".
  bool autoPlay = true;

  /// Streams that actually started (what the user hears).
  final List<Uri> played = <Uri>[];
  Uri? _loaded;

  /// When set, load() waits for this completer (slow network).
  final Map<Uri, Completer<void>> loadGates = <Uri, Completer<void>>{};

  @override
  Stream<RadioSignal> get signals => _signals.stream;

  void emit(RadioSignal s) => _signals.add(s);

  @override
  Future<void> load(Uri url) async {
    opened.add(url);
    _loaded = url;
    final gate = loadGates[url];
    if (gate != null) await gate.future;
    if (failOpen) throw Exception('open failed');
  }

  @override
  Future<void> play() async {
    played.add(_loaded!);
    if (autoPlay) {
      emit(RadioSignal.buffering);
      emit(RadioSignal.playing);
    }
  }

  @override
  Future<void> stop() async {
    stops++;
    _loaded = null;
    emit(RadioSignal.idle);
  }

  @override
  Future<void> setVolume(double v) async => volume = v;

  @override
  Future<void> dispose() => _signals.close();
}

const ms = Duration(milliseconds: 1);

LinefmAudioHandler handler(
  FakeRadioPlayer player, {
  Duration minConnect = Duration.zero,
}) => LinefmAudioHandler(
  player: player,
  minConnectDuration: minConnect,
  connectTimeout: const Duration(milliseconds: 200),
  reconnectPolicy: const ReconnectPolicy(
    delays: <Duration>[ms, ms, ms, ms, ms],
  ),
);

Future<void> settle([int ms = 20]) =>
    Future<void>.delayed(Duration(milliseconds: ms));
