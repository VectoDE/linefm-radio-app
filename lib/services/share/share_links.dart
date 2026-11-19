import 'package:linefm_radio/domain/station.dart';

/// Links auf Sender: Web-Adresse zum Teilen und App-Link (Deep Link).
class ShareLinks {
  const ShareLinks._();

  /// `https://app.linefm.de/?station={slug}` (Basis ohne Schraegstrich am Ende).
  static String stationUrl(String webBaseUrl, Station station) {
    final base = webBaseUrl.endsWith('/')
        ? webBaseUrl.substring(0, webBaseUrl.length - 1)
        : webBaseUrl;
    return '$base/?station=${station.slug}';
  }

  /// `linefm://play?station={slug}` (oeffnet die installierte App).
  static Uri stationAppLink(Station station) => Uri(
    scheme: 'linefm',
    host: 'play',
    queryParameters: <String, String>{'station': station.slug},
  );
}
