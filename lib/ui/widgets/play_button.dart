import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Play/Verbinden/Stop-Knopf (`fa-circle-play`, Spinner, `fa-circle-stop`).
///
/// - [PlayerStatus.playing] zeigt Stop, `idle`/`error` Play,
///   `connecting`/`reconnecting` einen Spinner (Knopf dann deaktiviert, die
///   Mindestdauer von 1 s steuert der Controller, nicht das Widget).
/// - Die Icons wechseln mit kurzer Skalier-/Blendanimation (180 ms), der Knopf
///   skaliert bei Hover (Desktop, 1,05) und Druck (0,94) und zeigt bei
///   Tastaturfokus den Fokusring.
/// - Die Tippflaeche ist mindestens 48 dp gross.
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.status,
    required this.onPressed,
    this.size = 66,
    this.color,
    this.labelPlay = 'Play',
    this.labelConnecting = 'Connecting',
    this.labelStop = 'Stop',
  });

  final PlayerStatus status;
  final VoidCallback? onPressed;

  /// Durchmesser: Player 66, Mini-Player 70, Mini-Player Handy 56.
  final double size;

  /// Iconfarbe. Standard `accent`; auf Senderverlauf `onPlayerBody` setzen.
  final Color? color;

  /// Beschriftungen fuer Screenreader (lokalisiert vom Aufrufer, Web-Wortlaut:
  /// "Stream starten", "Stream wird verbunden", "Stream stoppen").
  final String labelPlay;
  final String labelConnecting;
  final String labelStop;

  bool get _busy =>
      status == PlayerStatus.connecting || status == PlayerStatus.reconnecting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LinefmColors>()!;
    final fg = color ?? colors.accent;
    final playing = status == PlayerStatus.playing;
    final label = _busy ? labelConnecting : (playing ? labelStop : labelPlay);
    final iconSize = size * 45 / 66;
    final spinnerSize = size * 30 / 66;
    final hit = size < LinefmMetrics.minTarget ? LinefmMetrics.minTarget : size;

    final Widget glyph = _busy
        ? SizedBox.square(
            key: const ValueKey<String>('connecting'),
            dimension: spinnerSize,
            child: CircularProgressIndicator(strokeWidth: 3, color: fg),
          )
        : FaIcon(
            playing ? FontAwesomeIcons.circleStop : FontAwesomeIcons.circlePlay,
            key: ValueKey<bool>(playing),
            size: iconSize,
            color: fg,
          );

    return SemanticFocus(
      builder: (context, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        enabled: onPressed != null && !_busy,
        label: label,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        excludeSemantics: true,
        onTap: _busy ? null : onPressed,
        child: child,
      ),
      child: FocusRing(
        borderRadius: hit / 2,
        shape: BoxShape.circle,
        child: _Pressable(
          onPressed: _busy ? null : onPressed,
          size: hit,
          child: AnimatedSwitcher(
            duration: LinefmMetrics.fast,
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: glyph,
          ),
        ),
      ),
    );
  }
}

/// Runder Knopf mit Hover- und Druck-Skalierung und Tastaturbedienung.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onPressed,
    required this.size,
    required this.child,
  });

  final VoidCallback? onPressed;
  final double size;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = reduce ? 1.0 : (_down ? 0.94 : (_hover ? 1.05 : 1.0));
    return SizedBox.square(
      dimension: widget.size,
      child: InkResponse(
        onTap: widget.onPressed,
        onHover: (v) => setState(() => _hover = v),
        onHighlightChanged: (v) => setState(() => _down = v),
        radius: widget.size / 2,
        highlightColor: Colors.transparent,
        child: AnimatedScale(
          scale: scale,
          duration: LinefmMetrics.fast,
          curve: Curves.easeOut,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
