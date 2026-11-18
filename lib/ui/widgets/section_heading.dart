import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Abschnittsueberschrift in Syncopate. Platzhalter, P04.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: LinefmFonts.brand,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  );
}
