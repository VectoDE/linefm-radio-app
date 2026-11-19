import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Oeffnet eine URL ausserhalb der App. Tests ueberschreiben den Provider.
typedef UrlOpener = Future<bool> Function(Uri uri);

final urlOpenerProvider = Provider<UrlOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Oeffnet [url] und zeigt bei Fehlschlag den Hinweis "Der Link konnte nicht
/// geoeffnet werden." als SnackBar.
Future<void> openExternalUrl(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = AppLocalizations.of(context).linkOpenError;
  var ok = false;
  try {
    ok = await ref.read(urlOpenerProvider)(Uri.parse(url));
  } on Object {
    ok = false;
  }
  if (!ok) {
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
