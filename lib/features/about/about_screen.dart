import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/about/radiogruppe_logo.dart';
import 'package:linefm_radio/features/legal/external_link.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/loader/made_by_credit.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Build-Nummer, von der CI per `--dart-define=APP_BUILD=<n>` gesetzt.
const String appBuildNumber = String.fromEnvironment(
  'APP_BUILD',
  defaultValue: '1',
);

const String developerUrl = 'https://github.com/VectoDE';
const String websiteUrl = 'https://linefm.de';

/// Oeffnet den Ueber-Bereich als eigenen Screen.
Future<void> openAbout(BuildContext context) => Navigator.of(context)
    .push<void>(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));

/// Ueber-Bereich (Spec 4.7): alle drei Credits im Wortlaut, Version und
/// Build, Rechtstexte, Open-Source-Lizenzen und optional die Vertrauens-
/// Badges (Gridinsoft, Trustpilot), sofern ihre URLs konfiguriert sind.
///
/// Credits (Entscheidungen 30 und 46): "Made by .jaybelife with ♥", "Ein
/// Angebot von" + RadioGruppe, "Entwickelt von Tim Hauke (VectoDE) fuer
/// jaybelife" mit Link auf GitHub und "LINEFM und die App gehoeren jaybelife."
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final config = ref.watch(appConfigProvider);
    final width = MediaQuery.sizeOf(context).width;
    final side = width > 760 ? (width - 720) / 2 : 20.0;

    final trust = <({String label, String url})>[
      if (config.trustGridinsoftUrl.isNotEmpty)
        (label: l10n.trustGridinsoft, url: config.trustGridinsoftUrl),
      if (config.trustTrustpilotUrl.isNotEmpty)
        (label: l10n.trustTrustpilot, url: config.trustTrustpilotUrl),
    ];

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(side, 20, side, 48),
        children: <Widget>[
          SectionHeading(
            l10n.aboutTitle,
            style: TextStyle(fontSize: width < 600 ? 18 : 25),
          ),
          Text(
            l10n.aboutVersion(appBuildNumber, config.appVersion),
            style: LinefmText.listTitle.copyWith(color: c.muted),
          ),
          const SizedBox(height: 28),
          const _MadeBy(),
          const SizedBox(height: 28),
          const RadioGruppeCredit(),
          const SizedBox(height: 28),
          const _Developer(),
          const SizedBox(height: 8),
          Divider(color: c.line, height: 48),
          _LinkRow(
            label: l10n.footerImprint,
            linkUrl: LegalKind.imprint.webUri,
            onTap: () => openLegal(context, LegalKind.imprint),
          ),
          _LinkRow(
            label: l10n.footerPrivacy,
            linkUrl: LegalKind.privacy.webUri,
            onTap: () => openLegal(context, LegalKind.privacy),
          ),
          _LinkRow(
            label: l10n.aboutLicenses,
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: l10n.aboutVersion(
                appBuildNumber,
                config.appVersion,
              ),
            ),
          ),
          _LinkRow(
            label: l10n.footerWebsite,
            external: true,
            linkUrl: Uri.parse(websiteUrl),
            onTap: () => openExternalUrl(context, ref, websiteUrl),
          ),
          if (trust.isNotEmpty) ...<Widget>[
            Divider(color: c.line, height: 48),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final t in trust)
                  OutlinedButton.icon(
                    onPressed: () => openExternalUrl(context, ref, t.url),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(t.label),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Made by .jaybelife with ♥" wie im Ladebildschirm.
class _MadeBy extends StatelessWidget {
  const _MadeBy();

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return MadeByCredit(
      style: LinefmText.listTitle.copyWith(color: c.muted, fontSize: 15),
      authorColor: c.text,
      heartColor: c.heart,
    );
  }
}

/// Entwickler-Nennung mit Link und Eigentumshinweis.
class _Developer extends ConsumerWidget {
  const _Developer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SemanticFocus(
          builder: (_, focused, onFocus, child) => Semantics(
            link: true,
            linkUrl: Uri.parse(developerUrl),
            label: '${l10n.creditsDevelopedBy}. ${l10n.creditsDeveloperOpen}',
            excludeSemantics: true,
            onTap: () => openExternalUrl(context, ref, developerUrl),
            focusable: true,
            focused: focused,
            onFocus: onFocus,
            child: child,
          ),
          child: InkWell(
            onTap: () => openExternalUrl(context, ref, developerUrl),
            borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: LinefmMetrics.minTarget,
              ),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      l10n.creditsDevelopedBy,
                      style: LinefmText.listTitle.copyWith(
                        color: c.accent,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                        decorationColor: c.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new, size: 16, color: c.muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.creditsOwnership,
          style: LinefmText.listTitle.copyWith(color: c.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.onTap,
    this.external = false,
    this.linkUrl,
  });

  final String label;
  final VoidCallback onTap;
  final bool external;

  /// Ziel fuer die Link-Rolle (im Web ein echtes `href`, A11Y-03). Ohne
  /// Ziel ist die Zeile ein Knopf (z. B. Lizenzen).
  final Uri? linkUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        link: linkUrl != null,
        linkUrl: linkUrl,
        button: linkUrl == null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: LinefmMetrics.minTarget),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: LinefmText.listTitle.copyWith(color: c.text),
                ),
              ),
              Icon(
                external ? Icons.open_in_new : Icons.chevron_right,
                size: 18,
                color: c.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
