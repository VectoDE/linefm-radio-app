import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/share/share_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Grundausstattung fuer Teilen, Export und Links ueber die Systemdialoge
/// (share_plus, url_launcher), bis P21 den vollstaendigen Dienst liefert.
///
/// - Song teilen: Text "Ich hoere gerade ..." plus Link auf den Sender.
/// - Export: CSV als Datei, Text als geteilter Text.
/// - Links: externe App bzw. neuer Browser-Tab; Fehlschlag wirft eine
///   Ausnahme, damit der Aufrufer "Der Link konnte nicht geoeffnet werden."
///   zeigen kann.
class SystemShareService implements ShareService {
  SystemShareService({required this.webBaseUrl, Locale? Function()? locale})
    : _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final String webBaseUrl;
  final Locale? Function() _locale;

  AppLocalizations get _l10n {
    final code = _locale()?.languageCode == 'de' ? 'de' : 'en';
    return lookupAppLocalizations(Locale(code));
  }

  /// Link auf den Sender (gleiches Format wie "Sender teilen").
  String stationUrl(Station station) {
    final base = webBaseUrl.endsWith('/')
        ? webBaseUrl.substring(0, webBaseUrl.length - 1)
        : webBaseUrl;
    return '$base/?station=${station.slug}';
  }

  @override
  Future<void> shareSong(Station station, Track track) async {
    final text = _l10n.shareSongText(
      track.artist,
      station.displayName,
      track.title,
      stationUrl(station),
    );
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {
    final de = _locale()?.languageCode == 'de';
    final content = FavoritesExport.build(
      favorites,
      format,
      labels: de ? FavoritesExportLabels.de : FavoritesExportLabels.en,
    );
    if (format == ExportFormat.text) {
      await SharePlus.instance.share(ShareParams(text: content));
      return;
    }
    final name = de ? 'linefm-favoriten.csv' : 'linefm-favorites.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(
            utf8.encode(content),
            mimeType: 'text/csv',
            name: name,
          ),
        ],
        fileNameOverrides: <String>[name],
      ),
    );
  }

  @override
  Future<void> openUrl(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) throw StateError('Link konnte nicht geoeffnet werden: $uri');
  }
}
