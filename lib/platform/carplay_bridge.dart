import 'dart:async';

import 'package:audio_service/audio_service.dart' show MediaItem, PlaybackState;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, MissingPluginException, PlatformException;
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/browse_tree.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

/// Bruecke zum nativen CarPlay-Code (iOS, `ios/Runner/CarPlay*.swift`).
/// Besitzer: P17.
///
/// Vertrag des Kanals `de.linefm.app/carplay`:
///
/// Dart -> nativ
/// * `setMenu` mit `{folders: [AutoMenuFolder.toJson(), ...]}`: die drei
///   Ordner des Auto-Menues (Favoriten-Sender, Stationen, Zuletzt gehoert,
///   Entscheidung 49) in fester Reihenfolge. Nativ wird daraus je Ordner ein
///   Tab mit einer Liste.
/// * `nowPlaying` mit `{slug, station, title, artist, playing}`: aktuelle
///   Station und Titel fuer Detailtext und Wiedergabe-Markierung der Liste.
///   `slug` ist `null`, wenn noch keine Station gewaehlt ist.
///
/// nativ -> Dart
/// * `getMenu` -> `{folders: [...]}` (wie `setMenu`; die CarPlay-Szene fragt
///   beim Verbinden, falls Dart schon lief).
/// * `play` mit `{slug}` -> `bool` (true, wenn der Sender bekannt ist und der
///   Start angestossen wurde).
///
/// Die Wiedergabe-Steuerung im CarPlay-Now-Playing-Bildschirm laeuft ueber
/// `MPRemoteCommandCenter`/`MPNowPlayingInfoCenter`, die audio_service
/// bedient; dafuer braucht es keinen eigenen Kanalaufruf.
abstract interface class CarPlayBridge {
  static const String channelName = 'de.linefm.app/carplay';

  Future<void> init();

  Future<void> updateNowPlaying(Station station, Track? track);
}

class NoopCarPlayBridge implements CarPlayBridge {
  const NoopCarPlayBridge();

  @override
  Future<void> init() async {}

  @override
  Future<void> updateNowPlaying(Station station, Track? track) async {}
}

/// Was gerade laeuft, in der Form des Kanals (`nowPlaying`).
class CarPlayNowPlaying {
  const CarPlayNowPlaying({
    this.slug,
    this.station,
    this.title,
    this.artist,
    this.playing = false,
  });

  final String? slug;
  final String? station;
  final String? title;
  final String? artist;
  final bool playing;

  Map<String, Object?> toJson() => <String, Object?>{
    'slug': slug,
    'station': station,
    'title': title,
    'artist': artist,
    'playing': playing,
  };

  @override
  bool operator ==(Object other) =>
      other is CarPlayNowPlaying &&
      other.slug == slug &&
      other.station == station &&
      other.title == title &&
      other.artist == artist &&
      other.playing == playing;

  @override
  int get hashCode => Object.hash(slug, station, title, artist, playing);
}

/// Datenquelle der CarPlay-Bruecke. In der App ist das der Audio-Handler
/// ([AudioHandlerCarPlayHost]), in Tests ein Fake.
abstract interface class CarPlayHost {
  /// Die drei Ordner des Auto-Menues in aktueller Fassung.
  List<AutoMenuFolder> menu();

  /// Meldet, dass sich Favoriten-Sender oder die zuletzt gehoerte Station
  /// geaendert haben.
  Stream<void> get menuChanges;

  /// Laufende Station und Titel.
  Stream<CarPlayNowPlaying> get nowPlaying;

  /// Startet den Sender mit diesem Slug.
  Future<void> play(Station station);
}

/// [CarPlayHost] auf Basis des [LinefmAudioHandler]: dieselben Ordner wie
/// Android Auto (`BrowseTree.menu`), Start ueber `playFromMediaId`.
class AudioHandlerCarPlayHost implements CarPlayHost {
  AudioHandlerCarPlayHost(this._handler);

  final LinefmAudioHandler _handler;

  @override
  List<AutoMenuFolder> menu() => BrowseTree.menu(
    favorites: _handler.favoriteStations,
    recent: _handler.recentStation,
    titles: LinefmAudioHandler.autoMenuTitles(),
  );

  @override
  Stream<void> get menuChanges {
    late final StreamController<void> controller;
    final subs = <StreamSubscription<Object?>>[];
    controller = StreamController<void>.broadcast(
      onListen: () {
        for (final id in <String>[
          BrowseTree.favoriteStationsId,
          BrowseTree.recentId,
        ]) {
          subs.add(
            _handler
                .subscribeToChildren(id)
                .listen((_) => controller.add(null)),
          );
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        subs.clear();
      },
    );
    return controller.stream;
  }

  @override
  Stream<CarPlayNowPlaying> get nowPlaying {
    late final StreamController<CarPlayNowPlaying> controller;
    final subs = <StreamSubscription<Object?>>[];
    MediaItem? item = _handler.mediaItem.valueOrNull;
    var playing = _handler.playbackState.valueOrNull?.playing ?? false;
    void emit() => controller.add(nowPlayingFrom(item, playing: playing));
    controller = StreamController<CarPlayNowPlaying>.broadcast(
      onListen: () {
        subs
          ..add(
            _handler.mediaItem.listen((MediaItem? next) {
              item = next;
              emit();
            }),
          )
          ..add(
            _handler.playbackState.listen((PlaybackState next) {
              playing = next.playing;
              emit();
            }),
          );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        subs.clear();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> play(Station station) => _handler.playStation(station);

  /// Uebersetzt das MediaItem des Handlers (id = Slug) in den Kanal-Wert.
  @visibleForTesting
  static CarPlayNowPlaying nowPlayingFrom(
    MediaItem? item, {
    required bool playing,
  }) {
    final station = item == null ? null : stationBySlug(item.id);
    if (station == null) return CarPlayNowPlaying(playing: playing);
    final hasTrack = item!.title != station.displayName;
    return CarPlayNowPlaying(
      slug: station.slug,
      station: station.displayName,
      title: hasTrack ? item.title : null,
      artist: hasTrack ? item.artist : null,
      playing: playing,
    );
  }
}

/// Umsetzung ueber den MethodChannel [CarPlayBridge.channelName].
///
/// Fehlt die native Seite (andere Plattform, Tests ohne Mock), werden
/// Aufrufe still verworfen: Ohne CarPlay gibt es nichts zu tun.
class MethodChannelCarPlayBridge implements CarPlayBridge {
  MethodChannelCarPlayBridge({
    required this._host,
    this._channel = const MethodChannel(CarPlayBridge.channelName),
  });

  final CarPlayHost _host;
  final MethodChannel _channel;
  final List<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>[];
  CarPlayNowPlaying _lastNowPlaying = const CarPlayNowPlaying();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handle);
    _subs
      ..add(_host.menuChanges.listen((_) => unawaited(pushMenu())))
      ..add(_host.nowPlaying.listen((n) => unawaited(_sendNowPlaying(n))));
    await pushMenu();
  }

  /// Schickt das aktuelle Menue an die native Seite.
  Future<void> pushMenu() => _invoke('setMenu', menuPayload(_host.menu()));

  @override
  Future<void> updateNowPlaying(Station station, Track? track) {
    final hasTrack =
        track != null && (track.title.isNotEmpty || track.artist.isNotEmpty);
    return _sendNowPlaying(
      CarPlayNowPlaying(
        slug: station.slug,
        station: station.displayName,
        title: hasTrack ? track.title : null,
        artist: hasTrack ? track.artist : null,
        playing:
            _lastNowPlaying.slug == station.slug && _lastNowPlaying.playing,
      ),
    );
  }

  Future<void> _sendNowPlaying(CarPlayNowPlaying value) async {
    if (value == _lastNowPlaying) return;
    _lastNowPlaying = value;
    await _invoke('nowPlaying', value.toJson());
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _initialized = false;
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'getMenu':
        return menuPayload(_host.menu());
      case 'play':
        final args = call.arguments;
        final slug = args is Map ? args['slug'] : null;
        final station = slug is String ? stationBySlug(slug) : null;
        if (station == null) return false;
        unawaited(
          _host.play(station).catchError((Object e, StackTrace st) {
            logError('CarPlay: Start fehlgeschlagen', e, st);
          }),
        );
        return true;
      default:
        throw MissingPluginException('CarPlay: unbekannte Methode');
    }
  }

  Future<void> _invoke(String method, Object? arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Keine native Seite (nicht iOS): nichts zu tun.
    } on PlatformException catch (e) {
      logError('CarPlay: $method fehlgeschlagen', e);
    }
  }

  /// Nutzlast fuer `setMenu`/`getMenu`.
  static Map<String, Object> menuPayload(List<AutoMenuFolder> folders) =>
      <String, Object>{
        'folders': <Map<String, Object>>[for (final f in folders) f.toJson()],
      };
}

CarPlayBridge? _active;

/// Startet die CarPlay-Bruecke auf iOS (sonst No-Op). Aufruf in `main()`
/// direkt nach `initAudio()` mit dem gelieferten Dienst, damit ein Start nur
/// ueber CarPlay (App nicht geoeffnet) sofort Menue und Wiedergabe hat.
Future<CarPlayBridge> initCarPlay(PlaybackService playback) async {
  final existing = _active;
  if (existing != null) return existing;
  final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  if (!isIos || playback is! LinefmAudioHandler) {
    return const NoopCarPlayBridge();
  }
  final bridge = MethodChannelCarPlayBridge(
    host: AudioHandlerCarPlayHost(playback),
  );
  try {
    await bridge.init();
  } on Object catch (e, st) {
    logError('CarPlay-Bruecke nicht gestartet', e, st);
  }
  return _active = bridge;
}
