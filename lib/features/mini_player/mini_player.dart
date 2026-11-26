import 'dart:async';
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

/// Basis des Mini-Players (Web: `rgba(15, 18, 33, .86)`). Der Player liegt
/// immer auf einem abgedunkelten Cover, deshalb ist er in beiden Themes dunkel
/// mit weisser Schrift.
const Color _miniBase = Color.fromRGBO(15, 18, 33, 0.86);

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

    // Die Senderfarbe liegt rechts bis 82 % deckend hinter den Knoepfen:
    // Knopffarbe nach Kontrast waehlen (FobFM und +GAMING bekommen dunkle
    // Knoepfe).
    final rightEnd = Color.alphaBlend(
      station.color.withValues(alpha: 0.82),
      LinefmPalette.miniPlayerBase,
    );
    final onRight = Contrast.onColor(rightEnd, large: true);

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
                child: _MiniBackdrop(color: station.color, coverUrl: cover),
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
    required this.hint,
    required this.onTap,
    this.lastSeen,
  });

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
                          .copyWith(color: LinefmPalette.paper),
                    ),
                    if (artist.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: LinefmSpace.xs),
                        child: MarqueeText(
                          artist,
                          enabled: marquee,
                          style: LinefmText.miniArtist(compact: compact)
                              .copyWith(
                                color: const Color.fromRGBO(255, 255, 255, .82),
                              ),
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
                                color: const Color.fromRGBO(255, 255, 255, .7),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    const _SleepRemaining(),
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

/// Unscharfes, abgedunkeltes Cover (blur 22, brightness .58) mit den beiden
/// Verlaeufen der Web-App; ohne Cover nur der Verlauf in der Senderfarbe.
class _MiniBackdrop extends StatelessWidget {
  const _MiniBackdrop({required this.color, required this.coverUrl});

  final Color color;
  final String? coverUrl;

  static const Alignment _from = Alignment(-0.966, -0.259);
  static const Alignment _to = Alignment(0.966, 0.259);

  @override
  Widget build(BuildContext context) {
    final cover = coverUrl;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: _miniBase),
        if (cover != null && cover.isNotEmpty) ...<Widget>[
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 22,
              sigmaY: 22,
              tileMode: TileMode.mirror,
            ),
            child: Image.network(
              cover,
              fit: BoxFit.cover,
              cacheWidth: 120,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _from,
                end: _to,
                colors: <Color>[
                  Color.fromRGBO(15, 18, 33, 0.62),
                  Color.fromRGBO(15, 18, 33, 0.76),
                ],
              ),
            ),
          ),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _from,
                end: _to,
                colors: <Color>[color, LinefmPalette.clearBlack],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _from,
              end: _to,
              colors: <Color>[
                LinefmPalette.clearBlack,
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.82),
              ],
              stops: const <double>[0.18, 0.48, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Restzeit des Sleeptimers ("Noch 12 Min."), solange einer laeuft und das
/// Ende bekannt ist. Aktualisiert sich alle 15 s, Screenreader bekommen eine
/// Live-Region.
class _SleepRemaining extends ConsumerStatefulWidget {
  const _SleepRemaining();

  @override
  ConsumerState<_SleepRemaining> createState() => _SleepRemainingState();
}

class _SleepRemainingState extends ConsumerState<_SleepRemaining> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final endsAt = ref.watch(sleepTimerProvider.select((s) => s.endsAt));
    final active = ref.watch(sleepTimerProvider.select((s) => s.isActive));
    if (!active || endsAt == null) return const SizedBox.shrink();
    final left = endsAt.difference(ref.read(clockProvider).now());
    if (left.isNegative || left == Duration.zero) {
      return const SizedBox.shrink();
    }
    final minutes = (left.inSeconds / 60).ceil();
    final text = AppLocalizations.of(context).sleepRemainingShort(minutes);
    return Padding(
      padding: const EdgeInsets.only(top: LinefmSpace.xs),
      child: Semantics(
        liveRegion: true,
        label: text,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const FaIcon(
              FontAwesomeIcons.moon,
              size: 10,
              color: Color.fromRGBO(255, 255, 255, .82),
            ),
            const SizedBox(width: LinefmSpace.sm),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LinefmText.time.copyWith(
                  color: const Color.fromRGBO(255, 255, 255, .82),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
