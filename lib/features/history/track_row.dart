import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:material_ui/material_ui.dart';

/// Zeile fuer Verlauf und Favoriten (`.history-item` der Web-App):
/// Cover 40 dp, Titel und Kuenstler als Lauftext, rechts [meta] (Uhrzeit,
/// LIVE) und [trailing] (Herz, Papierkorb). Mindesthoehe 72 dp, Trennlinie
/// unten. Hoehe waechst bei grosser Systemschrift mit.
///
/// Screenreader: Cover, Titel, Kuenstler und [meta] werden zu EINEM Knoten mit
/// [semanticLabel] zusammengefasst; [trailing] bleibt eigener Knoten.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.station,
    required this.title,
    required this.artist,
    required this.semanticLabel,
    this.coverUrl,
    this.meta,
    this.trailing,
    this.marquee = true,
    this.showDivider = true,
  });

  final Station station;
  final String title;
  final String artist;
  final String semanticLabel;
  final String? coverUrl;

  /// Rechts neben dem Text (z. B. Uhrzeit), rein visuell.
  final Widget? meta;

  /// Aktionsknopf ganz rechts (48 dp).
  final Widget? trailing;

  /// Einstellung "Lauftext".
  final bool marquee;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider ? Border(bottom: BorderSide(color: c.line)) : null,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  container: true,
                  label: semanticLabel,
                  excludeSemantics: true,
                  child: Row(
                    children: <Widget>[
                      CoverImage(station: station, url: coverUrl, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            MarqueeText(
                              title,
                              enabled: marquee,
                              style: LinefmText.listTitleStrong.copyWith(
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            MarqueeText(
                              artist,
                              enabled: marquee,
                              style: LinefmText.listMeta.copyWith(
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (meta != null) ...<Widget>[
                        const SizedBox(width: 8),
                        meta!,
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) trailing! else const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
