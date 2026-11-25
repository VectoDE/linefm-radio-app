import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/browser_cast_bridge.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:material_ui/material_ui.dart';

/// Bridge to web/cast.js; tests override it.
final browserCastBridgeProvider = Provider<BrowserCastBridge>(
  (ref) => createBrowserCastBridge(),
);

/// Consent "Google Cast" in the web version. `null` = browser cannot cast or
/// not decided yet. Default is declined: without consent nothing loads from
/// Google. Separate from the analytics consent.
class CastConsentNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    final bridge = ref.watch(browserCastBridgeProvider);
    return bridge.supported ? bridge.decision : null;
  }

  void set({required bool value}) {
    final bridge = ref.read(browserCastBridgeProvider);
    if (!bridge.supported) return;
    value ? bridge.grant() : bridge.deny();
    state = value;
  }

  /// "Clear storage": forget the decision.
  void reset() {
    ref.read(browserCastBridgeProvider).reset();
    state = null;
  }
}

final castConsentProvider = NotifierProvider<CastConsentNotifier, bool?>(
  CastConsentNotifier.new,
);

/// Consent text: names Google as recipient, the US transfer (DPF) and the
/// purpose. Paragraphs separated by a blank line.
String castConsentText(AppLocalizations l10n) => <String>[
  l10n.castConsentIntro,
  l10n.castConsentRecipient,
  l10n.castConsentTransfer,
  l10n.castConsentOutro,
].join('\n\n');

/// `true` = allowed, `false` = declined, `null` = closed without a choice.
Future<bool?> showCastConsentDialog(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (_) => const CastConsentDialog(),
);

/// Equal buttons, nothing preselected (like the other consent dialogs).
class CastConsentDialog extends StatelessWidget {
  const CastConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return NamedDialog(
      label: l10n.castConsentTitle,
      child: AlertDialog(
        semanticLabel: l10n.castConsentTitle,
        scrollable: true,
        title: Semantics(header: true, child: Text(l10n.castConsentTitle)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                castConsentText(l10n),
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
