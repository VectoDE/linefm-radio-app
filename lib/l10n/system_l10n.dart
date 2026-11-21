import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:linefm_radio/l10n/gen/app_localizations.dart';

String? _languageOverride;

/// Sprachcode der in der App gewaehlten Sprache (`de` oder `en`), `null` =
/// Systemsprache. Gilt fuer alles ausserhalb des Widget-Baums (Benachrichtigung
/// des Weckers, Kanalname, Tray-Menue, Auto-Menue, Widget, Export), das keinen
/// BuildContext hat. Die App setzt ihn beim Start und bei jedem Wechsel in den
/// Einstellungen.
set appLanguageOverride(String? languageCode) => _languageOverride =
    languageCode == 'de' || languageCode == 'en' ? languageCode : null;

String? get appLanguageOverride => _languageOverride;

/// Sprache fuer Texte ohne BuildContext: gewaehlte App-Sprache, sonst die
/// Systemsprache des Geraets.
Locale effectiveSystemLocale() => _languageOverride == null
    ? PlatformDispatcher.instance.locale
    : Locale(_languageOverride!);

/// Texte aus den ARB-Dateien ohne BuildContext (Benachrichtigungen des
/// Weckers, Kanalname der Wiedergabe-Benachrichtigung). Deutsch, sonst
/// Englisch, wie [resolveAppLocale] in der App.
AppLocalizations systemLocalizations([String? languageCode]) {
  final code = languageCode ?? effectiveSystemLocale().languageCode;
  return lookupAppLocalizations(Locale(code == 'de' ? 'de' : 'en'));
}
