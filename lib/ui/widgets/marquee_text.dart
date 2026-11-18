import 'package:material_ui/material_ui.dart';

/// Lauftext nur bei Ueberlaenge. Platzhalter, P04.
class MarqueeText extends StatelessWidget {
  const MarqueeText(this.text, {super.key, this.style, this.enabled = true});

  final String text;
  final TextStyle? style;
  final bool enabled;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
}
