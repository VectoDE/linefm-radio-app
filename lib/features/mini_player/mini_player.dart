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
                child: _MiniBackdrop(
                  color: station.color,
                  coverUrl: cover,
                  base: c.miniPlayerBg,
                  veil: c.background,
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

/// Unscharfes, abgedunkeltes Cover (blur 22, brightness .58) mit den beiden
/// Verlaeufen der Web-App; ohne Cover nur der Verlauf in der Senderfarbe.
class _MiniBackdrop extends StatelessWidget {
  const _MiniBackdrop({
    required this.color,
    required this.coverUrl,
    required this.base,
    required this.veil,
  });

  final Color color;
  final String? coverUrl;

  /// Grundflaeche aus dem Theme (`miniPlayerBg`).
  final Color base;

  /// Farbe des Schleiers ueber dem Cover (Seitenhintergrund des Themes).
  final Color veil;

  static const Alignment _from = Alignment(-0.966, -0.259);
  static const Alignment _to = Alignment(0.966, 0.259);

  @override
  Widget build(BuildContext context) {
    final cover = coverUrl;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: base),
        if (cover != null && cover.isNotEmpty) ...<Widget>[
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: 22,
              sigmaY: 22,
              tileMode: TileMode.mirror,
            ),
            child: Image(
              image: ResizeImage.resizeIfNeeded(
                120,
                null,
                CoverImage.providerFor(cover),
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _from,
                end: _to,
                colors: <Color>[
                  veil.withValues(alpha: 0.62),
                  veil.withValues(alpha: 0.76),
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
                colors: <Color>[
                  color.withValues(alpha: MiniPlayerContrast.leftStrength),
                  LinefmPalette.clearBlack,
                ],
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
              stops: MiniPlayerContrast.rightStops,
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
  const _SleepRemaining({required this.color});

  final Color color;

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
            FaIcon(FontAwesomeIcons.moon, size: 10, color: widget.color),
            const SizedBox(width: LinefmSpace.sm),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LinefmText.time.copyWith(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Farbverlauf und Kontrastregeln des Mini-Players, auch fuer Tests.
abstract final class MiniPlayerContrast {
  /// Deckkraft der Senderfarbe am linken Rand (ohne Cover).
  static const double leftStrength = 0.45;

  /// Stopps der Senderfarbe nach rechts: 0, 28 % und 82 % Deckkraft. Sie
  /// beginnt erst hinter dem Textbereich.
  static const List<double> rightStops = <double>[0.34, 0.64, 1];

  /// Anteil der Breite, ueber den Titel und Interpret laufen.
  static const double textStart = 0.22;
  static const double textEnd = 0.70;

  /// Schleier ueber dem Cover (kleinste Deckkraft).
  static const double coverVeil = 0.62;

  static double _overlay(double u) {
    if (u <= rightStops[0]) return 0;
    if (u <= rightStops[1]) {
      return 0.28 * (u - rightStops[0]) / (rightStops[1] - rightStops[0]);
    }
    return 0.28 + 0.54 * (u - rightStops[1]) / (rightStops[2] - rightStops[1]);
  }

  /// Flaeche ohne Cover an der Stelle [u] (0 links, 1 rechts).
  static Color backgroundAt(
    double u, {
    required Color station,
    required Color base,
  }) => Color.alphaBlend(
    station.withValues(alpha: _overlay(u)),
    Color.alphaBlend(station.withValues(alpha: (1 - u) * leftStrength), base),
  );

  /// Anteil der Breite, ab dem die Knoepfe liegen.
  static const double buttonsStart = 0.72;

  /// Hintergruende unter den Knoepfen.
  static List<Color> buttonBackgrounds(Color station, Color base) => <Color>[
    for (var u = buttonsStart; u <= 1 + 1e-9; u += 0.04)
      backgroundAt(u, station: station, base: base),
  ];

  /// Knopffarbe: [Contrast.paper] oder [Contrast.ink], je nachdem, welche
  /// auf dem unguenstigsten Hintergrund unter den Knoepfen mehr Kontrast hat.
  static Color buttonColor(Color station, Color base) {
    final bgs = buttonBackgrounds(station, base);
    double worst(Color fg) =>
        bgs.map((b) => Contrast.ratio(fg, b)).reduce(math.min);
    return worst(Contrast.paper) >= worst(Contrast.ink)
        ? Contrast.paper
        : Contrast.ink;
  }

  /// Hintergruende unter dem Text, von links nach rechts abgetastet.
  static List<Color> textBackgrounds({
    required Color station,
    required Color base,
    required Color background,
    required bool hasCover,
  }) {
    if (hasCover) {
      // Unbekanntes Bild: schwarz und weiss als Extreme unter dem Schleier.
      return <Color>[
        for (final under in const <Color>[Color(0xFF000000), Color(0xFFFFFFFF)])
          Color.alphaBlend(background.withValues(alpha: coverVeil), under),
      ];
    }
    return <Color>[
      for (var u = textStart; u <= textEnd + 1e-9; u += 0.04)
        backgroundAt(u, station: station, base: base),
    ];
  }

  /// Unguenstigster Hintergrund fuer die Theme-Textfarbe.
  static Color worstTextBackground({
    required Color station,
    required Color base,
    required Color background,
    required bool hasCover,
    Color? text,
  }) {
    final all = textBackgrounds(
      station: station,
      base: base,
      background: background,
      hasCover: hasCover,
    );
    final fg = text ?? _farthest(all);
    all.sort((a, b) => Contrast.ratio(fg, a).compareTo(Contrast.ratio(fg, b)));
    return all.first;
  }

  static Color _farthest(List<Color> bgs) =>
      bgs.first.computeLuminance() > 0.18 ? Contrast.ink : Contrast.paper;

  /// [text] mit [alpha], solange es auf [worst] 4,5:1 erreicht, sonst
  /// schrittweise deckender bis voll.
  static Color secondary(Color text, Color worst, double alpha) {
    for (var a = alpha; a < 1; a += 0.04) {
      final c = text.withValues(alpha: a);
      if (Contrast.ratioOver(c, worst) >= Contrast.aaText) return c;
    }
    return text;
  }
}
