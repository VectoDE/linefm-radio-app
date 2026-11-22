import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/consent/google_consent.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/storage_notice/storage_notice_dialog.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Soll der Einwilligungsdialog erscheinen? Nur wenn Telemetrie konfiguriert
/// ist (`telemetry.consentRequired`) und noch nichts entschieden wurde.
bool shouldAskTelemetryConsent({
  required bool consentRequired,
  required bool? decision,
}) => consentRequired && decision == null;

/// Einwilligungstext aus den aktiven Anbietern (R3-P05): nennt nur die
/// Dienste, die in [config] wirklich konfiguriert sind; bei Firebase zusaetzlich
/// Google als Empfaenger und die USA-Uebermittlung (EU-US Data Privacy
/// Framework). Absaetze durch Leerzeile getrennt.
String telemetryConsentText(AppLocalizations l10n, AppConfig config) {
  final services = <String>[
    if (config.umamiConfigured) l10n.consentServiceUmami,
    if (config.sentryConfigured) l10n.consentServiceSentry,
    if (config.firebaseConfigured) l10n.consentServiceFirebase,
  ];
  return <String>[
    l10n.consentIntro,
    if (services.isNotEmpty) l10n.consentRecipients(services.join(', ')),
    if (config.firebaseConfigured) l10n.consentFirebaseTransfer,
    l10n.consentOutro,
  ].join('\n\n');
}

/// Rahmen um die App: steuert die Dialoge beim Start der Reihe nach, nie zwei
/// zugleich. Sobald der erste Frame steht (der Ladebildschirm liegt noch
/// darueber und blendet sich danach aus):
///
/// 1. App und Desktop: Speicher-Hinweis als Popup ([showStorageNoticeDialog]),
///    bis er bestaetigt ist. Im Browser entfaellt der Schritt, dort steht der
///    Banner der Shell.
/// 2. Einwilligungsdialog "Statistik und Fehlerberichte".
/// 3. Getrennt davon "Reichweitenmessung mit Google" (nur Web mit
///    GTM_ID/GA4_MEASUREMENT_ID).
///
/// Setzt "Speicher loeschen" die Bestaetigung zurueck, erscheint das Popup
/// (App und Desktop) sofort wieder.
///
/// Ohne konfigurierte Telemetrie passiert nichts (kein Dialog, kein Aufruf).
/// Schliesst der Nutzer den Dialog ohne Wahl (Zurueck/Esc), gilt das als
/// "nicht entschieden": es wird nichts gesendet, beim naechsten Start wird
/// erneut gefragt. Die Shell setzt das Widget als Eltern von [child] ein.
class TelemetryConsentGate extends ConsumerStatefulWidget {
  const TelemetryConsentGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TelemetryConsentGate> createState() =>
      _TelemetryConsentGateState();
}

class _TelemetryConsentGateState extends ConsumerState<TelemetryConsentGate> {
  bool _asked = false;
  bool _noticeOpen = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(storageConsentProvider, (previous, next) {
      // Nach "Speicher loeschen" den Hinweis erneut verlangen.
      if (_asked && !next) unawaited(_askStorageNotice());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAsk());
  }

  /// Speicher-Hinweis als Popup (nur App und Desktop). Schliesst nur mit
  /// "Verstanden"; erst dann wird die Bestaetigung gemerkt.
  Future<void> _askStorageNotice() async {
    if (!mounted || _noticeOpen) return;
    final show = shouldShowStorageNoticeDialog(
      platform: ref.read(platformInfoProvider),
      confirmed: ref.read(storageConsentProvider),
    );
    if (!show) return;
    _noticeOpen = true;
    try {
      final confirmed = await showStorageNoticeDialog(context);
      if (!mounted || confirmed != true) return;
      await ref.read(storageConsentProvider.notifier).set(value: true);
    } finally {
      _noticeOpen = false;
    }
  }

  Future<void> _maybeAsk() async {
    if (!mounted || _asked) return;
    _asked = true;
    await _askStorageNotice();
    if (!mounted) return;
    final ask = shouldAskTelemetryConsent(
      consentRequired: ref.read(telemetryProvider).consentRequired,
      decision: ref.read(telemetryConsentProvider),
    );
    if (ask) {
      final answer = await showTelemetryConsentDialog(context);
      if (!mounted) return;
      if (answer != null) {
        await ref.read(telemetryConsentProvider.notifier).set(value: answer);
      }
    }
    // Danach, getrennt: Reichweitenmessung mit Google (nur Web mit IDs).
    if (!mounted) return;
    final askGoogle = shouldAskGoogleConsent(
      configured: ref.read(googleAnalyticsEnabledProvider),
      decision: ref.read(googleConsentProvider),
    );
    if (!askGoogle) return;
    final google = await showGoogleConsentDialog(context);
    if (google == null || !mounted) return;
    ref.read(googleConsentProvider.notifier).set(value: google);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Zeigt den Dialog. Ergebnis: `true` = erlaubt, `false` = abgelehnt,
/// `null` = ohne Wahl geschlossen.
///
/// Beide Antworten sind gleichwertig gestaltet (gleicher Knopftyp, gleiche
/// Groesse, keine Vorauswahl, kein Hervorheben).
Future<bool?> showTelemetryConsentDialog(BuildContext context) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TelemetryConsentDialog(),
    );

class TelemetryConsentDialog extends ConsumerWidget {
  const TelemetryConsentDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final decline = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: Text(l10n.consentDecline),
    );
    final allow = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(true),
      child: Text(l10n.consentAllow),
    );
    return NamedDialog(
      label: l10n.consentTitle,
      child: AlertDialog(
        semanticLabel: l10n.consentTitle,
        scrollable: true,
        title: Semantics(header: true, child: Text(l10n.consentTitle)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                telemetryConsentText(l10n, ref.watch(appConfigProvider)),
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
              Expanded(child: decline),
              const SizedBox(width: LinefmSpace.md),
              Expanded(child: allow),
            ],
          ),
        ],
      ),
    );
  }
}
