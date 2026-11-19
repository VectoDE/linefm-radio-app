import 'package:material_ui/material_ui.dart';

/// Gibt einem [AlertDialog] (oder [Dialog]) einen zugaenglichen Namen.
///
/// `Dialog` legt den Knoten mit `role: alertDialog` an, das Label aus
/// `AlertDialog.semanticLabel` landet aber auf einem inneren Routen-Knoten.
/// Die Web-Engine setzt `aria-label` am `role="alertdialog"` nur, wenn genau
/// dieser Knoten `namesRoute` und ein Label traegt; sonst meldet axe
/// `aria-dialog-name` (serious). Dieser Rahmen ergaenzt beides am Rollen-Knoten.
class NamedDialog extends StatelessWidget {
  const NamedDialog({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(label: label, namesRoute: true, child: child);
}
