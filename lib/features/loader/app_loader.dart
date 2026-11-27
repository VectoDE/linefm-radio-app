import 'dart:async';
import 'dart:math' as math;

import 'package:linefm_radio/features/loader/made_by_credit.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/desktop/window_reveal.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Background of the loading screen, identical to the native splash.
const Color loaderBackground = LinefmPalette.ink;

/// Loading screen of the web app: word mark on a white tile, tilted by -7
/// degrees, three pulsing dots and the line "Made by Tim Hauke with ♥".
///
/// Always dark, because the native splash before it is also `#0f1221`. With
/// "reduce animations" the dots stand still.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  static const Color _heart = LinefmPalette.heart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width <= 480;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    const credit = MadeByCredit(
      style: TextStyle(
        fontFamily: LinefmFonts.body,
        fontSize: LinefmType.caption,
        height: 1.5,
        color: LinefmPalette.loaderCaption,
      ),
      authorColor: LinefmPalette.paper,
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
              // Dark band at the back left (`.app-loader::before`).
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
                        child: const ColoredBox(
                          color: LinefmPalette.loaderStripe,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: LoaderMark(compact: compact, animate: !reduce),
              ),
              Positioned(left: 0, right: 0, bottom: 20 + bottom, child: credit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Word mark on the white tile, tilted by -7 degrees, with the three dots
/// below. Centred on screen by [AppLoader]; the native splash images
/// (Android before 12, iOS) are rendered from this widget by
/// `tool/splash/render_splash_test.dart`, so the hand-over from the native
/// splash to the first Flutter frame does not move or change anything.
class LoaderMark extends StatelessWidget {
  const LoaderMark({super.key, required this.compact, required this.animate});

  /// Phones (up to 480 dp): larger word mark.
  final bool compact;

  /// Pulse the dots; off with "reduce motion".
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Transform(
      transform: Matrix4.skewY(-7 * math.pi / 180),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ColoredBox(
            color: LinefmPalette.paper,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.md),
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
            child: _Dots(animate: animate),
          ),
        ],
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

  /// Curve like `@keyframes app-loader-pulse`: 0-80 % and 100 % small and
  /// faint, at 40 % large and bright.
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
              if (i > 0) const SizedBox(width: LinefmSpace.sm),
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
              color: LinefmPalette.paper,
            ),
          ),
        ),
      ),
    );
  }
}

/// Remembers that the loading screen already ran in this process
/// (warm start without loader). Tests reset the value.
@visibleForTesting
bool loaderShownThisProcess = false;

/// Shows the loading screen over [child] on a cold start, only as long as
/// necessary: after the first painted frame (or after the desktop window is
/// revealed) it fades out over [fadeDuration]. There is no fixed minimum
/// time any more; [minDuration] remains only for tests and special cases.
/// The child already builds in the background, but is blocked for input and
/// screen readers while the loader is opaque. A rebuild in the same
/// process (warm start) shows no loader.
class LoaderGate extends StatefulWidget {
  const LoaderGate({
    super.key,
    required this.child,
    this.minDuration = Duration.zero,
  });

  final Widget child;

  /// Additional hold time after the first frame, none by default.
  final Duration minDuration;

  static const Duration fadeDuration = Duration(milliseconds: 150);

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
    final reveal = pendingWindowReveal;
    if (reveal == null) {
      _startTimer();
    } else {
      unawaited(reveal.then((_) => _startTimer()));
    }
  }

  void _startTimer() {
    if (!mounted) return;
    if (widget.minDuration > Duration.zero) {
      _timer = Timer(widget.minDuration, _fadeOut);
      return;
    }
    // Wait for the loader frame to be on screen, then fade out right away.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeOut());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _fadeOut() {
    if (!mounted || _fading) return;
    setState(() => _fading = true);
    _timer = Timer(LoaderGate.fadeDuration, () {
      if (mounted) setState(() => _visible = false);
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
