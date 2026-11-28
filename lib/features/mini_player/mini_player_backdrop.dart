part of 'mini_player.dart';

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
