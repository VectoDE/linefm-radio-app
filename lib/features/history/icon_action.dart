import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Runder Icon-Knopf mit 48 dp Tippflaeche (WCAG 2.5.8), Tastaturfokus-Ring,
/// Hover-Hervorhebung und Screenreader-Beschriftung. [toggled] markiert
/// Umschalter (Herz "Song merken").
class IconAction extends StatefulWidget {
  const IconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.hoverColor,
    this.toggled,
    this.iconSize = 18,
    this.tooltip = true,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Ruhefarbe, Standard `muted`.
  final Color? color;

  /// Farbe bei Hover/Fokus, Standard `text`.
  final Color? hoverColor;

  /// Null = normaler Knopf, sonst Umschalter mit diesem Zustand.
  final bool? toggled;
  final double iconSize;
  final bool tooltip;

  @override
  State<IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<IconAction> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    final lit = _hover || _focus;
    final color = lit
        ? (widget.hoverColor ?? c.text)
        : (widget.color ?? c.muted);

    Widget button = FocusRing(
      shape: BoxShape.circle,
      offset: 0,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: widget.onPressed,
          onHover: (v) => setState(() => _hover = v),
          onFocusChange: (v) => setState(() => _focus = v),
          radius: LinefmMetrics.minTarget / 2,
          containedInkWell: false,
          child: SizedBox.square(
            dimension: LinefmMetrics.minTarget,
            child: Center(
              child: AnimatedSwitcher(
                duration: LinefmMetrics.fast,
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: FaIcon(
                  widget.icon,
                  key: ValueKey<Object>('${widget.icon.codePoint}-$color'),
                  size: widget.iconSize,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip) {
      button = QuietTooltip(message: widget.label, child: button);
    }

    // Umschalter wie `SettingsSwitch`: Schalter-Rolle (toggled), KEINE
    // zusaetzliche Knopf-Rolle, eigener Knoten mit Tipp-Aktion. Beides
    // zusammen (button + toggled) wurde von Screenreadern/Web-Semantik nicht
    // als Schalter aktiviert; nur der Mausklick griff.
    final isToggle = widget.toggled != null;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: !isToggle,
        toggled: widget.toggled,
        enabled: true,
        label: widget.label,
        onTap: widget.onPressed,
        excludeSemantics: true,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: button,
    );
  }
}
