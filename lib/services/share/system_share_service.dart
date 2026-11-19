import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/share/file_delivery.dart' as delivery;
import 'package:linefm_radio/services/share/share_feedback.dart';
import 'package:linefm_radio/services/share/share_links.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ergebnis eines Teilen-Versuchs.
enum ShareStatus {
  /// Teilen-Menue wurde bedient (oder Ergebnis unbekannt).
  shared,

  /// Nutzer hat abgebrochen.
  dismissed,

  /// Auf diesem Geraet/Browser gibt es kein Teilen.
  unavailable,
}

/// Plattformzugriffe des Teilen-Dienstes; in Tests ersetzbar.
abstract interface class ShareBackend {
  bool get isWeb;
  TargetPlatform get platform;

  Future<ShareStatus> shareText(String text);

  Future<ShareStatus> shareFile(Uint8List bytes, String name, String mime);

  Future<void> copyToClipboard(String text);

  /// Browser-Download (nur Web).
  void download(String name, Uint8List bytes, String mime);

  /// Datei in den Download-Ordner schreiben, liefert den Pfad.
  Future<String> saveToDownloads(String name, Uint8List bytes);

  Future<bool> launch(Uri uri);
}

/// Echte Plattformzugriffe: share_plus, Zwischenablage, url_launcher.
class PluginShareBackend implements ShareBackend {
  const PluginShareBackend();

  @override
  bool get isWeb => kIsWeb;

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  static ShareStatus _map(ShareResult result) => switch (result.status) {
    ShareResultStatus.success => ShareStatus.shared,
    ShareResultStatus.dismissed => ShareStatus.dismissed,
    ShareResultStatus.unavailable => ShareStatus.shared,
  };

  @override
  Future<ShareStatus> shareText(String text) async {
    try {
      // Kein mailto-Ersatz: ohne Web Share API kopieren wir stattdessen.
      return _map(
        await SharePlus.instance.share(
          ShareParams(text: text, mailToFallbackEnabled: false),
        ),
      );
    } on Object catch (e) {
      logError('Teilen nicht verfuegbar', e);
      return ShareStatus.unavailable;
    }
  }

  @override
  Future<ShareStatus> shareFile(
    Uint8List bytes,
    String name,
    String mime,
  ) async {
    try {
      return _map(
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile.fromData(bytes, mimeType: mime, name: name)],
            fileNameOverrides: <String>[name],
            downloadFallbackEnabled: false,
          ),
        ),
      );
    } on Object catch (e) {
      logError('Datei teilen nicht verfuegbar', e);
      return ShareStatus.unavailable;
    }
  }

  @override
  Future<void> copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  void download(String name, Uint8List bytes, String mime) =>
      delivery.triggerBrowserDownload(name, bytes, mime);

  @override
  Future<String> saveToDownloads(String name, Uint8List bytes) =>
      delivery.saveToDownloadFolder(name, bytes);

  @override
  Future<bool> launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Teilen, Export und Links ueber die Systemfunktionen (Spec 2.2, Fussnote 10).
///
/// - Song/Sender teilen: Teilen-Menue (`share_plus`; Web: Web Share API).
///   Gibt es kein Teilen (Linux, Browser ohne Web Share API), landet der Text
///   in der Zwischenablage und die App meldet "In die Zwischenablage
///   kopiert.".
/// - Favoriten exportieren: CSV (UTF-8 mit BOM, Semikolon, oeffnet in Excel
///   mit korrekten Umlauten) bzw. Textliste als DATEI. Android/iOS/macOS:
///   Teilen-Menue. Windows: Teilen-Menue, sonst Download-Ordner. Linux:
///   Download-Ordner mit Hinweis auf den Pfad. Web: Browser-Download.
/// - Links: externe App bzw. neuer Browser-Tab; Fehlschlag wirft eine
///   Ausnahme, damit der Aufrufer "Der Link konnte nicht geoeffnet werden."
///   zeigen kann.
class SystemShareService implements ShareService {
  SystemShareService({
    required this.webBaseUrl,
    Locale? Function()? locale,
    this._backend = const PluginShareBackend(),
    void Function(ShareFeedback feedback)? feedback,
  }) : _locale = locale ?? (() => PlatformDispatcher.instance.locale),
       _feedback = feedback ?? ShareFeedbackBus.emit;

  final String webBaseUrl;
  final Locale? Function() _locale;
  final ShareBackend _backend;
  final void Function(ShareFeedback feedback) _feedback;

  bool get _de => _locale()?.languageCode == 'de';

  AppLocalizations get _l10n =>
      lookupAppLocalizations(Locale(_de ? 'de' : 'en'));

  /// Link auf den Sender (gleiches Format wie "Sender teilen").
  String stationUrl(Station station) =>
      ShareLinks.stationUrl(webBaseUrl, station);

  @override
  Future<void> shareSong(Station station, Track track) async {
    try {
      await shareText(
        _l10n.shareSongText(
          track.artist,
          station.displayName,
          track.title,
          stationUrl(station),
        ),
      );
    } on Object catch (e) {
      logError('Song teilen', e);
      _feedback(const ShareFeedback(ShareFeedbackKind.failed));
    }
  }

  @override
  Future<void> shareText(String text) async {
    final status = _backend.platform == TargetPlatform.linux && !_backend.isWeb
        ? ShareStatus.unavailable
        : await _backend.shareText(text);
    if (status != ShareStatus.unavailable) return;
    await _backend.copyToClipboard(text);
    _feedback(const ShareFeedback(ShareFeedbackKind.copied));
  }

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {
    final content = FavoritesExport.build(
      favorites,
      format,
      labels: _de ? FavoritesExportLabels.de : FavoritesExportLabels.en,
    );
    final isCsv = format == ExportFormat.csv;
    final name = exportFileName(format, de: _de);
    final mime = isCsv ? 'text/csv' : 'text/plain';
    final bytes = Uint8List.fromList(
      utf8.encode(isCsv ? content : '$content\n'),
    );

    if (_backend.isWeb) {
      _backend.download(name, bytes, '$mime;charset=utf-8');
      return;
    }
    final desktop = switch (_backend.platform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
    if (_backend.platform != TargetPlatform.linux) {
      final status = await _backend.shareFile(bytes, name, mime);
      if (status != ShareStatus.unavailable) return;
      if (!desktop) throw StateError('Teilen von Dateien nicht verfuegbar');
    }
    final path = await _backend.saveToDownloads(name, bytes);
    _feedback(ShareFeedback(ShareFeedbackKind.savedTo, path: path));
  }

  /// `linefm-favoriten.csv` bzw. `linefm-favorites.txt`.
  static String exportFileName(ExportFormat format, {required bool de}) {
    final base = de ? 'linefm-favoriten' : 'linefm-favorites';
    return format == ExportFormat.csv ? '$base.csv' : '$base.txt';
  }

  @override
  Future<void> openUrl(Uri uri) async {
    final ok = await _backend.launch(uri);
    if (!ok) throw StateError('Link konnte nicht geoeffnet werden: $uri');
  }
}
