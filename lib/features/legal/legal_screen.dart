import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/legal/external_link.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:material_ui/material_ui.dart';

/// Oeffnet Impressum oder Datenschutz als eigenen Screen (offline aus den
/// Assets).
Future<void> openLegal(BuildContext context, LegalKind kind) => Navigator.of(
  context,
).push<void>(MaterialPageRoute<void>(builder: (_) => LegalScreen(kind: kind)));

/// Zeigt Impressum oder Datenschutz aus `assets/legal/<sprache>/*.json`.
///
/// Bloecke mit `requires` erscheinen nur, wenn der Anbieter in der
/// Build-Konfiguration aktiv ist. Offene Platzhalter (`{{BETREIBER_NAME}}`)
/// werden farbig hervorgehoben, bis die Betreiberdaten eingesetzt sind.
class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.kind});

  final LegalKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lang = legalLanguageFor(Localizations.localeOf(context));
    final doc = ref.watch(legalDocumentProvider((kind: kind, lang: lang)));
    final config = ref.watch(appConfigProvider);
    final platform = ref.watch(platformInfoProvider);
    final title = kind == LegalKind.imprint
        ? l10n.legalImprintTitle
        : l10n.legalPrivacyTitle;

    // Eigene Seite: als Hauptinhalt kennzeichnen (NEU-2, Landmarke).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.main,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            if (!platform.isWeb)
              IconButton(
                tooltip: l10n.legalOpenInBrowser,
                icon: const Icon(Icons.open_in_new),
                onPressed: () => openExternalUrl(
                  context,
                  ref,
                  _webUrl(config.webBaseUrl, kind, lang),
                ),
              ),
          ],
        ),
        body: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: title,
          child: doc.when(
            data: (d) =>
                LegalBody(document: d, providers: activeLegalProviders(config)),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.legalLoadError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(
                        legalDocumentProvider((kind: kind, lang: lang)),
                      ),
                      child: Text(l10n.actionRetry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Adresse der statischen Web-Seite (`tool/gen_legal_html.dart`): Deutsch
  /// unter `/<kind>/`, Englisch unter `/<kind>/en/`.
  static String _webUrl(String base, LegalKind kind, String lang) {
    final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$root/${kind.assetName}/${lang == 'de' ? '' : 'en/'}';
  }
}

/// Rendert die sichtbaren Bloecke eines [LegalDocument].
class LegalBody extends ConsumerWidget {
  const LegalBody({super.key, required this.document, required this.providers});

  final LegalDocument document;
  final Set<String> providers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final width = MediaQuery.sizeOf(context).width;
    final compact = WindowClass.fromWidth(width) == WindowClass.compact;
    final side = width > 760 ? (width - 720) / 2 : 20.0;
    final blocks = document.visibleFor(providers);

    return SelectionArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(side, 8, side, 48),
        children: <Widget>[
          for (final b in blocks) _block(context, ref, b, compact: compact),
          if (document.updated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                l10n.legalUpdated(
                  formatLegalDate(document.updated, l10n.localeName),
                ),
                style: LinefmText.listMeta.copyWith(color: c.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _block(
    BuildContext context,
    WidgetRef ref,
    LegalBlock b, {
    required bool compact,
  }) {
    final c = context.linefm;
    final body = LinefmText.listTitle.copyWith(
      color: c.text,
      fontSize: 15,
      height: 1.65,
    );
    switch (b.type) {
      case LegalBlockType.h1:
        return SectionHeading(
          b.text,
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          style: TextStyle(fontSize: compact ? 16 : 25),
        );
      case LegalBlockType.h2:
        return Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 8),
            child: Text(
              b.text,
              style: LinefmText.settingTitle.copyWith(
                color: c.text,
                fontSize: 17,
              ),
            ),
          ),
        );
      case LegalBlockType.p:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text.rich(legalSpans(b.text, body, context)),
        );
      case LegalBlockType.ul:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final item in b.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 10),
                        child: Text('•', style: body),
                      ),
                      Expanded(
                        child: Text.rich(legalSpans(item, body, context)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      case LegalBlockType.link:
        return _LinkBlock(
          text: b.text,
          target: b.url,
          mail: false,
          style: body,
        );
      case LegalBlockType.mail:
        return _LinkBlock(
          text: b.text,
          target: b.address.isEmpty ? b.text : b.address,
          mail: true,
          style: body,
        );
    }
  }
}

final RegExp _placeholder = RegExp(r'\{\{(\w+)\}\}');

/// Text mit hervorgehobenen offenen Platzhaltern.
InlineSpan legalSpans(String text, TextStyle style, BuildContext context) {
  final c = context.linefm;
  final ph = style.copyWith(
    color: c.heart,
    fontWeight: FontWeight.w600,
    backgroundColor: c.heart.withValues(alpha: 0.10),
  );
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in _placeholder.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(text: m.group(0), style: ph));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return TextSpan(style: style, children: spans);
}

class _LinkBlock extends ConsumerWidget {
  const _LinkBlock({
    required this.text,
    required this.target,
    required this.mail,
    required this.style,
  });

  final String text;
  final String target;
  final bool mail;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.linefm;
    // Mit offenem Platzhalter kein Link, nur hervorgehobener Text.
    if (_placeholder.hasMatch(target) || _placeholder.hasMatch(text)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text.rich(legalSpans(text, style, context)),
      );
    }
    final uri = mail ? 'mailto:$target' : target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          link: true,
          child: InkWell(
            onTap: () => openExternalUrl(context, ref, uri),
            borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: LinefmMetrics.minTarget,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  text,
                  style: style.copyWith(
                    color: c.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: c.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stand-Datum der Rechtstexte (`2026-11-18` in der JSON) nach Sprache
/// (I01): Deutsch "18. November 2026", Englisch "November 18, 2026".
/// Unlesbare Werte bleiben unveraendert.
String formatLegalDate(String raw, String localeName) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  return DateFormat.yMMMMd(localeName).format(date);
}
