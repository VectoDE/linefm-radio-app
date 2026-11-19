import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/desktop_strings.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';
import 'package:material_ui/material_ui.dart';

/// Mini-Fenster 360x120 (Spec 2.2, 4.3): Cover, Titel/Kuenstler, Play/Stop,
/// Sender weiter und zurueck, "immer im Vordergrund" und zurueck zum grossen
/// Fenster. Rahmenlos, die ganze Flaeche zieht das Fenster. Esc oeffnet das
/// normale Fenster wieder.
class MiniPlayerWindow extends ConsumerWidget {
  const MiniPlayerWindow({super.key});

  static const double width = 360;
  static const double height = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = DesktopController.instance;
    final colors = Theme.of(context).extension<LinefmColors>()!;
    final strings = DesktopStrings.forLocale(Localizations.localeOf(context));
    final station = ref.watch(activeStationProvider);
    final status =
        ref.watch(playerStateProvider).value?.status ?? PlayerStatus.idle;
    final track = ref.watch(currentTrackProvider).value;
    final title = track?.title ?? station.displayName;
    final subtitle = track?.artist ?? '';

    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            CoverImage(station: station, url: track?.artworkUrl, size: 96),
            const SizedBox(width: 12),
            Expanded(
              child: _Info(
                station: station,
                title: title,
                subtitle: subtitle,
                status: status,
                strings: strings,
                colors: colors,
              ),
            ),
          ],
        ),
      ),
    );

    // Eigenes Overlay: das Mini-Fenster liegt ueber dem Navigator der App,
    // Tooltips der Knoepfe brauchen aber eines.
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            unawaited(desktop.exitMini()),
      },
      child: Focus(
        autofocus: true,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (context) =>
                  Material(type: MaterialType.transparency, child: content),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info({
    required this.station,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.strings,
    required this.colors,
  });

  final Station station;
  final String title;
  final String subtitle;
  final PlayerStatus status;
  final DesktopStrings strings;
  final LinefmColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = DesktopController.instance;
    final l10n = strings.l10n;
    final controller = ref.read(playerControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          station.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(color: colors.muted),
        ),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colors.tickerText),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: desktop.dragArea(SizedBox.expand(child: text))),
        Row(
          children: <Widget>[
            _MiniButton(
              icon: Icons.skip_previous,
              tooltip: l10n.playerPrevious,
              onPressed: () => unawaited(desktop.stepStation(-1)),
            ),
            PlayButton(
              status: status,
              size: 40,
              onPressed: () => unawaited(controller.togglePlayback()),
              labelPlay: l10n.playerStart,
              labelConnecting: l10n.playerConnecting,
              labelStop: l10n.playerStop,
            ),
            _MiniButton(
              icon: Icons.skip_next,
              tooltip: l10n.playerNext,
              onPressed: () => unawaited(desktop.stepStation(1)),
            ),
            const Spacer(),
            ValueListenableBuilder<bool>(
              valueListenable: desktop.alwaysOnTop,
              builder: (context, onTop, _) => _MiniButton(
                icon: onTop ? Icons.push_pin : Icons.push_pin_outlined,
                tooltip: strings.alwaysOnTop,
                onPressed: () => unawaited(desktop.toggleAlwaysOnTop()),
              ),
            ),
            _MiniButton(
              icon: Icons.open_in_full,
              tooltip: l10n.trayShowWindow,
              onPressed: () => unawaited(desktop.exitMini()),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LinefmColors>()!;
    return IconButton(
      icon: Icon(icon, size: 20),
      color: colors.accent,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}
