import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Speicher-Hinweis als Banner, nur im Browser (Entscheidung vom 21.11.2026
/// ersetzt Entscheidung 39). In der App und auf dem Desktop zeigt stattdessen
/// ein Popup den Hinweis (`StorageNoticeDialog`), das Banner bleibt dort leer.
/// Sachlicher Wortlaut (L13/C16): was gespeichert wird und wozu.
///
/// Erscheint im Browser, solange die Speicher-Bestaetigung fehlt. "Verstanden"
/// setzt sie, "Speicher loeschen" in den Einstellungen setzt sie zurueck. Die
/// Shell platziert das Widget am unteren Rand ueber der Navigation (69 dp +
/// 12 dp Abstand, max. 760 dp breit).
class StorageNotice extends ConsumerWidget {
  const StorageNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmed = ref.watch(storageConsentProvider);
    final isWeb = ref.watch(platformInfoProvider).isWeb;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : LinefmMetrics.medium,
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: confirmed || !isWeb
          ? const SizedBox.shrink(key: ValueKey<String>('storage-notice-off'))
          : const _NoticeCard(key: ValueKey<String>('storage-notice-on')),
    );
  }
}

class _NoticeCard extends ConsumerWidget {
  const _NoticeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final text = l10n.storageNoticeBodyWeb;

    const compactButton = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(0, LinefmMetrics.minTarget),
      ),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    final privacy = TextButton(
      onPressed: () => openLegal(context, LegalKind.privacy),
      style: TextButton.styleFrom(foregroundColor: c.text).merge(compactButton),
      child: Text(l10n.storageNoticePrivacy),
    );
    final dismiss = OutlinedButton(
      onPressed: () =>
          ref.read(storageConsentProvider.notifier).set(value: true),
      style: compactButton,
      child: Text(l10n.storageNoticeDismiss),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          // Deckend: Karten und Ticker duerfen nicht durchscheinen (D2).
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: c.noticeShadow,
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: LayoutBuilder(
              builder: (context, box) {
                // Live-Region nur um den Text, nicht um die Knoepfe.
                final copy = Semantics(
                  container: true,
                  liveRegion: true,
                  child: Text(
                    text,
                    style: LinefmText.notice.copyWith(color: c.text),
                  ),
                );
                if (box.maxWidth < 520) {
                  // Schmal: Text links, die beiden Knoepfe rechts
                  // untereinander. Das spart gegenueber Text-ueber-Knoepfen
                  // eine ganze Zeile (U1, A11Y-13).
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: copy,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[dismiss, privacy],
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: copy),
                    const SizedBox(width: 16),
                    privacy,
                    const SizedBox(width: 8),
                    dismiss,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
