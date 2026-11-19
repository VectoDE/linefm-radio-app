import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Sichtbarer Tastatur-Fokusring wie in der Web-App (`outline: 2px solid
/// accent; outline-offset: 4px`). Erscheint nur bei Tastatur- und
/// Fernbedienungsnavigation (traditioneller Fokusmodus), nicht bei Touch oder
/// Mausklick. Der Ring wird ausserhalb des Kindes gezeichnet und aendert das
/// Layout nicht.
///
/// Kontrast des Rings (`accent` auf `background`): dunkel 18,6:1, hell 17,1:1.
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.borderRadius = LinefmMetrics.radiusCard,
    this.offset = 4,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final double borderRadius;
  final double offset;
  final BoxShape shape;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  bool get _visible =>
      _focused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).extension<LinefmColors>()!.accent;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focused = value),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          widget.child,
          if (_visible)
            Positioned.fill(
              left: -widget.offset,
              top: -widget.offset,
              right: -widget.offset,
              bottom: -widget.offset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: widget.shape,
                    borderRadius: widget.shape == BoxShape.circle
                        ? null
                        : BorderRadius.circular(
                            widget.borderRadius + widget.offset,
                          ),
                    border: Border.all(color: color, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
