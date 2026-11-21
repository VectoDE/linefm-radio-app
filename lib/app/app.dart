import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/document_lang.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/app/stations_provider.dart';
import 'package:linefm_radio/app/shell.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/alarm/alarm_bootstrap.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/l10n/system_l10n.dart';
import 'package:linefm_radio/platform/desktop/desktop_host.dart';
import 'package:linefm_radio/platform/web_routes.dart';
import 'package:linefm_radio/services/share/share_feedback.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/features/stations/station_unavailable_notice.dart';
import 'package:material_ui/material_ui.dart';

/// Sprache aus `?lang=de|en` (Web, hreflang-Varianten), sonst `null`
/// (Systemsprache).
Locale? localeFromQuery(Uri uri) => switch (uri.queryParameters['lang']) {
  'de' => const Locale('de'),
  'en' => const Locale('en'),
  _ => null,
};

/// Deutsch bleibt Deutsch, alles andere faellt auf Englisch zurueck.
Locale resolveAppLocale(Locale? locale) =>
    locale?.languageCode == 'de' ? const Locale('de') : const Locale('en');

/// Sprache der Oberflaeche, Rangfolge (hoechste zuerst):
///
/// 1. Wahl in den Einstellungen waehrend dieser Sitzung ([urlLocale] ist dann
///    schon verworfen),
/// 2. `?lang=de|en` der Start-Adresse (Web, hreflang-Varianten),
/// 3. gespeicherte Wahl in den Einstellungen,
/// 4. `null`: Systemsprache, Rueckfall Englisch ([resolveAppLocale]).
Locale? chooseLocale({Locale? urlLocale, required AppLanguage language}) {
  if (urlLocale != null) return urlLocale;
  final code = language.code;
  return code == null ? null : Locale(code);
}

/// Wurzel der App: Theme hell/dunkel/System aus den Einstellungen, Sprache
/// (Einstellung, `?lang=` im Web, sonst System; siehe [chooseLocale]),
/// Ladebildschirm und Einwilligungsdialog um die Shell.
class LinefmApp extends ConsumerStatefulWidget {
  const LinefmApp({super.key, this.launchUri});

  /// Start-Adresse (Web: `Uri.base`), fuer `?lang=`.
  final Uri? launchUri;

  @override
  ConsumerState<LinefmApp> createState() => _LinefmAppState();
}

class _LinefmAppState extends ConsumerState<LinefmApp> {
  /// `?lang=` der Start-Adresse; faellt weg, sobald der Nutzer in den
  /// Einstellungen eine Sprache waehlt, damit die Wahl sofort wirkt.
  Locale? _urlLocale;

  @override
  void initState() {
    super.initState();
    final uri = widget.launchUri ?? (kIsWeb ? Uri.base : null);
    _urlLocale = uri == null ? null : localeFromQuery(uri);
    appLanguageOverride = ref.read(settingsProvider).language.code;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final language = ref.watch(settingsProvider.select((s) => s.language));
    ref.listen(settingsProvider.select((s) => s.language), (previous, next) {
      appLanguageOverride = next.code;
      if (previous == null || previous == next) return;
      if (_urlLocale != null) setState(() => _urlLocale = null);
      // Benachrichtigungstexte geplanter Wecker entstehen beim Planen: neu
      // planen, damit sie die neue Sprache tragen.
      unawaited(
        ref
            .read(alarmCoordinatorProvider)
            .rescheduleAll(ref.read(alarmProvider)),
      );
    });
    // Nachgeladene Senderliste (Issue #91): Wecker neu planen, damit
    // Mitteilungstext und Link einen entfernten Sender durch den Ersatz
    // ersetzen, den der Wecker beim Klingeln spielt.
    ref.listen(stationsCatalogProvider, (previous, next) {
      if (previous == null) return;
      unawaited(
        ref
            .read(alarmCoordinatorProvider)
            .rescheduleAll(ref.read(alarmProvider)),
      );
    });
    final forced = chooseLocale(urlLocale: _urlLocale, language: language);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildLinefmTheme(Brightness.light),
      darkTheme: buildLinefmTheme(Brightness.dark),
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      locale: forced,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        final resolved = resolveAppLocale(locale);
        setDocumentLang(resolved.languageCode);
        return resolved;
      },
      builder: (context, child) => DesktopHost(
        child: AlarmBootstrap(
          child: ShareFeedbackListener(
            child: StationUnavailableNotice(
              child: LoaderGate(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
      home: const WebRouteSync(child: TelemetryConsentGate(child: AppShell())),
    );
  }
}
