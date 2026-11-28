import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/features/legal/external_link.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Bundled originals of the RadioGruppe logo, exactly as RadioGruppe
/// publishes them (1400x400 PNG, not re-encoded). The dark-text variant is for
/// light surfaces, the light-text variant for dark surfaces.
const String radioGruppeLogoAssetLight =
    'assets/brand/radiogruppe/rgd-logo.png';
const String radioGruppeLogoAssetDark =
    'assets/brand/radiogruppe/rgd-logo-dark.png';

const String radioGruppeUrl = 'https://radiogruppe.de';

/// "Ein Angebot von" + RadioGruppe-Logo mit Link auf radiogruppe.de.
///
/// Shows the original logo bundled with the app, picked per theme.
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
                  child: const _Logo(),
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
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    // The logo is decoration: the surrounding link carries focus and label.
    return ExcludeFocus(
      child: Image.asset(
        light ? radioGruppeLogoAssetLight : radioGruppeLogoAssetDark,
        width: 190,
        height: 48,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        excludeFromSemantics: true,
      ),
    );
  }
}
