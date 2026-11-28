import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/features/mini_player/volume_popover.dart';
import 'package:linefm_radio/features/stations/station_actions.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

part 'mini_player_backdrop.dart';

/// Platz fuer den Mini-Player in der Shell: blendet ihn aus, solange der
/// Player-Screen offen ist oder das breite Layout mit fester Player-Spalte
/// aktiv ist (Spec 4.3), und schiebt ihn sonst mit kurzer Animation ein.
class MiniPlayerSlot extends ConsumerWidget {
  const MiniPlayerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(navigationProvider);
    final visible =
        screen != AppScreen.player &&
        WindowClass.of(context) != WindowClass.expanded;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : LinefmMetrics.medium,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? const MiniPlayer(key: ValueKey<String>('mini'))
          : const SizedBox.shrink(key: ValueKey<String>('mini-hidden')),
    );
  }
}

/// Mini-Player (`.mini-player` der Web-App): Cover, Titel und Kuenstler als
/// Lauftext, Restzeit des Sleeptimers, Lautstaerke-Popover und Play/Stop.
/// Hintergrund ist das unscharfe, abgedunkelte Cover mit Verlauf in der
/// Senderfarbe. Antippen von Cover oder Titel oeffnet den Player.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.onOpenPlayer});

  /// Standard: `navigationProvider` auf den Player-Screen.
  final VoidCallback? onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final station = ref.watch(activeStationProvider);
    final track = ref.watch(currentTrackProvider).value;
    final status = ref.watch(
      playerStateProvider.select((s) => s.value?.status ?? PlayerStatus.idle),
    );
    final marquee = ref.watch(settingsProvider.select((s) => s.marquee));

    final compact = MediaQuery.sizeOf(context).width < 560;
    final title = track?.title ?? station.displayName;
    final artist = track?.artist ?? '';
    final cover = track?.artworkUrl;

    // Basis aus dem Theme (`miniPlayerBg`, Dunkel wie die Web-App, Hell
    // entsprechend hell), deckend gedacht ueber dem Seitenhintergrund.
    final c = context.linefm;
    final base = Color.alphaBlend(c.miniPlayerBg, c.background);
    // Die Senderfarbe liegt rechts bis 82 % deckend hinter den Knoepfen:
    // Knopffarbe nach Kontrast waehlen (FobFM und +GAMING bekommen dunkle
    // Knoepfe).
    final onRight = MiniPlayerContrast.buttonColor(station.color, base);
    // Links: mit Cover liegt die Schrift auf dem Cover unter einem Schleier
    // in Hintergrundfarbe (Theme-Textfarbe), ohne Cover auf der Senderfarbe
    // (Schriftfarbe nach Kontrast).
    final hasCover = cover != null && cover.isNotEmpty;
    // Links liegt die Senderfarbe nur gedaempft, die Schrift nimmt immer die
    // Theme-Textfarbe. Zweitzeilen werden nur so weit abgeschwaecht, wie der
    // unguenstigste Hintergrund unter der Schrift noch 4,5:1 zulaesst.
    final onLeft = c.text;
    final worst = MiniPlayerContrast.worstTextBackground(
      station: station.color,
      base: base,
      background: c.background,
      hasCover: hasCover,
      text: onLeft,
    );
    Color soft(double alpha) =>
        MiniPlayerContrast.secondary(onLeft, worst, alpha);

    final radius = BorderRadius.circular(
      compact ? 16 : LinefmMetrics.radiusMiniPlayer,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? LinefmSpace.md : LinefmSpace.lg,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.12),
              blurRadius: 40,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                // Own layer: the blurred cover is not repainted when the
                // marquee, buttons or sleep timer above it change.
                child: RepaintBoundary(
                  child: _MiniBackdrop(
                    color: station.color,
                    coverUrl: cover,
                    base: c.miniPlayerBg,
                    veil: c.background,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: compact ? 78 : 90),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LinefmSpace.sm,
                    vertical: LinefmSpace.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _TrackArea(
                          station: station,
                          coverUrl: cover,
                          title: title,
                          artist: artist,
                          marquee: marquee,
                          compact: compact,
                          color: onLeft,
                          artistColor: soft(0.82),
                          hintColor: soft(0.7),
                          hint: l10n.miniOpenPlayer,
                          lastSeen: track?.lastSeen ?? false
                              ? l10n.trackLastSeen
                              : null,
                          onTap:
                              onOpenPlayer ??
                              () => ref
                                  .read(navigationProvider.notifier)
                                  .go(AppScreen.player),
                        ),
                      ),
                      VolumeButton(color: onRight),
                      PlayButton(
                        status: status,
                        size: compact ? 56 : 70,
                        color: onRight,
                        labelPlay: l10n.playerStart,
                        labelConnecting: l10n.playerConnecting,
                        labelStop: l10n.playerStop,
                        onPressed: () => ref.toggleActiveStation(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackArea extends StatelessWidget {
  const _TrackArea({
    required this.station,
    required this.coverUrl,
    required this.title,
    required this.artist,
    required this.marquee,
    required this.compact,
    required this.color,
    required this.artistColor,
    required this.hintColor,
    required this.hint,
    required this.onTap,
    this.lastSeen,
  });

  /// Schriftfarbe links (Theme-Textfarbe).
  final Color color;

  /// Interpret und Sleeptimer-Rest, mindestens 4,5:1.
  final Color artistColor;

  /// "Zuletzt gesehen", mindestens 4,5:1.
  final Color hintColor;

  final Station station;
  final String? coverUrl;
  final String title;
  final String artist;
  final bool marquee;
  final bool compact;
  final String hint;
  final VoidCallback onTap;

  /// "Last seen" hint for a track restored from the device, else null.
  final String? lastSeen;

  @override
  Widget build(BuildContext context) {
    final coverSize = compact ? 62.0 : 72.0;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: <String>[
          title,
          if (artist.isNotEmpty) artist,
          ?lastSeen,
        ].join(', '),
        hint: hint,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: FocusRing(
        borderRadius: 14,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: <Widget>[
              CoverImage(
                station: station,
                url: coverUrl,
                size: coverSize,
                borderRadius: compact ? 12 : 14,
              ),
              SizedBox(width: compact ? 11 : 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MarqueeText(
                      title,
                      enabled: marquee,
                      style: LinefmText.miniTitle(compact: compact)
                          .copyWith(color: color),
                    ),
                    if (artist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: LinefmSpace.xs),
                        child: MarqueeText(
                          artist,
                          enabled: marquee,
                          style: LinefmText.miniArtist(compact: compact)
                              .copyWith(color: artistColor),
                        ),
                      ),
                    if (lastSeen case final String hint)
                      Padding(
                        padding: const EdgeInsets.only(top: LinefmSpace.xs),
                        child: Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LinefmText.miniArtist(compact: compact)
                              .copyWith(
                                color: hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    _SleepRemaining(color: artistColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
