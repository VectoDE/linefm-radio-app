import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:linefm_radio/features/loader/made_by_credit.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Hintergrund des Ladebildschirms, identisch zum nativen Splash.
const Color loaderBackground = Color(0xFF0F1221);

/// Ladebildschirm der Web-App: Wortmarke auf weisser Kachel, um -7 Grad
/// geneigt, drei pulsierende Punkte und die Zeile "Made by .jaybelife with ♥".
///
/// Immer dunkel, weil der native Splash davor ebenfalls `#0f1221` ist. Bei
/// "Animationen reduzieren" stehen die Punkte still.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  static const Color _heart = Color(0xFFFF4B6E);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width <= 480;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    const credit = MadeByCredit(
      style: TextStyle(
        fontFamily: LinefmFonts.body,
        fontSize: 12,
        height: 1.5,
        color: Color(0x8CFFFFFF),
      ),
      authorColor: Color(0xFFFFFFFF),
      heartColor: _heart,
      textAlign: TextAlign.center,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.loaderSemantics,
      child: ExcludeSemantics(
        child: Material(
          color: loaderBackground,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Dunkles Band links hinten (`.app-loader::before`).
              LayoutBuilder(
                builder: (context, box) => Stack(
                  children: <Widget>[
                    Positioned(
                      left: -0.1 * box.maxWidth,
                      top: -0.2 * box.maxHeight,
                      width: 0.6 * box.maxWidth,
                      height: 1.4 * box.maxHeight,
                      child: Transform.rotate(
                        angle: -7 * math.pi / 180,
                        child: const ColoredBox(color: Color(0x0D000000)),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Transform(
                  transform: Matrix4.skewY(-7 * math.pi / 180),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ColoredBox(
                        color: const Color(0xFFFFFFFF),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            l10n.brandName.toUpperCase(),
                            style: LinefmText.loaderBrand(compact: compact)
                                .copyWith(color: loaderBackground),
                          ),
                        ),
                      ),
                      const SizedBox(height: 75),
                      Transform(
                        transform: Matrix4.skewY(7 * math.pi / 180),
                        alignment: Alignment.center,
                        child: _Dots(animate: !reduce),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 20 + bottom, child: credit),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots({required this.animate});

  final bool animate;

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_Dots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Verlauf wie `@keyframes app-loader-pulse`: 0-80 % und 100 % klein und
  /// blass, bei 40 % gross und hell.
  static double _phase(double t) {
    final x = t % 1;
    if (x < 0.4) return x / 0.4;
    if (x < 0.8) return 1 - (x - 0.4) / 0.4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < 3; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 7),
              _dot(
                widget.animate ? _phase(_controller.value - i * 0.125) : 0.5,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _dot(double p) {
    final eased = Curves.easeInOut.transform(p);
    return Opacity(
      opacity: 0.2 + 0.8 * eased,
      child: Transform.scale(
        scale: 0.75 + 0.45 * eased,
        child: const SizedBox.square(
          dimension: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

/// Merkt sich, dass der Ladebildschirm in diesem Prozess schon lief
/// (Warmstart ohne Loader). Tests setzen den Wert zurueck.
@visibleForTesting
bool loaderShownThisProcess = false;

/// Zeigt den Ladebildschirm beim Kaltstart ueber [child] und blendet ihn nach
/// [minDuration] in 350 ms aus. Das Kind baut sich im Hintergrund schon auf,
/// ist aber fuer Bedienung und Screenreader gesperrt, solange der Loader
/// steht. Ein Neuaufbau im selben Prozess (Warmstart) zeigt keinen Loader.
///
/// Dauer: Web hoechstens 400 ms (P30-03; die alte Web-App hielt 2 s und
/// verzoegerte so den ersten Inhalt), nativ 300 ms, weil davor schon der
/// native Splash steht.
class LoaderGate extends StatefulWidget {
  const LoaderGate({super.key, required this.child, this.minDuration});

  final Widget child;

  /// Standard: [defaultMinDuration].
  final Duration? minDuration;

  static const Duration webMinDuration = Duration(milliseconds: 400);
  static const Duration nativeMinDuration = Duration(milliseconds: 300);
  static const Duration fadeDuration = Duration(milliseconds: 350);

  static Duration get defaultMinDuration =>
      kIsWeb ? webMinDuration : nativeMinDuration;

  @override
  State<LoaderGate> createState() => _LoaderGateState();
}

class _LoaderGateState extends State<LoaderGate> {
  Timer? _timer;
  bool _visible = false;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    if (loaderShownThisProcess) return;
    loaderShownThisProcess = true;
    _visible = true;
    _timer = Timer(widget.minDuration ?? LoaderGate.defaultMinDuration, () {
      if (!mounted) return;
      setState(() => _fading = true);
      _timer = Timer(LoaderGate.fadeDuration, () {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ExcludeSemantics(
          excluding: !_fading,
          child: IgnorePointer(ignoring: !_fading, child: widget.child),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _fading,
            child: AnimatedOpacity(
              opacity: _fading ? 0 : 1,
              duration: reduce ? Duration.zero : LoaderGate.fadeDuration,
              curve: Curves.easeOut,
              child: const AppLoader(),
            ),
          ),
        ),
      ],
    );
  }
}
