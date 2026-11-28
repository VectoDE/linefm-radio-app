import 'package:material_ui/material_ui.dart';

/// Mutes every ticker below it while the app is not visible.
///
/// When the window is minimized or the app is in the background
/// ([AppLifecycleState.hidden], [AppLifecycleState.paused],
/// [AppLifecycleState.detached]) nothing on screen can change for the user,
/// so continuous animations (loader dots, playing bars, progress spinners)
/// must not keep scheduling frames. [AppLifecycleState.inactive] keeps
/// tickers running: an unfocused desktop window is still visible.
class LifecycleTickerMode extends StatefulWidget {
  const LifecycleTickerMode({super.key, required this.child});

  final Widget child;

  /// Whether content is visible in [state]. A null state (before the engine
  /// reported one, e.g. in tests) counts as visible.
  static bool isVisible(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  @override
  State<LifecycleTickerMode> createState() => _LifecycleTickerModeState();
}

class _LifecycleTickerModeState extends State<LifecycleTickerMode> {
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      final visible = LifecycleTickerMode.isVisible(state);
      if (visible != _visible) setState(() => _visible = visible);
    },
  );

  bool _visible = LifecycleTickerMode.isVisible(
    WidgetsBinding.instance.lifecycleState,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: _visible, child: widget.child);
}
