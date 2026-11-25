import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Custom title bar of the setup window, the same on Windows, macOS and
/// Linux (#88, design of the app's bar from #87: 40 dp, logo, name, window
/// buttons on the right, 46 x 40 like Windows 11). The native title bar is
/// hidden by the runners. The setup window has a fixed size, so it offers
/// minimize and close only (no maximize, no double-click zoom).
abstract final class SetupTitleBarMetrics {
  static const double height = 40;
  static const double buttonWidth = 46;
  static const double logoSize = 20;
  static const Color closeHover = Color(0xFFC42B1C);
  static const Color closePressed = Color(0xE6C42B1C);
  static const Color onClose = Color(0xFFFFFFFF);
}

class SetupTitleBar extends StatelessWidget {
  const SetupTitleBar({
    super.key,
    required this.title,
    required this.minimizeLabel,
    required this.closeLabel,
    required this.onDragStart,
    required this.onMinimize,
    required this.onClose,
  });

  final String title;
  final String minimizeLabel;
  final String closeLabel;
  final VoidCallback onDragStart;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: SetupTitleBarMetrics.height,
        child: ColoredBox(
          color: c.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Listener(
                  // The whole bar except the buttons moves the window.
                  onPointerDown: (event) {
                    if (event.buttons == kPrimaryButton) onDragStart();
                  },
                  child: Semantics(
                    header: true,
                    label: title,
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: SetupTitleBarMetrics.logoSize,
                              height: SetupTitleBarMetrics.logoSize,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.text,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SetupCaptionButton(
                close: false,
                label: minimizeLabel,
                onPressed: onMinimize,
              ),
              SetupCaptionButton(
                close: true,
                label: closeLabel,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Window button with the app's states: hover 8 %, pressed 12 %, close red
/// with white glyph, keyboard focus ring inside, screen reader button.
class SetupCaptionButton extends StatefulWidget {
  const SetupCaptionButton({
    super.key,
    required this.close,
    required this.label,
    required this.onPressed,
  });

  final bool close;
  final String label;
  final VoidCallback onPressed;

  @override
  State<SetupCaptionButton> createState() => _SetupCaptionButtonState();
}

class _SetupCaptionButtonState extends State<SetupCaptionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color background;
    final Color foreground;
    if (widget.close && (_hovered || _pressed)) {
      background = _pressed
          ? SetupTitleBarMetrics.closePressed
          : SetupTitleBarMetrics.closeHover;
      foreground = SetupTitleBarMetrics.onClose;
    } else if (_pressed) {
      background = c.text.withValues(alpha: 0.12);
      foreground = c.text;
    } else if (_hovered) {
      background = c.text.withValues(alpha: 0.08);
      foreground = c.text;
    } else {
      background = const Color(0x00000000);
      foreground = c.text;
    }
    return Semantics(
      container: true,
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        excludeFromSemantics: true,
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed();
                return null;
              },
            ),
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Listener(
              onPointerDown: (event) {
                if (event.buttons == kPrimaryButton) {
                  setState(() => _pressed = true);
                }
              },
              onPointerUp: (_) => setState(() => _pressed = false),
              onPointerCancel: (_) => setState(() => _pressed = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onPressed,
                excludeFromSemantics: true,
                child: SizedBox(
                  width: SetupTitleBarMetrics.buttonWidth,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      border: _focused
                          ? Border.all(color: c.accent, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: ColoredBox(
                      color: background,
                      child: Center(
                        child: CustomPaint(
                          size: const Size.square(10),
                          painter: _GlyphPainter(
                            close: widget.close,
                            color: foreground,
                            dpr: MediaQuery.devicePixelRatioOf(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glyphs like Segoe Fluent (Windows 11), 10 x 10, 1 device pixel lines.
class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.close, required this.color, required this.dpr});

  final bool close;
  final Color color;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final px = 1 / dpr;
    final stroke = dpr.round().clamp(1, 4) * px;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final s = size.width;
    if (close) {
      canvas
        ..drawLine(Offset.zero, Offset(s, s), paint)
        ..drawLine(Offset(s, 0), Offset(0, s), paint);
    } else {
      final y = (s / 2 / px).round() * px + stroke / 2;
      canvas.drawLine(Offset(0, y), Offset(s, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.close != close || old.color != color || old.dpr != dpr;
}
