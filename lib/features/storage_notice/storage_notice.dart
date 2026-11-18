import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Speicher-Hinweis wie in der Web-App, auf allen Plattformen (Entscheidung
/// 39): "Wir speichern kleine Daten in diesem Browser / auf diesem Geraet ...".
///
/// Erscheint, solange die Speicher-Bestaetigung fehlt. "Verstanden" setzt sie,
/// "Speicher loeschen" in den Einstellungen setzt sie zurueck. Die Shell
/// platziert das Widget am unteren Rand ueber der Navigation (Web: 69 dp +
/// 12 dp Abstand, max. 760 dp breit).
class StorageNotice extends ConsumerWidget {
  const StorageNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmed = ref.watch(storageConsentProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : LinefmMetrics.medium,
      switchInCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: confirmed
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
    final platform = ref.watch(platformInfoProvider);
    final text = platform.isWeb
        ? l10n.storageNoticeBodyWeb
        : l10n.storageNoticeBodyDevice;

    final privacy = TextButton(
      onPressed: () => openLegal(context, LegalKind.privacy),
      style: TextButton.styleFrom(foregroundColor: c.text),
      child: Text(l10n.storageNoticePrivacy),
    );
    final dismiss = OutlinedButton(
      onPressed: () =>
          ref.read(storageConsentProvider.notifier).set(value: true),
      child: Text(l10n.storageNoticeDismiss),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.navBg,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x47000000),
                  blurRadius: 26,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: LayoutBuilder(
                builder: (context, box) {
                  final copy = Text(
                    text,
                    style: LinefmText.notice.copyWith(color: c.muted),
                  );
                  if (box.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        copy,
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            privacy,
                            const SizedBox(width: 8),
                            dismiss,
                          ],
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
      ),
    );
  }
}
