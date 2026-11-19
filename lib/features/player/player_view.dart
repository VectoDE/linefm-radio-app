import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/player/player_strings.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';
import 'package:material_ui/material_ui.dart';

/// Anzeigedaten des Players. Reine Werte, damit die Ansicht ohne Provider
/// gebaut und getestet werden kann.
@immutable
class PlayerViewData {
  const PlayerViewData({
    required this.station,
    this.track,
    this.coverUrl,
    this.status = PlayerStatus.idle,
    this.listeners,
    this.isFavorite = false,
    this.marquee = true,
  });

  final Station station;

  /// Laufender Titel, `null` solange er noch nicht geladen ist.
  final Track? track;

  /// Cover (iTunes 600x600). `null`: Rueckfall Senderlogo, dann Kuerzel.
  final String? coverUrl;
  final PlayerStatus status;
  final int? listeners;
  final bool isFavorite;

  /// Einstellung "Lauftext fuer lange Titel".
  final bool marquee;
}

/// Player-Screen (Spec 4.1/4.2): Cover gross, Titel und Kuenstler, die drei
/// Knoepfe der Web-App (Shuffle, Play/Stop, Herz), darunter Musikdienste,
/// Teilen und die Slots fuer Cast und AirPlay. Hintergrund ist der Verlauf
/// aus der Senderfarbe.
///
/// - Wischen links/rechts: naechster/vorheriger Sender. Wischen nach unten
///   schliesst den Player (nicht bei [embedded]). Dasselbe bieten
///   Screenreader-Aktionen, Pfeiltasten wechseln den Sender (Desktop).
/// - [topInset]/[bottomInset] halten Platz fuer Header und Navigation frei,
///   die der Shell darueber liegen (Web: Header + 30 oben, 110 unten).
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.data,
    required this.strings,
    required this.onTogglePlayback,
    required this.onShuffle,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onOpenMusicLinks,
    required this.onNextStation,
    required this.onPreviousStation,
    this.onClose,
    this.onRetry,
    this.castSlot,
    this.airPlaySlot,
    this.topInset = 0,
    this.bottomInset = 0,
    this.embedded = false,
  });

  final PlayerViewData data;
  final PlayerStrings strings;
  final VoidCallback onTogglePlayback;
  final VoidCallback onShuffle;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onOpenMusicLinks;
  final VoidCallback onNextStation;
  final VoidCallback onPreviousStation;

  /// Schliesst den Player (Handy). `null` schaltet die Wischgeste ab.
  final VoidCallback? onClose;
  final VoidCallback? onRetry;

  /// Slots aus P19 (Chromecast) und P17 (AirPlay). Leere Slots belegen
  /// keinen Platz.
  final Widget? castSlot;
  final Widget? airPlaySlot;
  final double topInset;
  final double bottomInset;

  /// In der festen Player-Spalte der breiten Layouts: kein Schliessen.
  final bool embedded;

  static const double _swipeVelocity = 300;
  static const double _closeVelocity = 700;

  @override
  Widget build(BuildContext context) {
    final colors = context.linefm;
    final brightness = Theme.of(context).brightness;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final station = data.station;
    final fg = StationStyle.onPlayerBody(station.color, colors, brightness);
    final gradient = StationStyle.playerGradient(
      station.color,
      colors,
      brightness,
    );

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final gutter = (width * 0.06).clamp(22.0, 88.0);
        final short = height < 760;
        final roomy = width >= 600 && height >= 800;
        final coverMax = roomy ? 380.0 : (short ? 250.0 : 310.0);
        final coverFactor = short ? 0.58 : 0.68;
        final coverSize = math.min(width * coverFactor, coverMax);
        final radius = width < 600
            ? LinefmMetrics.radiusCoverCompact
            : LinefmMetrics.radiusCover;
        final playing = data.status == PlayerStatus.playing;
        final cover = AnimatedScale(
          scale: playing || reduce ? 1 : 0.93,
          duration: LinefmMetrics.slow,
          curve: Curves.easeOutCubic,
          child: CoverImage(
            station: station,
            url: data.coverUrl,
            size: coverSize,
            borderRadius: radius,
            shadow: true,
            semanticLabel: strings.coverAlt,
          ),
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, topInset, gutter, bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, height - topInset - bottomInset),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(height: short ? 18 : 28),
                    cover,
                    SizedBox(height: short ? 18 : 30),
                    _StationLine(
                      name: station.displayName,
                      live: playing,
                      liveLabel: strings.live,
                      color: fg,
                    ),
                    const SizedBox(height: 10),
                    _TrackInfo(
                      data: data,
                      strings: strings,
                      color: fg,
                      viewportWidth: width,
                    ),
                    if (data.listeners != null) ...<Widget>[
                      const SizedBox(height: 14),
                      _ListenerBadge(
                        text: strings.listeners(data.listeners!),
                        color: fg,
                      ),
                    ],
                    SizedBox(height: short ? 16 : 24),
                    _Controls(
                      data: data,
                      strings: strings,
                      color: fg,
                      onShuffle: onShuffle,
                      onTogglePlayback: onTogglePlayback,
                      onToggleFavorite: onToggleFavorite,
                    ),
                    _StatusLine(
                      status: data.status,
                      strings: strings,
                      color: fg,
                      onRetry: onRetry,
                    ),
                    const SizedBox(height: 8),
                    _SecondaryRow(
                      data: data,
                      strings: strings,
                      color: fg,
                      onShare: onShare,
                      onOpenMusicLinks: onOpenMusicLinks,
                      castSlot: castSlot,
                      airPlaySlot: airPlaySlot,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final actions = <CustomSemanticsAction, VoidCallback>{
      CustomSemanticsAction(label: strings.next): onNextStation,
      CustomSemanticsAction(label: strings.previous): onPreviousStation,
      if (!embedded && onClose != null)
        CustomSemanticsAction(label: strings.close): onClose!,
    };

    return AnimatedContainer(
      duration: reduce ? Duration.zero : LinefmMetrics.slow,
      curve: Curves.easeOut,
      decoration: BoxDecoration(gradient: gradient),
      // Material hinter den Knoepfen, damit Ink-Effekte ueber dem Verlauf
      // liegen.
      child: Material(
        type: MaterialType.transparency,
        child: IconTheme(
          data: IconThemeData(color: fg),
          // Pfeiltasten: CallbackShortcuts muss OBERHALB des Focus liegen,
          // Tastenereignisse laufen vom Fokus nach oben.
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.arrowRight):
                  onNextStation,
              const SingleActivator(LogicalKeyboardKey.arrowLeft):
                  onPreviousStation,
            },
            child: Focus(
              autofocus: embedded,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v <= -_swipeVelocity) onNextStation();
                  if (v >= _swipeVelocity) onPreviousStation();
                },
                onVerticalDragEnd: embedded || onClose == null
                    ? null
                    : (details) {
                        if ((details.primaryVelocity ?? 0) >= _closeVelocity) {
                          onClose!();
                        }
                      },
                child: Semantics(
                  container: true,
                  customSemanticsActions: actions,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      fontSize: 10,
      height: 1.4,
      letterSpacing: 1.6,
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
          const SizedBox(width: 6),
          ExcludeSemantics(child: Text(liveLabel, style: style)),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
    return Semantics(
      liveRegion: true,
      container: true,
      label: '$title, $artist',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: MarqueeText(
                title,
                enabled: data.marquee,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: LinefmFonts.brand,
                  fontWeight: FontWeight.w700,
                  // Web-App: h1 mit 20 px. Auf Tablets etwas groesser.
                  fontSize: viewportWidth >= 600 ? 24 : 20,
                  height: 1.3,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 5),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
            const SizedBox(width: 8),
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

/// Shuffle, Play/Stop, Herz wie in der Web-App.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.data,
    required this.strings,
    required this.color,
    required this.onShuffle,
    required this.onTogglePlayback,
    required this.onToggleFavorite,
  });

  final PlayerViewData data;
  final PlayerStrings strings;
  final Color color;
  final VoidCallback onShuffle;
  final VoidCallback onTogglePlayback;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final hasTrack = data.track != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _IconAction(
          label: strings.shuffle,
          onPressed: onShuffle,
          color: color.withValues(alpha: 0.8),
          child: FaIcon(
            FontAwesomeIcons.shuffle,
            size: 24,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 26),
        PlayButton(
          status: data.status,
          onPressed: onTogglePlayback,
          color: color,
          labelPlay: strings.start,
          labelConnecting: strings.connecting,
          labelStop: strings.stop,
        ),
        const SizedBox(width: 26),
        _IconAction(
          label: data.isFavorite ? strings.favoriteRemove : strings.favoriteAdd,
          onPressed: hasTrack ? onToggleFavorite : null,
          color: color,
          child: AnimatedSwitcher(
            duration: LinefmMetrics.fast,
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: FaIcon(
              data.isFavorite
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.heart,
              key: ValueKey<bool>(data.isFavorite),
              size: 25,
              color: color.withValues(alpha: hasTrack ? 0.9 : 0.4),
            ),
          ),
        ),
      ],
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
    if (message == null) return const SizedBox(height: 12);
    final style = LinefmText.listMeta.copyWith(
      color: color.withValues(alpha: 0.9),
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
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

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({
    required this.data,
    required this.strings,
    required this.color,
    required this.onShare,
    required this.onOpenMusicLinks,
    required this.castSlot,
    required this.airPlaySlot,
  });

  final PlayerViewData data;
  final PlayerStrings strings;
  final Color color;
  final VoidCallback onShare;
  final VoidCallback onOpenMusicLinks;
  final Widget? castSlot;
  final Widget? airPlaySlot;

  @override
  Widget build(BuildContext context) {
    final hasTrack = data.track != null;
    final border = color.withValues(alpha: 0.32);
    // Abstand ueber Padding statt Wrap-spacing: leere Slots (SizedBox.shrink)
    // verschieben sonst die Mitte.
    Widget gap(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: child,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (hasTrack)
          gap(
            _PillAction(
              label: strings.openSongIn,
              icon: FontAwesomeIcons.music,
              color: color,
              border: border,
              onPressed: onOpenMusicLinks,
            ),
          ),
        if (hasTrack)
          gap(
            _IconAction(
              label: strings.shareSong,
              onPressed: onShare,
              color: color,
              border: border,
              child: FaIcon(
                FontAwesomeIcons.shareNodes,
                size: 18,
                color: color,
              ),
            ),
          ),
        if (castSlot != null) gap(castSlot!),
        if (airPlaySlot != null) gap(airPlaySlot!),
      ],
    );
  }
}

/// Runder Symbolknopf mit mindestens 48 dp Tippflaeche, Tooltip (Desktop)
/// und Fokusring. Optional mit feinem Rand.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.label,
    required this.onPressed,
    required this.child,
    required this.color,
    this.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        onTap: onPressed,
        child: FocusRing(
          shape: BoxShape.circle,
          borderRadius: LinefmMetrics.minTarget / 2,
          child: SizedBox.square(
            dimension: LinefmMetrics.minTarget,
            child: InkResponse(
              onTap: onPressed,
              radius: LinefmMetrics.minTarget / 2,
              highlightShape: BoxShape.circle,
              containedInkWell: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: border == null ? null : Border.all(color: border!),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abgerundete Schaltflaeche mit Symbol und Text (48 dp hoch).
class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.border,
    required this.onPressed,
  });

  final String label;
  final FaIconData icon;
  final Color color;
  final Color border;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: FocusRing(
        borderRadius: LinefmMetrics.minTarget / 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
          child: Container(
            height: LinefmMetrics.minTarget,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FaIcon(icon, size: 15, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: LinefmText.listMeta.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
