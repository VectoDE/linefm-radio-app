import 'dart:math' as math;

import 'package:flutter/rendering.dart';
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
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

part 'player_view_info.dart';
part 'player_view_actions.dart';
part 'player_slot_gap.dart';

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
    this.onSleepTimer,
    this.sleepTimerActive = false,
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

  /// Oeffnet die Sleeptimer-Auswahl (U2). `null` blendet den Knopf aus.
  final VoidCallback? onSleepTimer;

  /// Sleeptimer laeuft: Knopf hervorgehoben.
  final bool sleepTimerActive;
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
                    const SizedBox(height: LinefmSpace.md),
                    _TrackInfo(
                      data: data,
                      strings: strings,
                      color: fg,
                      viewportWidth: width,
                    ),
                    if (data.listeners != null) ...<Widget>[
                      const SizedBox(height: LinefmSpace.lg),
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
                    const SizedBox(height: LinefmSpace.sm),
                    _SecondaryRow(
                      data: data,
                      strings: strings,
                      color: fg,
                      onShare: onShare,
                      onOpenMusicLinks: onOpenMusicLinks,
                      castSlot: castSlot,
                      airPlaySlot: airPlaySlot,
                      onSleepTimer: onSleepTimer,
                      sleepTimerActive: sleepTimerActive,
                    ),
                    const SizedBox(height: LinefmSpace.md),
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
