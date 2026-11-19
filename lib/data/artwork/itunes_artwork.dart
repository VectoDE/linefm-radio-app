import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/clock.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/track.dart';

class ArtworkResult {
  const ArtworkResult({this.artworkUrl, this.trackViewUrl});

  /// 600x600-Cover.
  final String? artworkUrl;

  /// Apple-Music-Link des Treffers.
  final String? trackViewUrl;

  Map<String, Object?> toJson() => <String, Object?>{
    if (artworkUrl != null) 'a': artworkUrl,
    if (trackViewUrl != null) 'v': trackViewUrl,
  };

  static ArtworkResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final a = json['a'];
    final v = json['v'];
    return ArtworkResult(
      artworkUrl: a is String ? a : null,
      trackViewUrl: v is String ? v : null,
    );
  }
}

/// iTunes-Cover-Lookup mit Drosselung und Cache (Spec 3.3).
abstract interface class ArtworkService {
  /// `null` = kein Cover gefunden (Aufrufer faellt auf Senderlogo bzw.
  /// Kuerzel-Kachel zurueck).
  Future<ArtworkResult?> lookup(Track track, {bool priority = false});
}

class NoopArtworkService implements ArtworkService {
  const NoopArtworkService();

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) async =>
      null;
}

/// Ohne iTunes-Suche: nur ein Cover, das die laut.fm-API schon mitliefert
/// (Einstellung "Cover laden" aus, L5).
class ApiCoverOnlyArtworkService implements ArtworkService {
  const ApiCoverOnlyArtworkService();

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) async {
    final cover = track.artworkUrl;
    return cover == null || cover.isEmpty
        ? null
        : ArtworkResult(artworkUrl: cover);
  }
}

/// Persistenter Speicher fuer den Cover-Cache (JSON-Text). Passt zu
/// `PrefsStore.readCoverCache`/`writeCoverCache`, z. B.:
/// `CoverCacheStore(read: prefs.readCoverCache, write: prefs.writeCoverCache)`.
class CoverCacheStore {
  const CoverCacheStore({required this.read, required this.write});

  final String? Function() read;
  final Future<void> Function(String json) write;
}

/// Echte Implementierung gegen die iTunes Search API.
///
/// - URL wie Web-App plus `country=DE`, `artworkUrl100` -> `600x600bb`.
/// - Cache-Schluessel `"artist title".trim().toLowerCase()` (Web-App).
/// - In-Memory-LRU mit [maxEntries] Eintraegen; persistent ebenso viele,
///   Treffer [positiveTtl], Fehltreffer [negativeTtl].
/// - Drosselung: max. [maxParallel] parallel, mind. [minGap] zwischen zwei
///   Anfragestarts, Prioritaet vor Verlauf; bei 403/429 [penalty] Pause.
/// - Hat der Track schon ein Cover aus der laut.fm-API, wird es ohne
///   Anfrage zurueckgegeben (Rueckfall-Kette Spec 3.3).
/// - Treffer werden geprueft (D8): Kuenstler und Titel muessen nach
///   [normalize] zum laufenden Titel passen ([matchesTrack]). Sonst gilt die
///   Suche als Fehltreffer und die App zeigt das Senderlogo. Die Web-App nahm
///   den ersten Treffer ungeprueft (Biene-Maja-Cover zu "Zusammen").
/// - Jede Anfrage bricht nach [timeout] ab (S5).
class ItunesArtworkService implements ArtworkService {
  ItunesArtworkService({
    http.Client? client,
    this._clock = const SystemClock(),
    Future<void> Function(Duration)? sleep,
    this.store,
    this.maxEntries = 300,
    this.positiveTtl = const Duration(days: 30),
    this.negativeTtl = const Duration(days: 1),
    this.maxParallel = 2,
    this.minGap = const Duration(milliseconds: 1500),
    this.penalty = const Duration(minutes: 5),
    this.persistDelay = const Duration(seconds: 5),
    this.country = 'DE',
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _sleep = sleep ?? _defaultSleep {
    _load();
  }

  static Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);

  final CoverCacheStore? store;
  final int maxEntries;
  final Duration positiveTtl;
  final Duration negativeTtl;
  final int maxParallel;
  final Duration minGap;
  final Duration penalty;
  final Duration persistDelay;
  final String country;

  /// Hoechstdauer einer Anfrage; danach gilt sie als Netzwerkfehler.
  final Duration timeout;

  final http.Client _client;
  final Clock _clock;
  final Future<void> Function(Duration) _sleep;

  // LinkedHashMap: Einfuegereihenfolge = LRU-Reihenfolge.
  final LinkedHashMap<String, _CacheItem> _cache =
      LinkedHashMap<String, _CacheItem>();
  final Map<String, Future<ArtworkResult?>> _inFlight =
      <String, Future<ArtworkResult?>>{};
  final Queue<_Job> _priorityQueue = Queue<_Job>();
  final Queue<_Job> _normalQueue = Queue<_Job>();
  int _running = 0;
  DateTime? _lastStart;
  DateTime? _blockedUntil;
  bool _pumping = false;
  Timer? _persistTimer;

  /// Anzahl echter Anfragen (Tests/Diagnose).
  int networkRequests = 0;

  /// Version 2: Treffer sind geprueft (D8); ungepruefte Eintraege der
  /// Version 1 werden verworfen.
  static const int _cacheVersion = 2;

  static String keyFor(Track track) =>
      '${track.artist} ${track.title}'.trim().toLowerCase();

  /// Web-App: `artworkUrl100.replace("100x100bb", "600x600bb")`.
  static String upscale(String artworkUrl100) =>
      artworkUrl100.replaceFirst('100x100bb', '600x600bb');

  Uri searchUri(Track track) => Uri.https('itunes.apple.com', '/search', {
    'term': '${track.artist} ${track.title}'.trim(),
    'entity': 'song',
    // Mehrere Treffer, damit [matchesTrack] den passenden waehlen kann.
    'limit': '5',
    'country': country,
  });

  @override
  Future<ArtworkResult?> lookup(Track track, {bool priority = false}) {
    final apiCover = track.artworkUrl;
    if (apiCover != null && apiCover.isNotEmpty) {
      return Future<ArtworkResult?>.value(ArtworkResult(artworkUrl: apiCover));
    }
    final key = keyFor(track);
    if (key.isEmpty) return Future<ArtworkResult?>.value();

    final cached = _cache[key];
    if (cached != null) {
      if (_clock.now().isBefore(cached.expiresAt)) {
        _cache
          ..remove(key)
          ..[key] = cached;
        return Future<ArtworkResult?>.value(cached.result);
      }
      _cache.remove(key);
    }

    final running = _inFlight[key];
    if (running != null) {
      if (priority) _promote(key);
      return running;
    }

    final job = _Job(key, track);
    (priority ? _priorityQueue : _normalQueue).add(job);
    // Block-Rumpf: remove() liefert dieses Future; als Rueckgabewert von
    // whenComplete wuerde es auf sich selbst warten (Deadlock).
    final future = job.completer.future.whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    unawaited(_pump());
    return future;
  }

  /// Schreibt ausstehende Aenderungen sofort in den Speicher.
  Future<void> flush() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    await _persist();
  }

  Future<void> dispose() async {
    await flush();
    _client.close();
  }

  void _promote(String key) {
    final job = _normalQueue.where((j) => j.key == key).firstOrNull;
    if (job == null) return;
    _normalQueue.remove(job);
    _priorityQueue.add(job);
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (_running < maxParallel &&
          (_priorityQueue.isNotEmpty || _normalQueue.isNotEmpty)) {
        final now = _clock.now();
        final blocked = _blockedUntil;
        if (blocked != null && now.isBefore(blocked)) {
          // Waehrend der Strafpause: offene Anfragen ohne Cover beantworten,
          // nichts negativ cachen.
          for (final job in <_Job>[..._priorityQueue, ..._normalQueue]) {
            job.completer.complete(null);
          }
          _priorityQueue.clear();
          _normalQueue.clear();
          return;
        }
        final last = _lastStart;
        if (last != null) {
          final wait = last.add(minGap).difference(now);
          if (wait > Duration.zero) {
            await _sleep(wait);
            continue;
          }
        }
        final job = _priorityQueue.isNotEmpty
            ? _priorityQueue.removeFirst()
            : _normalQueue.removeFirst();
        _lastStart = _clock.now();
        _running++;
        unawaited(
          _run(job).whenComplete(() {
            _running--;
            unawaited(_pump());
          }),
        );
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(_Job job) async {
    try {
      networkRequests++;
      final response = await _client
          .get(
            searchUri(job.track),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode == 403 || response.statusCode == 429) {
        _blockedUntil = _clock.now().add(penalty);
        logInfo(
          'iTunes: ${response.statusCode}, Pause ${penalty.inMinutes} min',
        );
        job.completer.complete(null);
        return;
      }
      if (response.statusCode != 200) {
        job.completer.complete(null);
        return;
      }
      final result = parseSearch(
        utf8.decode(response.bodyBytes),
        track: job.track,
      );
      _put(job.key, result);
      job.completer.complete(result);
    } on Object catch (e) {
      // Netzwerkfehler: nicht cachen, spaeter erneut versuchen.
      logError('iTunes-Lookup fehlgeschlagen', e);
      if (!job.completer.isCompleted) job.completer.complete(null);
    }
  }

  /// Wertet eine iTunes-Antwort aus; `null` = kein Treffer. Mit [track]
  /// zaehlt nur ein Ergebnis, dessen Kuenstler und Titel passen
  /// ([matchesTrack]); ohne [track] das erste.
  static ArtworkResult? parseSearch(String body, {Track? track}) {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json is! Map) return null;
    final results = json['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.whereType<Map<Object?, Object?>>().where((r) {
      if (track == null) return true;
      final artist = r['artistName'];
      final title = r['trackName'];
      return artist is String &&
          title is String &&
          matchesTrack(track, artist: artist, title: title);
    }).firstOrNull;
    if (first == null) return null;
    final art = first['artworkUrl100'];
    final view = first['trackViewUrl'];
    final artworkUrl = art is String && art.startsWith('https://')
        ? upscale(art)
        : null;
    final trackViewUrl = view is String && view.startsWith('https://')
        ? view
        : null;
    if (artworkUrl == null && trackViewUrl == null) return null;
    return ArtworkResult(artworkUrl: artworkUrl, trackViewUrl: trackViewUrl);
  }

  /// Kleinbuchstaben, Klammerzusaetze ("(feat. X)", "[Remix]") und Satz-
  /// zeichen entfernt, "&"/"and"/"und" vereinheitlicht, Leerraum gestaucht.
  static String normalize(String value) {
    var v = value.toLowerCase();
    v = v.replaceAll(RegExp(r'[\(\[][^\)\]]*[\)\]]'), ' ');
    v = v.replaceAll(RegExp(r'\s(feat\.?|ft\.?|featuring)\s.*$'), ' ');
    v = v.replaceAll(RegExp(r'\s(&|and|und|x|vs\.?)\s'), ' ');
    v = v.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    return v.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Passt ein iTunes-Ergebnis zum laufenden Titel? Titel: gleich oder einer
  /// beginnt mit dem anderen (Zusaetze wie "Radio Edit"). Kuenstler: der
  /// erste Name des laut.fm-Kuenstlers steckt im iTunes-Kuenstler oder
  /// umgekehrt (Gemeinschaftstitel werden je Dienst anders geschrieben).
  static bool matchesTrack(
    Track track, {
    required String artist,
    required String title,
  }) {
    final wantTitle = normalize(track.title);
    final gotTitle = normalize(title);
    if (wantTitle.isEmpty || gotTitle.isEmpty) return false;
    final titleOk =
        wantTitle == gotTitle ||
        gotTitle.startsWith(wantTitle) ||
        wantTitle.startsWith(gotTitle);
    if (!titleOk) return false;
    final wantArtist = normalize(_primaryArtist(track.artist));
    final gotArtist = normalize(artist);
    if (wantArtist.isEmpty || gotArtist.isEmpty) return false;
    return gotArtist.contains(wantArtist) ||
        wantArtist.contains(normalize(_primaryArtist(artist)));
  }

  /// Erster Name einer Kuenstlerangabe ("A & B", "A feat. B", "A, B").
  static String _primaryArtist(String artist) => artist
      .split(
        RegExp(
          r'\s*(,|&|feat\.?|ft\.?|featuring|x|vs\.?|und|and)\s*',
          caseSensitive: false,
        ),
      )
      .first;

  void _put(String key, ArtworkResult? result) {
    final ttl = result?.artworkUrl == null ? negativeTtl : positiveTtl;
    _cache
      ..remove(key)
      ..[key] = _CacheItem(result, _clock.now().add(ttl));
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _schedulePersist();
  }

  void _schedulePersist() {
    if (store == null || _persistTimer != null) return;
    _persistTimer = Timer(persistDelay, () {
      _persistTimer = null;
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    final s = store;
    if (s == null) return;
    final now = _clock.now();
    final data = <String, Object?>{
      'v': _cacheVersion,
      'e': <String, Object?>{
        for (final MapEntry(:key, :value) in _cache.entries)
          if (now.isBefore(value.expiresAt))
            key: <String, Object?>{
              'x': value.expiresAt.millisecondsSinceEpoch,
              if (value.result != null) 'r': value.result!.toJson(),
            },
      },
    };
    try {
      await s.write(jsonEncode(data));
    } on Object catch (e) {
      logError('Cover-Cache konnte nicht gespeichert werden', e);
    }
  }

  void _load() {
    final text = store?.read();
    if (text == null || text.isEmpty) return;
    try {
      final json = jsonDecode(text);
      if (json is! Map || json['v'] != _cacheVersion) return;
      final entries = json['e'];
      if (entries is! Map) return;
      final now = _clock.now();
      final loaded = <(String, _CacheItem)>[];
      for (final MapEntry(:key, :value) in entries.entries) {
        if (key is! String || value is! Map) continue;
        final x = value['x'];
        if (x is! int) continue;
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(x);
        if (!now.isBefore(expiresAt)) continue;
        loaded.add((
          key,
          _CacheItem(ArtworkResult.fromJson(value['r']), expiresAt),
        ));
      }
      for (final (key, item) in loaded.skip(
        loaded.length > maxEntries ? loaded.length - maxEntries : 0,
      )) {
        _cache[key] = item;
      }
    } on FormatException {
      // Kaputter Cache: verwerfen.
    }
  }
}

class _CacheItem {
  const _CacheItem(this.result, this.expiresAt);

  /// `null` = Fehltreffer (negativ gecacht).
  final ArtworkResult? result;
  final DateTime expiresAt;
}

class _Job {
  _Job(this.key, this.track);

  final String key;
  final Track track;
  final Completer<ArtworkResult?> completer = Completer<ArtworkResult?>();
}
