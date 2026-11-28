import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/features/consent/consent_dialog_frame.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/browser_cast_bridge.dart';
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
    return ConsentDialogFrame(
      title: l10n.castConsentTitle,
      text: castConsentText(l10n),
    );
  }
}
