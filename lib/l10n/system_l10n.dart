import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:linefm_radio/l10n/gen/app_localizations.dart';

/// Texte aus den ARB-Dateien ohne BuildContext (Benachrichtigungen des
/// Weckers, Kanalname der Wiedergabe-Benachrichtigung). Deutsch, sonst
/// Englisch, wie [resolveAppLocale] in der App.
AppLocalizations systemLocalizations([String? languageCode]) {
  final code = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code == 'de' ? 'de' : 'en'));
}
