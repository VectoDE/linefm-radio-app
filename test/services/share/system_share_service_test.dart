import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/services/share/share_feedback.dart';
import 'package:linefm_radio/services/share/share_links.dart';
import 'package:linefm_radio/services/share/system_share_service.dart';

class _Backend implements ShareBackend {
  _Backend({
    this.isWeb = false,
    this.platform = TargetPlatform.android,
    this.textStatus = ShareStatus.shared,
    this.fileStatus = ShareStatus.shared,
    this.launchOk = true,
  });

  @override
  final bool isWeb;
  @override
  final TargetPlatform platform;
  ShareStatus textStatus;
  ShareStatus fileStatus;
  bool launchOk;

  final List<String> texts = <String>[];
  final List<String> clipboard = <String>[];
  final List<(String, Uint8List, String)> files =
      <(String, Uint8List, String)>[];
  final List<(String, Uint8List, String)> downloads =
      <(String, Uint8List, String)>[];
  final List<(String, Uint8List)> saved = <(String, Uint8List)>[];
  final List<Uri> launched = <Uri>[];

  @override
  Future<ShareStatus> shareText(String text) async {
    texts.add(text);
    return textStatus;
  }

  @override
  Future<ShareStatus> shareFile(
    Uint8List bytes,
    String name,
    String mime,
  ) async {
    files.add((name, bytes, mime));
    return fileStatus;
  }

  @override
  Future<void> copyToClipboard(String text) async => clipboard.add(text);

  @override
  void download(String name, Uint8List bytes, String mime) =>
      downloads.add((name, bytes, mime));

  @override
  Future<String> saveToDownloads(String name, Uint8List bytes) async {
    saved.add((name, bytes));
    return '/home/u/Downloads/$name';
  }

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return launchOk;
  }
}

final _station = stationsCatalog.first;
const _track = Track(artist: 'Michael Calfan', title: 'Waterfall');

final List<Favorite> _favorites = <Favorite>[
  Favorite(
    key: 'linefm:ärzte:über',
    stationSlug: 'linefm',
    title: 'Über den Wolken',
    artist: 'Reinhard Mey',
    savedAt: DateTime(2026, 11, 18, 21, 5),
  ),
];

void main() {
  late _Backend backend;
  late List<ShareFeedback> feedback;

  SystemShareService service({String lang = 'de'}) => SystemShareService(
    webBaseUrl: 'https://app.linefm.de/',
    locale: () => Locale(lang),
    backend: backend,
    feedback: feedback.add,
  );

  setUp(() {
    backend = _Backend();
    feedback = <ShareFeedback>[];
  });

  group('Links', () {
    test('Web-Link und App-Link eines Senders', () {
      expect(
        ShareLinks.stationUrl('https://app.linefm.de/', _station),
        'https://app.linefm.de/?station=linefm',
      );
      expect(
        ShareLinks.stationAppLink(_station).toString(),
        'linefm://play?station=linefm',
      );
    });
  });

  group('Song teilen', () {
    test('Text im Wortlaut mit Link auf den Sender', () async {
      await service().shareSong(_station, _track);
      expect(backend.texts, hasLength(1));
      expect(
        backend.texts.single,
        'Ich höre gerade „Waterfall“ von Michael Calfan auf '
        '${_station.displayName}. https://app.linefm.de/?station=linefm',
      );
      expect(feedback, isEmpty);
    });

    test('englischer Text', () async {
      await service(lang: 'en').shareSong(_station, _track);
      expect(backend.texts.single, startsWith('I’m listening to “Waterfall”'));
    });

    test('Web ohne Web Share API: Zwischenablage mit Hinweis', () async {
      backend = _Backend(isWeb: true, textStatus: ShareStatus.unavailable);
      await service().shareSong(_station, _track);
      expect(backend.clipboard, hasLength(1));
      expect(backend.clipboard.single, contains('?station=linefm'));
      expect(feedback.single.kind, ShareFeedbackKind.copied);
    });

    test('Linux: kein Teilen, direkt Zwischenablage', () async {
      backend = _Backend(platform: TargetPlatform.linux);
      await service().shareText('Hallo');
      expect(backend.texts, isEmpty);
      expect(backend.clipboard, <String>['Hallo']);
      expect(feedback.single.kind, ShareFeedbackKind.copied);
    });

    test('abgebrochen: keine Meldung, keine Zwischenablage', () async {
      backend = _Backend(textStatus: ShareStatus.dismissed);
      await service().shareText('Hallo');
      expect(backend.clipboard, isEmpty);
      expect(feedback, isEmpty);
    });
  });

  group('Favoriten-Export', () {
    test('Android: CSV als Datei ueber das Teilen-Menue', () async {
      await service().exportFavorites(_favorites, ExportFormat.csv);
      final (name, bytes, mime) = backend.files.single;
      expect(name, 'linefm-favoriten.csv');
      expect(mime, 'text/csv');
      // UTF-8-BOM, damit Excel Umlaute richtig liest.
      expect(bytes.sublist(0, 3), <int>[0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(bytes.sublist(3));
      expect(text.split('\r\n').first, 'Titel;Künstler;Sender;Gemerkt am');
      expect(text, contains('Über den Wolken;Reinhard Mey;'));
      expect(text, contains('2026-11-18 21:05'));
    });

    test('englische Spaltenkoepfe und Dateiname', () async {
      await service(lang: 'en').exportFavorites(_favorites, ExportFormat.csv);
      expect(backend.files.single.$1, 'linefm-favorites.csv');
      expect(
        utf8.decode(backend.files.single.$2.sublist(3)).split('\r\n').first,
        'Title;Artist;Station;Saved on',
      );
    });

    test('Text-Export als .txt-Datei', () async {
      await service().exportFavorites(_favorites, ExportFormat.text);
      final (name, bytes, mime) = backend.files.single;
      expect(name, 'linefm-favoriten.txt');
      expect(mime, 'text/plain');
      expect(
        utf8.decode(bytes),
        'Reinhard Mey - Über den Wolken (${_station.displayName})\n',
      );
    });

    test('Web: Download statt Teilen-Menue', () async {
      backend = _Backend(isWeb: true);
      await service().exportFavorites(_favorites, ExportFormat.csv);
      expect(backend.files, isEmpty);
      final (name, _, mime) = backend.downloads.single;
      expect(name, 'linefm-favoriten.csv');
      expect(mime, 'text/csv;charset=utf-8');
      expect(feedback, isEmpty);
    });

    test('Linux: Download-Ordner mit Pfad-Hinweis', () async {
      backend = _Backend(platform: TargetPlatform.linux);
      await service().exportFavorites(_favorites, ExportFormat.csv);
      expect(backend.files, isEmpty);
      expect(backend.saved.single.$1, 'linefm-favoriten.csv');
      expect(feedback.single.kind, ShareFeedbackKind.savedTo);
      expect(feedback.single.path, '/home/u/Downloads/linefm-favoriten.csv');
    });

    test('Windows: Teilen nicht verfuegbar -> Download-Ordner', () async {
      backend = _Backend(
        platform: TargetPlatform.windows,
        fileStatus: ShareStatus.unavailable,
      );
      await service().exportFavorites(_favorites, ExportFormat.csv);
      expect(backend.files, hasLength(1));
      expect(backend.saved, hasLength(1));
      expect(feedback.single.kind, ShareFeedbackKind.savedTo);
    });

    test('Android: Teilen nicht verfuegbar -> Fehler an den Aufrufer', () {
      backend = _Backend(fileStatus: ShareStatus.unavailable);
      expect(
        service().exportFavorites(_favorites, ExportFormat.csv),
        throwsStateError,
      );
    });
  });

  group('Links oeffnen', () {
    test('oeffnet extern', () async {
      await service().openUrl(Uri.parse('https://open.spotify.com/search/x'));
      expect(backend.launched.single.host, 'open.spotify.com');
    });

    test('Fehlschlag wirft', () {
      backend = _Backend(launchOk: false);
      expect(
        service().openUrl(Uri.parse('https://example.org')),
        throwsStateError,
      );
    });
  });
}
