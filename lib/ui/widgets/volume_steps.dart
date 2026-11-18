import 'package:material_ui/material_ui.dart';

/// Lautstaerke in 10 Stufen, Semantics als Slider. Platzhalter, P04.
class VolumeSteps extends StatelessWidget {
  const VolumeSteps({super.key, required this.volume, required this.onChanged});

  /// 0.1 bis 1.0.
  final double volume;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) =>
      Slider(value: volume, min: 0.1, divisions: 9, onChanged: onChanged);
}
