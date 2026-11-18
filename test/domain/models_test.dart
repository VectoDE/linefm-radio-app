import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';

void main() {
  final start = DateTime.utc(2026, 11, 18, 18);
  final track = Track(
    artist: 'Daft Punk',
    title: 'One More Time',
    album: 'Discovery',
    artworkUrl: 'https://x/c.jpg',
    startedAt: start,
    endsAt: start.add(const Duration(minutes: 5)),
  );

  group('Track', () {
    test('JSON-Rundlauf und Gleichheit', () {
      final back = Track.tryFromJson(track.toJson())!;
      expect(back, track);
      expect(back.hashCode, track.hashCode);
      expect(back.toString(), 'Track(Daft Punk - One More Time)');
    });

    test('copyWith aendert nur das Genannte', () {
      final t = track.copyWith(title: 'Anders');
      expect(t.title, 'Anders');
      expect(t.artist, track.artist);
      expect(t.endsAt, track.endsAt);
      expect(t, isNot(track));
    });

    test('tolerantes Lesen', () {
      expect(Track.tryFromJson(null), isNull);
      expect(Track.tryFromJson(<String, Object?>{'artist': 'A'}), isNull);
      expect(
        Track.tryFromJson(<String, Object?>{'artist': ' ', 'title': 'T'}),
        isNull,
      );
      final t = Track.tryFromJson(<String, Object?>{
        'artist': 'A',
        'title': 'T',
        'album': 5,
        'startedAt': 'kein Datum',
        'endsAt': 3,
      })!;
      expect(t.album, isNull);
      expect(t.startedAt, isNull);
      expect(t.endsAt, isNull);
    });
  });

  group('Wertobjekte', () {
    test('HistoryEntry', () {
      final a = HistoryEntry(track: track, isLive: true);
      expect(a, HistoryEntry(track: track, isLive: true));
      expect(a.hashCode, HistoryEntry(track: track, isLive: true).hashCode);
      expect(a.copyWith(isLive: false), isNot(a));
      expect(a.copyWith(track: track.copyWith(title: 'X')).track.title, 'X');
    });

    test('NowPlaying und StationLive', () {
      final s = stationsCatalog.first;
      final np = NowPlaying(station: s, track: track, listeners: 7);
      expect(np, NowPlaying(station: s, track: track, listeners: 7));
      expect(
        np.hashCode,
        NowPlaying(station: s, track: track, listeners: 7).hashCode,
      );
      expect(np.copyWith(listeners: 8).listeners, 8);
      expect(
        np.copyWith(station: stationsCatalog[1]).station,
        stationsCatalog[1],
      );
      expect(np.copyWith(track: track.copyWith(title: 'Y')).track?.title, 'Y');
      final live = StationLive(station: s, track: track);
      expect(live, StationLive(station: s, track: track));
      expect(live.hashCode, StationLive(station: s, track: track).hashCode);
      expect(live.copyWith(station: stationsCatalog[2]), isNot(live));
      expect(live.copyWith(track: track.copyWith(title: 'Z')), isNot(live));
    });

    test('PlayerUiState', () {
      const idle = PlayerUiState();
      expect(idle.isPlaying, isFalse);
      expect(idle.isBusy, isFalse);
      final playing = idle.copyWith(
        status: PlayerStatus.playing,
        station: stationsCatalog.first,
        volume: 0.5,
      );
      expect(playing.isPlaying, isTrue);
      expect(
        playing,
        const PlayerUiState().copyWith(
          status: PlayerStatus.playing,
          station: stationsCatalog.first,
          volume: 0.5,
        ),
      );
      expect(playing.hashCode, isNot(idle.hashCode));
      expect(idle.copyWith(status: PlayerStatus.connecting).isBusy, isTrue);
      expect(idle.copyWith(status: PlayerStatus.reconnecting).isBusy, isTrue);
      expect(idle.copyWith(status: PlayerStatus.error).isBusy, isFalse);
    });

    test('Favorite copyWith und Gleichheit', () {
      final f = Favorite(
        key: 'k',
        stationSlug: 'linefm',
        title: 'T',
        artist: 'A',
        savedAt: start,
      );
      expect(f.copyWith(title: 'U').title, 'U');
      expect(f.copyWith(artworkUrl: 'a').artworkUrl, 'a');
      expect(f.copyWith(stationLogoUrl: 'l').stationLogoUrl, 'l');
      expect(f.copyWith(key: 'k2').key, 'k2');
      expect(f.copyWith(stationSlug: 's').stationSlug, 's');
      expect(f.copyWith(artist: 'B').artist, 'B');
      expect(f.copyWith(savedAt: start).savedAt, start);
      expect(f, f.copyWith());
      expect(f.hashCode, f.copyWith().hashCode);
      expect(f.toString(), 'Favorite(k)');
    });
  });

  group('AppSettings', () {
    test('Standardwerte', () {
      const s = AppSettings();
      expect(s.marquee, isTrue);
      expect(s.rememberVolume, isTrue);
      expect(s.autoplay, isTrue);
      expect(s.closeToTray, isTrue);
      expect(s.themeMode, AppThemeMode.system);
    });

    test('JSON-Rundlauf', () {
      const s = AppSettings(
        marquee: false,
        rememberVolume: false,
        autoplay: false,
        closeToTray: false,
        themeMode: AppThemeMode.light,
      );
      expect(AppSettings.fromJson(s.toJson()), s);
      expect(AppSettings.fromJson(s.toJson()).hashCode, s.hashCode);
    });

    test('tolerantes Lesen: Muell ergibt Standardwerte', () {
      expect(AppSettings.fromJson(null), const AppSettings());
      expect(AppSettings.fromJson('x'), const AppSettings());
      expect(
        AppSettings.fromJson(<String, Object?>{
          'marquee': 'ja',
          'themeMode': 'neon',
          'autoplay': false,
        }),
        const AppSettings(autoplay: false),
      );
    });

    test('copyWith', () {
      const s = AppSettings();
      expect(s.copyWith(marquee: false).marquee, isFalse);
      expect(s.copyWith(rememberVolume: false).rememberVolume, isFalse);
      expect(s.copyWith(autoplay: false).autoplay, isFalse);
      expect(s.copyWith(closeToTray: false).closeToTray, isFalse);
      expect(
        s.copyWith(themeMode: AppThemeMode.dark).themeMode,
        AppThemeMode.dark,
      );
      expect(s.copyWith(), s);
    });
  });

  group('Senderkatalog', () {
    test('6 Sender mit eindeutigen Slugs und IDs', () {
      expect(stationsCatalog, hasLength(6));
      expect(stationsCatalog.map((s) => s.slug).toSet(), hasLength(6));
      expect(stationsCatalog.map((s) => s.id).toSet(), hasLength(6));
    });

    test('stationBySlug', () {
      expect(stationBySlug('linefmrap')?.displayName, 'LineFM +RAP');
      expect(stationBySlug('gibtsnicht'), isNull);
    });

    test('Station: Gleichheit ueber id und slug', () {
      final s = stationsCatalog.first;
      expect(s, stationBySlug(s.slug));
      expect(s.hashCode, stationBySlug(s.slug).hashCode);
      expect(s, isNot(stationsCatalog[1]));
    });
  });
}
