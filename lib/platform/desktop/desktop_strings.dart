import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:linefm_radio/l10n/gen/app_localizations.dart';

/// Texte fuer Tray-Menue und Mini-Fenster. Das Tray-Menue entsteht vor dem
/// ersten Widget, deshalb ohne BuildContext: Sprache wie in der App (Deutsch
/// bleibt Deutsch, alles andere Englisch).
///
/// Die vorhandenen Schluessel (trayPlay, trayStop, trayStations, ...) kommen
/// aus den ARB-Dateien. Nur "Immer im Vordergrund" hat dort noch keinen
/// Schluessel; es steht hier, bis P28 es in die ARB-Dateien uebernimmt.
class DesktopStrings {
  DesktopStrings._(this.l10n, {required this.german});

  factory DesktopStrings.forLocale(Locale locale) {
    final german = locale.languageCode == 'de';
    return DesktopStrings._(
      lookupAppLocalizations(Locale(german ? 'de' : 'en')),
      german: german,
    );
  }

  factory DesktopStrings.system() =>
      DesktopStrings.forLocale(PlatformDispatcher.instance.locale);

  final AppLocalizations l10n;
  final bool german;

  String get alwaysOnTop => german ? 'Immer im Vordergrund' : 'Always on top';
}
