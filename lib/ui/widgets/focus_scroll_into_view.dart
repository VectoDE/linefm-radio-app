import 'package:flutter/widgets.dart';

/// Scrolls the element that gets keyboard focus into view.
///
/// Flutter's traversal scrolls only when it moves focus itself. Entering a
/// group from another one (for example Tab from the navigation rail into an
/// already scrolled list) focuses an entry outside the viewport and leaves
/// the list where it is. This listens to focus changes in keyboard mode and
/// calls [Scrollable.ensureVisible] for the focused element, for every
/// scrollable screen.
class FocusScrollIntoView extends StatefulWidget {
  const FocusScrollIntoView({super.key, required this.child});

  final Widget child;

  @override
  State<FocusScrollIntoView> createState() => _FocusScrollIntoViewState();
}

class _FocusScrollIntoViewState extends State<FocusScrollIntoView> {
  FocusNode? _last;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final node = FocusManager.instance.primaryFocus;
    if (node == null || identical(node, _last)) return;
    _last = node;
    // Pointer and touch focus stays where the user put it.
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }
    final target = node.context;
    if (target == null || !target.mounted) return;
    if (Scrollable.maybeOf(target) == null) return;
    // Instant: no extra motion for keyboard users.
    Scrollable.ensureVisible(target);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
