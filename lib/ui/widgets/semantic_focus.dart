import 'package:flutter/widgets.dart';

/// Baut einen eigenen Semantik-Knoten fuer ein Bedienelement, dessen
/// Kinder per `excludeSemantics` ausgeblendet sind (Karte, Play-Knopf,
/// Mini-Player, Links), und reicht dabei den Tastaturfokus weiter.
///
/// `excludeSemantics` entfernt auch das Fokus-Flag des inneren InkWell. Ohne
/// Ausgleich bekommt das Element im Web kein `tabindex`, und das DOM folgt
/// dem Flutter-Fokus nicht (Screenreader bleiben stehen, A11Y-02). Der
/// [builder] erhaelt deshalb:
///
/// - `focused`: Ein Element im Teilbaum hat den Tastaturfokus. In
///   `Semantics(focused: ...)` gesetzt, verschiebt Flutter Web den DOM-Fokus
///   auf diesen Knoten.
/// - `onFocus`: Fuer `Semantics(onFocus: ...)`. Setzt der Screenreader oder
///   der Browser den Fokus auf den Knoten, bekommt ihn das erste fokussierbare
///   Element im Teilbaum.
/// - `child`: der Teilbaum, umschlossen von einem Beobachter des Fokus.
///
/// Die Semantik selbst setzt der Aufrufer, zusammen mit `focusable: true`.
class SemanticFocus extends StatefulWidget {
  const SemanticFocus({super.key, required this.builder, required this.child});

  final Widget Function(
    BuildContext context,
    bool focused,
    VoidCallback onFocus,
    Widget child,
  )
  builder;

  final Widget child;

  @override
  State<SemanticFocus> createState() => _SemanticFocusState();
}

class _SemanticFocusState extends State<SemanticFocus> {
  final FocusNode _node = FocusNode(
    debugLabel: 'semantic-focus',
    canRequestFocus: false,
    skipTraversal: true,
  );
  bool _focused = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  void _onFocusChange(bool value) {
    if (!mounted || value == _focused) return;
    setState(() => _focused = value);
  }

  void _focusFirst() {
    for (final node in _node.descendants) {
      if (node.canRequestFocus && !node.skipTraversal) {
        node.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _focused,
    _focusFirst,
    Focus(
      focusNode: _node,
      includeSemantics: false,
      onFocusChange: _onFocusChange,
      child: widget.child,
    ),
  );
}
