import 'dart:async';
import 'dart:math' as math;

import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Lauftext wie `setMarqueeText` der Web-App.
///
/// - Passt der Text in die Breite, steht er still (optional zentriert).
/// - Nur bei Ueberlaenge laeuft er als Endlosband mit einer Kopie und
///   [LinefmMetrics.marqueeGap] Abstand, ein Durchlauf dauert 18 s.
/// - [enabled] false (Einstellung "Lauftext") oder System-Einstellung
///   `disableAnimations` zeigen statisch mit Auslassungspunkten.
/// - Das Band blendet an den Raendern weich aus, Screenreader lesen den Text
///   genau einmal.
class MarqueeText extends StatelessWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.loopDuration = LinefmMetrics.marqueeLoop,
    this.gap = LinefmMetrics.marqueeGap,
    this.bandInset = 0,
  });

  final String text;
  final TextStyle? style;

  /// Wert der Einstellung "Lauftext fuer lange Titel".
  final bool enabled;

  /// Ausrichtung, solange der Text nicht ueberlaeuft.
  final TextAlign textAlign;

  final Duration loopDuration;
  final double gap;

  /// Seitlicher Innenabstand nur fuer das laufende Band: Es blendet dann
  /// innerhalb dieses Abstands aus statt an der Kante des Elternelements.
  /// Text, der passt, nutzt weiter die volle Breite.
  final double bandInset;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: effective),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        final height = painter.height;
        painter.dispose();
        final available = constraints.maxWidth;
        final overflows =
            available.isFinite && textWidth > available + 1 && text.isNotEmpty;
        if (!overflows || !enabled || reduce) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          );
        }
        return Semantics(
          label: text,
          excludeSemantics: true,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: bandInset),
            child: SizedBox(
              height: height,
              child: _Band(
                text: text,
                style: style,
                cycle: textWidth + gap,
                gap: gap,
                duration: loopDuration,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Band extends StatefulWidget {
  const _Band({
    required this.text,
    required this.style,
    required this.cycle,
    required this.gap,
    required this.duration,
  });

  final String text;
  final TextStyle? style;
  final double cycle;
  final double gap;
  final Duration duration;

  @override
  State<_Band> createState() => _BandState();
}

/// One timer for all running bands.
///
/// Every band advancing on its own timer would each trigger a frame at its
/// own moment, so several bands on screen add up to a frame on nearly every
/// vsync. The shared clock ticks once for all of them, at the rate of the
/// fastest band (one physical pixel per tick, at most one tick per display
/// frame), and each band only rebuilds when its pixel position changed.
class _MarqueeClock {
  _MarqueeClock._();

  static final _MarqueeClock instance = _MarqueeClock._();

  static const int _minPeriodMicros = 16667;

  final Set<_BandState> _bands = <_BandState>{};
  Timer? _timer;
  int _periodMicros = 0;

  /// Time the clock has run, advanced in whole ticks.
  int elapsedMicros = 0;

  void add(_BandState band) {
    if (_bands.add(band)) _retime();
  }

  void remove(_BandState band) {
    if (_bands.remove(band)) _retime();
  }

  void _retime() {
    if (_bands.isEmpty) {
      _timer?.cancel();
      _timer = null;
      _periodMicros = 0;
      return;
    }
    final period = math.max(
      _minPeriodMicros,
      _bands.map((band) => band.pixelPeriodMicros).reduce(math.min),
    );
    if (period == _periodMicros && _timer != null) return;
    _timer?.cancel();
    _periodMicros = period;
    _timer = Timer.periodic(Duration(microseconds: period), (_) {
      elapsedMicros += _periodMicros;
      for (final band in _bands.toList()) {
        band.tick();
      }
    });
  }
}

/// Moves the band in whole physical pixels on the shared [_MarqueeClock].
///
/// A ticker would rebuild the band on every vsync although the text only
/// moves a fraction of a pixel per frame (one loop of 18 s over a few hundred
/// pixels is roughly 20 px per second).
///
/// The band holds still, and schedules nothing, while it cannot be seen:
/// app not in the foreground, tickers muted ([TickerMode], e.g. hidden routes
/// or the desktop mini window) or the band scrolled out of its viewport
/// (cards kept alive in the cache area of a list).
class _BandState extends State<_Band> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (_) => _syncRunning(),
  );

  bool _running = false;

  /// Time this band has moved, kept across pauses.
  int _movedMicros = 0;

  /// Clock time at which [_movedMicros] was zero, while running.
  int _clockBase = 0;

  /// Current position in physical pixels within one loop.
  int _pixel = 0;

  double _pixelRatio = 1;

  ScrollPosition? _scroll;
  bool _tickersEnabled = true;
  bool _onScreen = true;
  bool _visibilityCheckPending = false;

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    final scroll = Scrollable.maybeOf(context)?.position;
    if (!identical(scroll, _scroll)) {
      _scroll?.removeListener(_onScroll);
      _scroll = scroll?..addListener(_onScroll);
    }
    _restart();
    // Visibility needs layout; check once this frame is laid out.
    _onScroll();
  }

  @override
  void didUpdateWidget(_Band old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration || old.cycle != widget.cycle) {
      _restart();
    }
  }

  @override
  void dispose() {
    _stop();
    _scroll?.removeListener(_onScroll);
    _lifecycle.dispose();
    super.dispose();
  }

  /// Physical pixels in one loop.
  int get _loopPixels => math.max(1, (widget.cycle * _pixelRatio).round());

  /// Time for one physical pixel.
  int get pixelPeriodMicros =>
      math.max(1, widget.duration.inMicroseconds ~/ _loopPixels);

  // Scroll notifications arrive before the new layout; measure after it.
  void _onScroll() {
    if (_visibilityCheckPending) return;
    _visibilityCheckPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckPending = false;
      if (!mounted) return;
      final visible = _computeOnScreen();
      if (visible != _onScreen) {
        _onScreen = visible;
        _syncRunning();
      }
    });
  }

  bool _computeOnScreen() {
    final box = context.findRenderObject();
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return true;
    if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize) {
      return true;
    }
    final mine = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    final view = MatrixUtils.transformRect(
      viewport.getTransformTo(null),
      Offset.zero & viewport.size,
    );
    return mine.overlaps(view);
  }

  bool get _shouldRun {
    final state = WidgetsBinding.instance.lifecycleState;
    final foreground = state == null || state == AppLifecycleState.resumed;
    return foreground && _tickersEnabled && _onScreen;
  }

  void _syncRunning() {
    if (!mounted) return;
    final run = _shouldRun;
    if (run && !_running) {
      _running = true;
      _clockBase = _MarqueeClock.instance.elapsedMicros - _movedMicros;
      _MarqueeClock.instance.add(this);
    } else if (!run && _running) {
      _stop();
    }
  }

  void _stop() {
    if (!_running) return;
    _running = false;
    _movedMicros = _MarqueeClock.instance.elapsedMicros - _clockBase;
    _MarqueeClock.instance.remove(this);
  }

  void _restart() {
    _pixelRatio = MediaQuery.devicePixelRatioOf(context);
    _stop();
    _syncRunning();
  }

  /// Called by the clock: rebuild only when the pixel position changed.
  void tick() {
    if (!mounted) return;
    final moved = _MarqueeClock.instance.elapsedMicros - _clockBase;
    final micros = math.max(1, widget.duration.inMicroseconds);
    final pixel = (moved % micros) * _loopPixels ~/ micros;
    if (pixel != _pixel) setState(() => _pixel = pixel);
  }

  @override
  Widget build(BuildContext context) {
    final copy = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
    );
    final offset = -_pixel / _pixelRatio;
    return RepaintBoundary(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: <Color>[
            LinefmPalette.clearWhite,
            LinefmPalette.paper,
            LinefmPalette.paper,
            LinefmPalette.clearWhite,
          ],
          stops: <double>[0, 0.04, 0.96, 1],
        ).createShader(rect),
        child: ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.centerStart,
            minWidth: 0,
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  copy,
                  SizedBox(width: widget.gap),
                  copy,
                  SizedBox(width: widget.gap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
