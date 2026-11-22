import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/analytics/google_analytics.dart';
import 'package:linefm_radio/services/analytics/google_analytics_bridge.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Bruecke zu web/analytics.js; Tests ueberschreiben sie.
final googleAnalyticsBridgeProvider = Provider<GoogleAnalyticsBridge>(
  (ref) => createGoogleAnalyticsBridge(),
);

/// Ist die Reichweitenmessung mit Google aktiv (Web und gueltige ID)? Tests
/// ueberschreiben den Provider, weil `kIsWeb` dort immer false ist.
final googleAnalyticsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(appConfigProvider).googleAnalyticsConfigured,
);

/// Einwilligung "Reichweitenmessung mit Google" (nur Web, P31), getrennt von
/// "Statistik und Fehlerberichte". `null` = nicht konfiguriert oder noch nicht
/// entschieden. Standard ist abgelehnt: ohne Zustimmung laedt nichts von Google.
class GoogleConsentNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    if (!ref.watch(googleAnalyticsEnabledProvider)) return null;
    final config = ref.read(appConfigProvider);
    final bridge = ref.read(googleAnalyticsBridgeProvider)
      ..configure(gtmId: config.validGtmId, ga4Id: config.validGa4Id);
    return bridge.decision;
  }

  void set({required bool value}) {
    if (!ref.read(googleAnalyticsEnabledProvider)) return;
    final bridge = ref.read(googleAnalyticsBridgeProvider);
    value ? bridge.grant() : bridge.deny();
    state = value;
  }

  /// "Speicher loeschen": Entscheidung vergessen, Cookies entfernen.
  void reset() {
    ref.read(googleAnalyticsBridgeProvider).reset();
    state = null;
  }
}

final googleConsentProvider = NotifierProvider<GoogleConsentNotifier, bool?>(
  GoogleConsentNotifier.new,
);

/// Soll der Google-Dialog erscheinen?
bool shouldAskGoogleConsent({
  required bool configured,
  required bool? decision,
}) => configured && decision == null;

/// Einwilligungstext: nennt Google als Empfaenger, die USA-Uebermittlung (DPF)
/// und den Zweck. Absaetze durch Leerzeile getrennt.
String googleConsentText(AppLocalizations l10n) => <String>[
  l10n.googleConsentIntro,
  l10n.googleConsentRecipient,
  l10n.googleConsentTransfer,
  l10n.googleConsentOutro,
].join('\n\n');

/// Ergebnis: `true` = erlaubt, `false` = abgelehnt, `null` = ohne Wahl.
Future<bool?> showGoogleConsentDialog(BuildContext context) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const GoogleConsentDialog(),
);

/// Gleichwertige Knoepfe, keine Vorauswahl (wie der Telemetrie-Dialog).
class GoogleConsentDialog extends StatelessWidget {
  const GoogleConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return NamedDialog(
      label: l10n.googleConsentTitle,
      child: AlertDialog(
        semanticLabel: l10n.googleConsentTitle,
        scrollable: true,
        title: Semantics(header: true, child: Text(l10n.googleConsentTitle)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                googleConsentText(l10n),
                style: LinefmText.listTitle.copyWith(
                  color: c.text,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: LinefmSpace.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => openLegal(context, LegalKind.privacy),
                  child: Text(l10n.consentPrivacyLink),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          LinefmSpace.xl,
          0,
          LinefmSpace.xl,
          LinefmSpace.gutter,
        ),
        actions: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.consentDecline),
                ),
              ),
              const SizedBox(width: LinefmSpace.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.consentAllow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
