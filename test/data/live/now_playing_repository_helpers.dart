import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/api/song_change_socket.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/domain/schedule_slot.dart';
import 'package:linefm_radio/domain/track.dart';

import '../../support/test_doubles.dart';

final t0 = DateTime.utc(2026, 11, 18, 20);

Track song(String title, {int startMin = 0, int? lengthSec = 180}) {
  final start = t0.add(Duration(minutes: startMin));
  return Track(
    artist: 'Artist',
    title: title,
    startedAt: start,
    endsAt: lengthSec == null ? null : start.add(Duration(seconds: lengthSec)),
  );
}

class FakeApi implements LautApi {
  final Map<String, Track?> current = <String, Track?>{};
  final Map<String, List<Track>> last = <String, List<Track>>{};
  final Map<String, int> listenerCount = <String, int>{};
  final List<String> calls = <String>[];
  bool offline = false;

  Future<T> _call<T>(String name, T value) async {
    calls.add(name);
    if (offline) throw http.ClientException('offline');
    return value;
  }

  @override
  Future<Track?> currentSong(String slug) =>
      _call('current:$slug', current[slug]);

  @override
  Future<List<Track>> lastSongs(String slug) =>
      _call('last:$slug', last[slug] ?? const <Track>[]);

  @override
  Future<int?> listeners(String slug) =>
      _call('listeners:$slug', listenerCount[slug]);

  @override
  Future<List<ScheduleSlot>> schedule(String slug) async =>
      const <ScheduleSlot>[];

  @override
  Future<String?> streamUrl(String slug) async => null;
}

class FakeSocket implements SongChangeSocket {
  final StreamController<SongChange> controller =
      StreamController<SongChange>.broadcast(sync: true);
  int connects = 0;
  int closes = 0;

  @override
  Stream<SongChange> get changes => controller.stream;

  @override
  Future<void> connect() async => connects++;

  @override
  Future<void> close() async => closes++;
}

class FakeArtwork implements ArtworkService {
  final List<String> lookups = <String>[];

  /// Titles without an iTunes hit.
  final Set<String> misses = <String>{};

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) async {
    lookups.add('${track.title}:$priority');
    if (misses.contains(track.title)) return null;
    return ArtworkResult(artworkUrl: 'https://cover/${track.title}.jpg');
  }
}

class FakeTimer implements Timer {
  FakeTimer(this.due, this.callback, {this.period});

  DateTime due;
  final void Function(Timer) callback;
  final Duration? period;
  bool active = true;
  int ticks = 0;

  @override
  void cancel() => active = false;

  @override
  bool get isActive => active;

  @override
  int get tick => ticks;
}

/// Manuelle Zeitsteuerung: Timer laufen nur bei [advance].
class Scheduler {
  Scheduler(this.clock);

  final FakeClock clock;
  final List<FakeTimer> timers = <FakeTimer>[];

  Timer one(Duration d, void Function() cb) {
    final t = FakeTimer(clock.now().add(d), (_) => cb());
    timers.add(t);
    return t;
  }

  Timer periodic(Duration d, void Function(Timer) cb) {
    final t = FakeTimer(clock.now().add(d), cb, period: d);
    timers.add(t);
    return t;
  }

  int get active => timers.where((t) => t.active).length;

  Future<void> advance(Duration d) async {
    final target = clock.now().add(d);
    while (true) {
      final due = timers.where((t) => t.active && !t.due.isAfter(target));
      if (due.isEmpty) break;
      final next = due.reduce((a, b) => a.due.isBefore(b.due) ? a : b);
      clock.setTo(next.due);
      next.ticks++;
      if (next.period == null) {
        next.active = false;
      } else {
        next.due = next.due.add(next.period!);
      }
      next.callback(next);
      await settle();
    }
    clock.setTo(target);
    await settle();
  }
}

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// API, deren Antworten der Test einzeln freigibt (verspaetete Antworten).
class GatedApi implements LautApi {
  final Map<String, Track?> current = <String, Track?>{};
  final Map<String, Completer<Object?>> pending =
      <String, Completer<Object?>>{};
  bool gated = false;

  Future<T> _call<T>(String key, T value) async {
    if (!gated) return value;
    final c = pending.putIfAbsent(key, Completer<Object?>.new);
    final result = await c.future;
    return result is T ? result : value;
  }

  void release(String key, Object? value) =>
      pending.remove(key)!.complete(value);

  @override
  Future<Track?> currentSong(String slug) =>
      _call('current:$slug', current[slug]);

  @override
  Future<List<Track>> lastSongs(String slug) =>
      _call('last:$slug', const <Track>[]);

  @override
  Future<int?> listeners(String slug) => _call('listeners:$slug', null);

  @override
  Future<List<ScheduleSlot>> schedule(String slug) async =>
      const <ScheduleSlot>[];

  @override
  Future<String?> streamUrl(String slug) async => null;
}
