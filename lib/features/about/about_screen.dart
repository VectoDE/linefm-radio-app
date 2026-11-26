import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
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

/// Versionszeile: Release-Version mit Build, lokal "Entwicklungsversion"
/// mit Commit-Kurz-ID.
String versionText(AppLocalizations l10n, AppConfig config) {
  if (config.isDevBuild) {
    final commit = config.appCommit.isEmpty ? '?' : config.appCommit;
    return l10n.aboutDevVersion(commit);
  }
  return l10n.aboutVersion(appBuildNumber, config.appVersion);
}

const String developerUrl = 'https://github.com/VectoDE';
const String websiteUrl = 'https://linefm.de';

/// Oeffnet den Ueber-Bereich als eigenen Screen.
Future<void> openAbout(BuildContext context) => Navigator.of(context)
    .push<void>(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));

/// Ueber-Bereich (Spec 4.7): alle drei Credits im Wortlaut, Version und
/// Build, Rechtstexte, Open-Source-Lizenzen und optional die Vertrauens-
/// Badges (Gridinsoft, Trustpilot), sofern ihre URLs konfiguriert sind.
///
/// Credits (Entscheidungen 30 und 46): "Made by Tim Hauke with ♥", "Ein
/// Angebot von" + RadioGruppe, "Entwickelt von Tim Hauke (VectoDE) fuer
/// LineFM Studios" mit Link auf GitHub und "LINEFM und die App gehoeren
/// LineFM Studios."
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

    // Eigene Seite: als Hauptinhalt kennzeichnen (Landmarke).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.main,
      child: Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: EdgeInsets.fromLTRB(side, LinefmSpace.gutter, side, 48),
          children: <Widget>[
            SectionHeading(
              l10n.aboutTitle,
              style: TextStyle(
                fontSize: width < 600 ? LinefmType.title : LinefmType.heading,
              ),
            ),
            Text(
              versionText(l10n, config),
              style: LinefmText.listTitle.copyWith(color: c.muted),
            ),
            const SizedBox(height: 28),
            const _MadeBy(),
            const SizedBox(height: 28),
            const RadioGruppeCredit(),
            const SizedBox(height: 28),
            const _Developer(),
            const SizedBox(height: LinefmSpace.sm),
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
                applicationVersion: versionText(l10n, config),
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
                spacing: LinefmSpace.md,
                runSpacing: LinefmSpace.md,
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
      ),
    );
  }
}

/// "Made by Tim Hauke with ♥" wie im Ladebildschirm, der Name ist ein Link.
class _MadeBy extends ConsumerWidget {
  const _MadeBy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.linefm;
    return MadeByCredit(
      onAuthorTap: () => openExternalUrl(context, ref, developerUrl),
      style: LinefmText.listTitle.copyWith(
        color: c.muted,
        fontSize: LinefmType.bodyLarge,
      ),
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
            container: true,
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
                        fontSize: LinefmType.bodyLarge,
                        decoration: TextDecoration.underline,
                        decorationColor: c.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: LinefmSpace.sm),
                  Icon(Icons.open_in_new, size: 16, color: c.muted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: LinefmSpace.xs),
        Text(
          l10n.creditsOwnership,
          style: LinefmText.listTitle.copyWith(
            color: c.muted,
            fontSize: LinefmType.caption,
          ),
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

  /// Ziel fuer die Link-Rolle (im Web ein echtes `href`). Ohne
  /// Ziel ist die Zeile ein Knopf (z. B. Lizenzen).
  final Uri? linkUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
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
