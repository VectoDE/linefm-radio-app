// Windows integration test: restart while offline restores the last track
// and the history with covers from the on-device cover cache.
//
// Phase 1 (online): a local fake laut.fm server on 127.0.0.1 serves the
// recorded JSON fixtures (test/fixtures/laut) plus a real PNG cover. The app
// loads the covers through the disk cache and saves the live snapshot to a
// file.
// Phase 2 (restart, offline): the app is built again from scratch on the same
// folders. The fake server is shut down and every new HTTP connection fails
// with a SocketException (HttpOverrides). The mini player and the history must
// show the restored track with the "last seen" hint, and every cover must come
// from the disk cache, with no network request.
//
// Run: flutter test integration_test/windows_offline_restore_test.dart -d windows
// Images go to --dart-define=ITEST_OUT=<folder>.
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/api/http_cache.dart';
import 'package:linefm_radio/data/api/laut_api.dart';
import 'package:linefm_radio/data/artwork/cached_cover_image.dart';
import 'package:linefm_radio/data/artwork/cover_disk_cache.dart';
import 'package:linefm_radio/data/artwork/cover_disk_cache_io.dart';
import 'package:linefm_radio/data/artwork/itunes_artwork.dart';
import 'package:linefm_radio/data/live/now_playing_repository.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/platform/desktop/desktop_init.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:window_manager/legacy.dart' show WindowManager;

const String _outDefine = String.fromEnvironment('ITEST_OUT');
const String _slug = 'linefm';

late final Directory _shotDir;
late final Directory _dataDir;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    installBundledStations(parseStationsConfig(_stationsJson));
    final out = _outDefine.isNotEmpty
        ? _outDefine
        : '${Directory.systemTemp.path}${Platform.pathSeparator}'
              'windows-itest-screens';
    _shotDir = Directory(out)..createSync(recursive: true);
    _dataDir = Directory.systemTemp.createTempSync('linefm_offline_itest_');
    // ignore: avoid_print
    print('Screenshot folder: ${_shotDir.path}, data folder: ${_dataDir.path}');
    await initDesktop();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    CoverImage.diskCache = null;
    try {
      _dataDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Temp folder; Windows may still hold a handle.
    }
  });

  testWidgets('restart while offline shows last track and history with '
      'covers from the disk cache', (tester) async {
    // Below 840 dp the mini player is visible next to the history.
    await _setWindowSize(tester, const Size(820, 720));
    final coverPng = (await rootBundle.load('assets/images/stations/rap.png'))
        .buffer
        .asUint8List();
    final server = await _FakeLautServer.start(coverPng);
    final coversDir = Directory(
      '${_dataDir.path}${Platform.pathSeparator}covers',
    );
    final snapshotFile = File(
      '${_dataDir.path}${Platform.pathSeparator}live_cache.json',
    );

    // ------------------------------------------------------------ Phase 1
    final cache1 = _CountingCoverCache(FileCoverDiskCache(coversDir));
    CoverImage.diskCache = cache1;
    var world = _World(
      prefs: _FilePrefsStore(snapshotFile),
      api: HttpLautApi(baseUri: server.base),
    );
    await _pumpWorld(tester, world);
    final current = server.currentTitle;
    world.container.read(navigationProvider.notifier).go(AppScreen.history);
    await _pumpUntil(
      tester,
      () =>
          find
              .descendant(
                of: find.byType(MiniPlayer),
                matching: find.text(current),
              )
              .evaluate()
              .isNotEmpty &&
          find
              .descendant(
                of: find.byType(HistoryScreen),
                matching: find.text(server.historyTitle),
              )
              .evaluate()
              .isNotEmpty,
      'phase 1: live track in mini player and history',
    );
    await _pumpUntil(
      tester,
      () =>
          _coverFile(coversDir, server.currentCoverUrl).existsSync() &&
          _coverFile(coversDir, server.historyCoverUrl).existsSync() &&
          _paintedCovers(tester, server.currentCoverUrl) > 0 &&
          _snapshotHas(snapshotFile, <String>[current, server.historyTitle]),
      'phase 1: covers cached on disk and snapshot saved',
    );
    expect(server.coverRequests, greaterThan(0));
    expect(
      _coverFile(coversDir, server.currentCoverUrl).readAsBytesSync(),
      coverPng,
      reason: 'cached file holds the served PNG',
    );
    expect(find.text('Zuletzt gesehen'), findsNothing);
    await _shot(world, '01-online-live-data');

    await _disposeWorld(tester, world);
    await (world.prefs as _FilePrefsStore).flush();
    expect(
      _snapshotHas(snapshotFile, <String>[current, server.historyTitle]),
      isTrue,
      reason: 'snapshot on disk is valid JSON with track and history',
    );
    await server.close();

    // ------------------------------------------------------------ Phase 2
    // Restart: nothing survives in memory, only the two folders on disk.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    final offline = _OfflineHttpOverrides();
    HttpOverrides.global = offline;
    final cache2 = _CountingCoverCache(FileCoverDiskCache(coversDir));
    CoverImage.diskCache = cache2;
    final requestsBefore = server.totalRequests;
    world = _World(
      prefs: _FilePrefsStore(snapshotFile),
      // Same address as before; the server is gone.
      api: HttpLautApi(cache: HttpCache(), baseUri: server.base),
    );
    await _pumpWorld(tester, world);
    world.container.read(navigationProvider.notifier).go(AppScreen.history);

    final mini = find.byType(MiniPlayer);
    final history = find.byType(HistoryScreen);
    await _pumpUntil(
      tester,
      () =>
          find
              .descendant(of: mini, matching: find.text(current))
              .evaluate()
              .isNotEmpty &&
          find
              .descendant(of: history, matching: find.text(current))
              .evaluate()
              .isNotEmpty &&
          find
              .descendant(of: history, matching: find.text(server.historyTitle))
              .evaluate()
              .isNotEmpty,
      'phase 2: restored track in mini player and history',
    );
    await _pumpUntil(
      tester,
      () =>
          _paintedCovers(tester, server.currentCoverUrl) > 0 &&
          _paintedCovers(tester, server.historyCoverUrl) > 0,
      'phase 2: covers painted',
    );
    await _pumpFor(tester, const Duration(milliseconds: 800));

    // "Last seen" in the mini player and on the top history entry.
    expect(
      find.descendant(
        of: mini,
        matching: find.textContaining('Zuletzt gesehen'),
      ),
      findsWidgets,
      reason: 'mini player shows the last-seen hint',
    );
    expect(
      find.descendant(
        of: history,
        matching: find.textContaining('Zuletzt gesehen'),
      ),
      findsWidgets,
      reason: 'history shows the last-seen hint',
    );
    final restored = world.container.read(currentTrackProvider).value;
    expect(restored?.title, current);
    expect(restored?.lastSeen, isTrue);
    expect(restored?.artworkUrl, server.currentCoverUrl);

    // Covers came from the disk cache, never from the network.
    expect(cache2.hits[server.currentCoverUrl] ?? 0, greaterThan(0));
    expect(cache2.hits[server.historyCoverUrl] ?? 0, greaterThan(0));
    expect(cache2.misses, isEmpty, reason: 'no cover missed the disk cache');
    expect(cache2.writes, 0, reason: 'nothing was downloaded and stored');
    expect(server.totalRequests, requestsBefore);
    expect(
      offline.attempts,
      greaterThan(0),
      reason: 'the app did try the network and was refused',
    );
    // ignore: avoid_print
    print(
      'Offline: cache hits ${cache2.hits}, refused connections '
      '${offline.attempts}, phase-1 cover requests ${server.coverRequests}',
    );
    expect(tester.takeException(), isNull);
    await _shot(world, '02-offline-restart-restored');

    await _disposeWorld(tester, world);
    HttpOverrides.global = null;
  }, timeout: const Timeout(Duration(minutes: 4)));
}

// ------------------------------------------------------------ Fake server

/// laut.fm stand-in on 127.0.0.1 with recorded fixtures. Times are moved to
/// "now" so the tracks are current; the active station gets cover URLs that
/// point back to this server.
class _FakeLautServer {
  _FakeLautServer._(this._server, this._cover);

  static Future<_FakeLautServer> start(Uint8List cover) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _FakeLautServer._(server, cover)
      ..base = Uri.parse('http://127.0.0.1:${server.port}');
    fake._load();
    server.listen(fake._handle);
    return fake;
  }

  final HttpServer _server;
  final Uint8List _cover;
  late final Uri base;
  final Map<String, String> _bodies = <String, String>{};
  int totalRequests = 0;
  int coverRequests = 0;
  late final String currentTitle;
  late final String historyTitle;

  String get currentCoverUrl => '$base/covers/current.png';
  String get historyCoverUrl => '$base/covers/history.png';

  void _load() {
    final now = DateTime.now().toUtc();
    String iso(DateTime t) => t.toIso8601String();
    for (final s in stationsCatalog) {
      final current = _fixture('${s.slug}_current_song.json');
      final last = _fixture('${s.slug}_last_songs.json');
      if (current is Map<String, Object?>) {
        current
          ..['started_at'] = iso(now.subtract(const Duration(seconds: 30)))
          ..['ends_at'] = iso(now.add(const Duration(minutes: 5)));
        if (s.slug == _slug) {
          current['cover'] = currentCoverUrl;
          currentTitle = current['title']! as String;
        }
        _bodies['/station/${s.slug}/current_song'] = jsonEncode(current);
      }
      if (last is List<Object?>) {
        for (var i = 0; i < last.length; i++) {
          final item = last[i];
          if (item is! Map<String, Object?>) continue;
          item
            ..['started_at'] = iso(
              now.subtract(Duration(minutes: 4 * (i + 1), seconds: 30)),
            )
            ..['ends_at'] = iso(
              now.subtract(Duration(minutes: 4 * i, seconds: 30)),
            );
          if (s.slug == _slug && i == 0) {
            item['cover'] = historyCoverUrl;
            historyTitle = item['title']! as String;
          }
        }
        _bodies['/station/${s.slug}/last_songs'] = jsonEncode(last);
      }
      _bodies['/station/${s.slug}/listeners'] = '12';
      _bodies['/station/${s.slug}/schedule'] = '[]';
    }
  }

  static Object? _fixture(String name) {
    final file = File(
      'test${Platform.pathSeparator}fixtures${Platform.pathSeparator}'
      'laut${Platform.pathSeparator}$name',
    );
    if (!file.existsSync()) return null;
    final text = file.readAsStringSync().trim();
    return text.isEmpty ? null : jsonDecode(text);
  }

  Future<void> _handle(HttpRequest request) async {
    totalRequests++;
    final path = request.uri.path;
    final response = request.response;
    if (path.startsWith('/covers/')) {
      coverRequests++;
      response.headers.contentType = ContentType('image', 'png');
      response.add(_cover);
    } else if (_bodies[path] case final String body) {
      response.headers.contentType = ContentType.json;
      response.write(body);
    } else {
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }

  Future<void> close() => _server.close(force: true);
}

/// Every new connection fails like a machine without network.
class _OfflineHttpOverrides extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..connectionFactory = (uri, proxyHost, proxyPort) {
          attempts++;
          return Future<ConnectionTask<Socket>>.error(
            SocketException(
              'Offline (test)',
              address: InternetAddress(uri.host),
            ),
          );
        };
}

// ---------------------------------------------------------------- Storage

/// Disk cache wrapper that records where each cover came from.
class _CountingCoverCache implements CoverDiskCache {
  _CountingCoverCache(this._inner);

  final CoverDiskCache _inner;
  final Map<String, int> hits = <String, int>{};
  final Set<String> misses = <String>{};
  int writes = 0;

  @override
  Future<Uint8List?> read(String url) async {
    final bytes = await _inner.read(url);
    if (bytes == null) {
      misses.add(url);
    } else {
      hits[url] = (hits[url] ?? 0) + 1;
    }
    return bytes;
  }

  @override
  Future<void> write(String url, Uint8List bytes) {
    writes++;
    return _inner.write(url, bytes);
  }

  @override
  Future<void> setMaxBytes(int maxBytes) => _inner.setMaxBytes(maxBytes);

  @override
  Future<void> clear() => _inner.clear();
}

/// In-memory store whose live snapshot lives in a file, so it survives the
/// simulated restart. Settings and consent are set fresh on every start.
class _FilePrefsStore extends InMemoryPrefsStore {
  _FilePrefsStore(this._file) {
    writeSettings(
      const AppSettings(
        autoplay: false,
        marquee: false,
        loadArtwork: false,
        // Fixed language: CI runners use an English system locale.
        language: AppLanguage.de,
      ),
    ).ignore();
    setStorageConsent(value: true).ignore();
  }

  final File _file;

  @override
  String? readLiveCache() =>
      _file.existsSync() ? _file.readAsStringSync() : null;

  Future<void> _writes = Future<void>.value();

  /// Writes one after another and atomically (temp file, then rename).
  /// Overlapping writeAsString calls on the same file can interleave and
  /// leave invalid JSON, which the restart then silently ignores.
  @override
  Future<void> writeLiveCache(String json) => _writes = _writes.then((_) async {
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(_file.path);
  });

  /// Completes when every write so far is on disk.
  Future<void> flush() => _writes;
}

/// True when [file] holds valid JSON that contains every one of [texts].
bool _snapshotHas(File file, List<String> texts) {
  if (!file.existsSync()) return false;
  final text = file.readAsStringSync();
  try {
    jsonDecode(text);
  } on FormatException {
    return false;
  }
  return texts.every(text.contains);
}

File _coverFile(Directory dir, String url) =>
    File('${dir.path}${Platform.pathSeparator}${coverCacheKey(url)}.img');

// ------------------------------------------------------------------ World

class _World {
  _World({required this.prefs, required LautApi api}) {
    container = ProviderContainer(
      overrides: <Override>[
        prefsProvider.overrideWithValue(prefs),
        playbackServiceProvider.overrideWithValue(NoopPlaybackService()),
        lautApiProvider.overrideWithValue(api),
        telemetryConsentProvider.overrideWith(_ConsentGiven.new),
        artworkProvider.overrideWithValue(const ApiCoverOnlyArtworkService()),
        nowPlayingRepositoryProvider.overrideWith((ref) {
          final repo = LiveNowPlayingRepository(
            api: api,
            artwork: const ApiCoverOnlyArtworkService(),
            activeStation: ref.read(activeStationProvider),
            pollInterval: const Duration(hours: 1),
            maxEndsAtDelay: const Duration(hours: 1),
            unknownEndDelay: const Duration(hours: 1),
            readSnapshot: prefs.readLiveCache,
            writeSnapshot: prefs.writeLiveCache,
          );
          bindNowPlayingRepository(ref, repo);
          return repo;
        }),
      ],
    );
  }

  final PrefsStore prefs;
  late final ProviderContainer container;
  final GlobalKey shotKey = GlobalKey();
}

class _ConsentGiven extends TelemetryConsentNotifier {
  @override
  bool? build() => true;
}

Future<void> _pumpWorld(WidgetTester tester, _World world) async {
  loaderShownThisProcess = true;
  await tester.pumpWidget(
    RepaintBoundary(
      key: world.shotKey,
      child: UncontrolledProviderScope(
        container: world.container,
        child: const LinefmApp(),
      ),
    ),
  );
  await _pumpFor(tester, const Duration(milliseconds: 1500));
}

Future<void> _disposeWorld(WidgetTester tester, _World world) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 200));
  world.container.dispose();
}

/// Number of painted images whose provider is the cached cover for [url].
int _paintedCovers(WidgetTester tester, String url) {
  var count = 0;
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    var provider = image.image;
    if (provider is ResizeImage) provider = provider.imageProvider;
    if (provider is! CachedCoverImage || provider.url != url) continue;
    final raw = find.descendant(
      of: find.byWidget(image),
      matching: find.byType(RawImage),
    );
    if (raw.evaluate().any((e) => (e.widget as RawImage).image != null)) {
      count++;
    }
  }
  return count;
}

// ---------------------------------------------------------------- Waiting

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String what, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for: $what');
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _setWindowSize(WidgetTester tester, Size size) async {
  final wm = WindowManager.instance;
  if (await wm.isMaximized()) await wm.unmaximize();
  await wm.setSize(size);
  final end = DateTime.now().add(const Duration(seconds: 10));
  final view = tester.view;
  while ((view.physicalSize.width / view.devicePixelRatio - size.width).abs() >
      40) {
    if (DateTime.now().isAfter(end)) {
      fail('View does not match window size $size');
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _shot(_World world, String name) async {
  final context = world.shotKey.currentContext;
  expect(context, isNotNull);
  final boundary = context!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(
    '${_shotDir.path}${Platform.pathSeparator}offline-restore-$name.png',
  )..writeAsBytesSync(data!.buffer.asUint8List());
  // ignore: avoid_print
  print('Screenshot: ${file.path}');
}

const String _stationsJson =
    r'''{"schemaVersion": 1, "sender": [{"kuerzel": "linefm", "name": "LineFM +MAIN", "farbe": "#4B4B7D", "logo": "https://cdn.linefm.de/images/icons/main.png", "logoDatei": "assets/images/stations/main.png"}, {"kuerzel": "linefmrap", "name": "LineFM +RAP", "farbe": "#FF0084", "logo": "https://cdn.linefm.de/images/icons/rap.png", "logoDatei": "assets/images/stations/rap.png"}, {"kuerzel": "linefmgaming", "name": "LineFM +GAMING", "farbe": "#4BBD71", "logo": "https://cdn.linefm.de/images/icons/gaming.png", "logoDatei": "assets/images/stations/gaming.png"}, {"kuerzel": "linefmlofi", "name": "LineFM +LOFI", "farbe": "#546E7A", "logo": "https://cdn.linefm.de/images/icons/lofi.png", "logoDatei": "assets/images/stations/lofi.png"}, {"kuerzel": "radio3fm", "name": "Radio3FM", "farbe": "#177D29", "logo": "https://cdn.linefm.de/images/icons/radio3fm.png", "logoDatei": "assets/images/stations/radio3fm.png"}, {"kuerzel": "fobfm", "name": "FobFM", "farbe": "#04FFF7", "logo": "https://cdn.linefm.de/images/icons/fobfm.png", "logoDatei": "assets/images/stations/fobfm.png"}]}''';
