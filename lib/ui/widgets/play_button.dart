import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:material_ui/material_ui.dart';

/// Play/Verbinden/Stop-Knopf mit Spinner. Platzhalter, P04.
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.status, required this.onPressed});

  final PlayerStatus status;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final busy =
        status == PlayerStatus.connecting ||
        status == PlayerStatus.reconnecting;
    return IconButton(
      iconSize: 56,
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const CircularProgressIndicator()
          : Icon(
              status == PlayerStatus.playing
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
            ),
    );
  }
}
