import 'dart:ui' show Locale;

import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/l10n/system_l10n.dart';

/// Texte fuer Tray-Menue und Mini-Fenster. Das Tray-Menue entsteht vor dem
/// ersten Widget, deshalb ohne BuildContext: Sprache wie in der App (Deutsch
/// bleibt Deutsch, alles andere Englisch).
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
      DesktopStrings.forLocale(effectiveSystemLocale());

  final AppLocalizations l10n;
  final bool german;

  String get alwaysOnTop => l10n.trayAlwaysOnTop;
}
