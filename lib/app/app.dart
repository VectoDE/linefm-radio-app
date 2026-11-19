import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/document_lang.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/app/shell.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/web_routes.dart';
import 'package:linefm_radio/services/share/share_feedback.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
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

/// Wurzel der App: Theme hell/dunkel/System aus den Einstellungen, Sprache
/// (System bzw. `?lang=` im Web), Ladebildschirm und Einwilligungsdialog um
/// die Shell.
class LinefmApp extends ConsumerWidget {
  const LinefmApp({super.key, this.launchUri});

  /// Start-Adresse (Web: `Uri.base`), fuer `?lang=`.
  final Uri? launchUri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final uri = launchUri ?? (kIsWeb ? Uri.base : null);
    final forced = uri == null ? null : localeFromQuery(uri);
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
      builder: (context, child) => ShareFeedbackListener(
        child: LoaderGate(child: child ?? const SizedBox.shrink()),
      ),
      home: const WebRouteSync(child: TelemetryConsentGate(child: AppShell())),
    );
  }
}
