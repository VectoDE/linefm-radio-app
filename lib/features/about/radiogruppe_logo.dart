import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/features/legal/external_link.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Adresse des RadioGruppe-Logos. Wird wie in der Web-App zur Laufzeit von
/// radiogruppe.de geladen und nicht gebuendelt (Entscheidung 47).
const String radioGruppeLogoUrl =
    'https://radiogruppe.de/assets/img/rgd-logo-dark.png';

const String radioGruppeUrl = 'https://radiogruppe.de';

/// "Ein Angebot von" + RadioGruppe-Logo mit Link auf radiogruppe.de.
///
/// Das Logo ist die helle Fassung fuer dunkle Flaechen. Im Hellmodus liegt es
/// deshalb auf einer dunklen Kachel. Schlaegt das Laden fehl (offline,
/// blockiert), erscheint der Name als Text.
class RadioGruppeCredit extends ConsumerWidget {
  const RadioGruppeCredit({super.key, this.center = false});

  /// Mittig statt linksbuendig (Ueber-Bereich auf breiten Flaechen).
  final bool center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.creditsOfferedBy,
          style: LinefmText.listTitle.copyWith(
            color: c.muted,
            fontSize: LinefmType.caption,
          ),
        ),
        const SizedBox(height: LinefmSpace.md),
        SemanticFocus(
          builder: (_, focused, onFocus, child) => Semantics(
            container: true,
            link: true,
            linkUrl: Uri.parse(radioGruppeUrl),
            label: l10n.radioGruppeOpen,
            excludeSemantics: true,
            onTap: () => openExternalUrl(context, ref, radioGruppeUrl),
            focusable: true,
            focused: focused,
            onFocus: onFocus,
            child: child,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => openExternalUrl(context, ref, radioGruppeUrl),
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: LinefmMetrics.minTarget,
                ),
                child: Align(
                  alignment: center ? Alignment.center : Alignment.centerLeft,
                  widthFactor: 1,
                  child: _Logo(name: l10n.radioGruppeName),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    final light = Theme.of(context).brightness == Brightness.light;
    final fallback = Text(
      name,
      style: LinefmText.settingTitle.copyWith(
        color: light ? LinefmPalette.paper : c.text,
        fontSize: LinefmType.bodyLarge,
      ),
    );
    // Im Web kann das Bild als <img>-Plattformansicht landen, und die hat
    // einen eigenen Fokusknoten: ein zweiter, unsichtbarer Tab-Stopp im Link.
    // Das Logo ist Dekoration, der Link drumherum traegt Fokus und Label.
    final image = ExcludeFocus(
      child: Image.network(
        radioGruppeLogoUrl,
        width: 190,
        height: 48,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        excludeFromSemantics: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const SizedBox(width: 190, height: 48),
        errorBuilder: (context, error, stack) => fallback,
      ),
    );
    if (!light) return image;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LinefmPalette.ink,
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LinefmSpace.md,
          vertical: LinefmSpace.sm,
        ),
        child: image,
      ),
    );
  }
}
