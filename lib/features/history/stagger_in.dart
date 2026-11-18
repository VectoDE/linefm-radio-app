import 'package:material_ui/material_ui.dart';

/// Einblend-Animation fuer Listenzeilen: Einblenden mit leichtem Hochgleiten,
/// jede Zeile um [stepMs] Millisekunden versetzt (Web-App: 40 ms je Eintrag).
///
/// Laeuft nur einmal beim ersten Aufbau der Zeile. Bei der System-Einstellung
/// `disableAnimations` erscheint die Zeile sofort. Der Versatz ist auf
/// [maxSteps] Zeilen begrenzt, damit lange Listen nicht traege wirken.
class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
    this.stepMs = 40,
    this.maxSteps = 10,
  });

  final int index;
  final Widget child;
  final int stepMs;
  final int maxSteps;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  static const int _durationMs = 280;

  late final int _delayMs =
      (widget.index < widget.maxSteps ? widget.index : widget.maxSteps) *
      widget.stepMs;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _durationMs + _delayMs),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delayMs / (_durationMs + _delayMs),
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * 8),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
