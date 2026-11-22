import 'dart:async';

import 'package:flutter/gestures.dart' show PointerEnterEvent, PointerExitEvent;
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Hinweisblase fuer Maus (Hover) und Touch (Langdruck), ganz ohne
/// Semantik.
///
/// Warum nicht `Tooltip`: Der Material-Tooltip haengt seine Blase per
/// `OverlayPortal` ein. Flutter gibt ihr damit immer einen eigenen
/// Semantik-Knoten (auch mit `excludeFromSemantics`) und verknuepft ihn im
/// Web per `aria-owns` mit dem Knopf. Verschwindet die Blase, bleibt das
/// Attribut stehen und zeigt ins Leere: axe meldet `aria-valid-attr-value`
/// (kritisch), solange sie sichtbar ist ausserdem `region`.
///
/// Hier liegt die Blase in einem eigenen [OverlayEntry] ohne Bezug zum Knopf,
/// eingehuellt in [ExcludeSemantics]. Der Knopf traegt sein Label selbst
/// (eigene `Semantics` oder `semanticLabel`). Aussehen und Wartezeit kommen
/// aus dem [TooltipTheme].
///
/// WCAG 1.4.13 (Inhalt bei Hover oder Fokus):
/// * schliessbar: Escape blendet die Blase aus, ohne den Fokus zu bewegen;
/// * hoverbar: Die Blase bleibt stehen, solange der Mauszeiger auf ihr liegt;
/// * dauerhaft: Sie bleibt, bis Zeiger oder Fokus gehen oder Escape kommt.
/// Bei Tastaturfokus (nicht bei Fokus durch Tippen) erscheint sie ebenfalls.
/// Der Fokus-Rahmen um das Kind hat keine eigene Semantik.
///
/// Der Baum um das Kind ist immer gleich (auch bei leerer Meldung), damit
/// ein Wechsel der Meldung den Zustand des Kindes (Fokus, Ripple) nicht
/// verwirft. Escape faengt die Blase nur ab, solange sie sichtbar ist; sonst
/// erreicht die Taste Dialoge und Routen wie gewohnt. Die Blase blendet in
/// [fadeDuration] ein, bei reduzierter Bewegung sofort.
class QuietTooltip extends StatefulWidget {
  const QuietTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<QuietTooltip> createState() => _QuietTooltipState();
}

/// Einblenddauer der Blase (WCAG 2.3.3: kurz, abschaltbar).
const Duration fadeDuration = Duration(milliseconds: 120);

class _QuietTooltipState extends State<QuietTooltip> {
  static const Duration _touchShowDuration = Duration(milliseconds: 1500);
  static const Duration _exitDelay = Duration(milliseconds: 100);

  OverlayEntry? _entry;
  Timer? _timer;
  bool _keyHandlerAdded = false;

  @override
  void didUpdateWidget(QuietTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      if (widget.message.isEmpty) {
        _hideNow();
      } else {
        _entry?.markNeedsBuild();
      }
    }
  }

  @override
  void deactivate() {
    _hideNow();
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideNow();
    super.dispose();
  }

  void _schedule(Duration delay, VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (mounted) action();
    });
  }

  void _onEnter(PointerEnterEvent _) {
    final wait = TooltipTheme.of(context).waitDuration ?? Duration.zero;
    _schedule(wait, _show);
  }

  void _onExit(PointerExitEvent _) => _schedule(_exitDelay, _hideNow);

  /// Zeiger auf der Blase: nicht ausblenden (hoverbar).
  void _onBubbleEnter(PointerEnterEvent _) => _timer?.cancel();

  void _onFocusChange(bool focused) {
    if (focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional) {
      _timer?.cancel();
      _show();
    } else if (!focused) {
      _hideNow();
    }
  }

  bool _onKey(KeyEvent event) {
    if (_entry != null &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _hideNow();
      return true;
    }
    return false;
  }

  void _onLongPress() {
    _show();
    _schedule(_touchShowDuration, _hideNow);
  }

  void _show() {
    if (_entry != null || widget.message.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final box = context.findRenderObject() as RenderBox?;
    if (overlay == null || box == null || !box.hasSize) return;
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final targetRect =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final theme = TooltipTheme.of(context);
    final textStyle = theme.textStyle ?? Theme.of(context).textTheme.bodyMedium;
    _entry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: ExcludeSemantics(
          child: CustomSingleChildLayout(
            delegate: _BubbleLayout(
              target: targetRect,
              verticalOffset: theme.verticalOffset ?? 24,
              preferBelow: theme.preferBelow ?? true,
            ),
            // Nur die Blase selbst nimmt den Zeiger an (der Rest des
            // Overlays laesst ihn durch), damit sie beim Hover stehen bleibt.
            child: MouseRegion(
              onEnter: _onBubbleEnter,
              onExit: _onExit,
              child: _Fade(
                duration:
                    MediaQuery.maybeDisableAnimationsOf(overlayContext) ?? false
                    ? Duration.zero
                    : fadeDuration,
                child: DecoratedBox(
                  decoration: theme.decoration ?? const BoxDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LinefmSpace.sm,
                      vertical: LinefmSpace.xs,
                    ),
                    // Overlay ohne Material: eigener Textstil, sonst zeichnet
                    // Flutter die gelbe Unterstreichung fuer fehlende Stile.
                    child: DefaultTextStyle(
                      style: (textStyle ?? const TextStyle()).copyWith(
                        decoration: TextDecoration.none,
                      ),
                      child: Text(widget.message),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    if (!_keyHandlerAdded) {
      HardwareKeyboard.instance.addHandler(_onKey);
      _keyHandlerAdded = true;
    }
  }

  void _hideNow() {
    _timer?.cancel();
    if (_keyHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      _keyHandlerAdded = false;
    }
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Immer derselbe Aufbau; bei leerer Meldung zeigt `_show` nichts.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _onFocusChange,
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: _onLongPress,
          excludeFromSemantics: true,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Einblenden der Blase; [Duration.zero] zeigt sie sofort.
class _Fade extends StatelessWidget {
  const _Fade({required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}

/// Blase unter (oder ueber) dem Ziel, mittig, im Overlay gehalten.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout({
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  });

  final Rect target;
  final double verticalOffset;
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => positionDependentBox(
    size: size,
    childSize: childSize,
    target: target.center,
    verticalOffset: verticalOffset,
    preferBelow: preferBelow,
  );

  @override
  bool shouldRelayout(_BubbleLayout oldDelegate) =>
      target != oldDelegate.target ||
      verticalOffset != oldDelegate.verticalOffset ||
      preferBelow != oldDelegate.preferBelow;
}
