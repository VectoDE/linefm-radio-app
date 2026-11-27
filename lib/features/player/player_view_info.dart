part of 'player_view.dart';

/// Zeile "LIVE - Sendername".
class _StationLine extends StatelessWidget {
  const _StationLine({
    required this.name,
    required this.live,
    required this.liveLabel,
    required this.color,
  });

  final String name;
  final bool live;
  final String liveLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: LinefmFonts.brand,
      fontWeight: FontWeight.w700,
      fontSize: LinefmType.caption,
      height: 1.4,
      letterSpacing: 1.2,
      color: color.withValues(alpha: 0.82),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (live) ...<Widget>[
          ExcludeSemantics(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: LinefmSpace.sm),
          ExcludeSemantics(child: Text(liveLabel, style: style)),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.sm),
              child: Text('·', style: style),
            ),
          ),
        ],
        Flexible(
          child: Text(
            name.toUpperCase(),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Titel und Kuenstler als Live-Region: Screenreader sagen jeden Titelwechsel
/// einmal an.
class _TrackInfo extends StatelessWidget {
  const _TrackInfo({
    required this.data,
    required this.strings,
    required this.color,
    required this.viewportWidth,
  });

  final PlayerViewData data;
  final PlayerStrings strings;
  final Color color;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    final track = data.track;
    final title = track?.title ?? data.station.displayName;
    final artist = track?.artist ?? strings.trackLoading;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        liveRegion: true,
        container: true,
        label: '$title, $artist',
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: MarqueeText(
                // Syncopate ohne Kapitaelchen: Grossbuchstaben.
                title.toUpperCase(),
                enabled: data.marquee,
                textAlign: TextAlign.center,
                style: LinefmText.playerSongTitle(viewportWidth)
                    .copyWith(color: color),
              ),
            ),
            const SizedBox(height: LinefmSpace.xs),
            SizedBox(
              width: double.infinity,
              child: MarqueeText(
                artist,
                enabled: data.marquee,
                textAlign: TextAlign.center,
                style: LinefmText.playerArtist.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenerBadge extends StatelessWidget {
  const _ListenerBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LinefmSpace.md,
          vertical: LinefmSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: FaIcon(
                FontAwesomeIcons.headphones,
                size: 12,
                color: color.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: LinefmSpace.sm),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LinefmText.listMeta.copyWith(
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Meldung unter den Knoepfen: Wiederverbinden und Fehler mit Retry.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.status,
    required this.strings,
    required this.color,
    required this.onRetry,
  });

  final PlayerStatus status;
  final PlayerStrings strings;
  final Color color;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String? message = switch (status) {
      PlayerStatus.reconnecting => strings.reconnecting,
      PlayerStatus.error => strings.streamError,
      _ => null,
    };
    if (message == null) return const SizedBox(height: LinefmSpace.md);
    final style = LinefmText.listMeta.copyWith(
      color: color.withValues(alpha: 0.9),
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: LinefmSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, style: style, textAlign: TextAlign.center),
            if (status == PlayerStatus.error && onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  minimumSize: const Size(
                    LinefmMetrics.minTarget,
                    LinefmMetrics.minTarget,
                  ),
                ),
                child: Text(strings.retry),
              ),
          ],
        ),
      ),
    );
  }
}
