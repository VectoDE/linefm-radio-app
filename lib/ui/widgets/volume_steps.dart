import 'package:flutter/services.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:material_ui/material_ui.dart';

/// Lautstaerke in 10 Stufen (10 % bis 100 %) wie das Popover der Web-App
/// (`.volume-steps`: 10 Balken, 8 dp hoch, 4 dp Abstand).
///
/// - Tippen und Ziehen waehlen die Stufe an der Fingerposition, oben ist
///   100 %.
/// - Tastatur: Pfeil hoch/rechts/Bild hoch = lauter, runter/links/Bild runter
///   = leiser, Pos1 = 100 %, Ende = 10 %.
/// - Screenreader: ein einziges Slider-Element mit Wert "70 Prozent" sowie
///   Erhoehen/Verringern.
/// - Stufenwechsel geben leichtes haptisches Feedback.
class VolumeSteps extends StatelessWidget {
  const VolumeSteps({
    super.key,
    required this.volume,
    required this.onChanged,
    this.axis = Axis.vertical,
    this.semanticLabel = 'Volume',
    this.valueLabel,
    this.color,
  });

  static const int steps = 10;
  static const double stepThickness = 8;
  static const double stepGap = 4;
  static const double crossExtent = 28;

  /// 0.1 bis 1.0.
  final double volume;
  final ValueChanged<double> onChanged;

  /// Vertikal (Popover, oben = laut) oder horizontal (links = leise).
  final Axis axis;

  /// Beschriftung des Sliders (lokalisiert vom Aufrufer).
  final String semanticLabel;

  /// Wert fuer Screenreader aus der Prozentzahl, z. B. "Lautstaerke 70
  /// Prozent". Standard: "70 %".
  final String Function(int percent)? valueLabel;

  /// Farbe der gefuellten Stufen. Standard `accent`.
  final Color? color;

  /// Aktuelle Stufe 1 bis 10.
  int get level => (volume * steps).round().clamp(1, steps);

  static double volumeForLevel(int level) =>
      level.clamp(1, steps) / steps.toDouble();

  void _setLevel(int next) {
    final clamped = next.clamp(1, steps);
    if (clamped == level) return;
    HapticFeedback.selectionClick();
    onChanged(volumeForLevel(clamped));
  }

  int _levelAt(Offset local, Size size) {
    final fraction = axis == Axis.vertical
        ? 1 - (local.dy / size.height)
        : local.dx / size.width;
    return (fraction.clamp(0.0, 1.0) * steps).ceil().clamp(1, steps);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LinefmColors>()!;
    final fill = color ?? colors.accent;
    final empty = fill.withValues(alpha: 0.2);
    final percent = level * 10;
    String label(int p) => valueLabel?.call(p) ?? '$p %';
    final text = label(percent);
    const extent = steps * stepThickness + (steps - 1) * stepGap;
    final vertical = axis == Axis.vertical;
    final size = vertical
        ? const Size(crossExtent, extent)
        : const Size(extent, crossExtent);

    // Vertikal oben = 100 %, horizontal links = 10 %.
    final content = vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            spacing: stepGap,
            children: <Widget>[
              for (var i = steps; i >= 1; i--) _step(i, fill, empty, vertical),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: stepGap,
            children: <Widget>[
              for (var i = 1; i <= steps; i++) _step(i, fill, empty, vertical),
            ],
          );

    return Semantics(
      slider: true,
      label: semanticLabel,
      value: text,
      increasedValue: label((level + 1).clamp(1, steps) * 10),
      decreasedValue: label((level - 1).clamp(1, steps) * 10),
      onIncrease: () => _setLevel(level + 1),
      onDecrease: () => _setLevel(level - 1),
      excludeSemantics: true,
      child: FocusRing(
        borderRadius: LinefmMetrics.radiusLogo,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
            SingleActivator(LogicalKeyboardKey.pageUp): _StepIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
            SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
            SingleActivator(LogicalKeyboardKey.pageDown): _StepIntent(-1),
            SingleActivator(LogicalKeyboardKey.home): _StepIntent(steps),
            SingleActivator(LogicalKeyboardKey.end): _StepIntent(-steps),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _StepIntent: CallbackAction<_StepIntent>(
                onInvoke: (intent) {
                  _setLevel(level + intent.delta);
                  return null;
                },
              ),
            },
            child: Focus(
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => _setLevel(_levelAt(d.localPosition, size)),
                  onVerticalDragUpdate: vertical
                      ? (d) => _setLevel(_levelAt(d.localPosition, size))
                      : null,
                  onHorizontalDragUpdate: vertical
                      ? null
                      : (d) => _setLevel(_levelAt(d.localPosition, size)),
                  child: SizedBox.fromSize(
                    size: size,
                    child: Center(child: content),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int index, Color fill, Color empty, bool vertical) {
    final filled = index <= level;
    return AnimatedContainer(
      duration: LinefmMetrics.fast,
      curve: Curves.easeOut,
      width: vertical ? crossExtent - 16 : stepThickness,
      height: vertical ? stepThickness : crossExtent - 16,
      decoration: BoxDecoration(
        color: filled ? fill : empty,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _StepIntent extends Intent {
  const _StepIntent(this.delta);
  final int delta;
}
