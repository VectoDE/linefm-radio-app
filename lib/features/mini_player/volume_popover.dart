import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/volume_steps.dart';
import 'package:material_ui/material_ui.dart';

/// Lautstaerke-Knopf mit Popover (`.mini-volume` der Web-App): Tippen oeffnet
/// ueber dem Knopf eine senkrechte Leiste mit 10 Stufen, Tippen daneben oder
/// Esc schliesst sie wieder. Die Lautstaerke kommt aus `playerStateProvider`
/// und wird ueber `playerControllerProvider` gesetzt.
class VolumeButton extends ConsumerStatefulWidget {
  const VolumeButton({super.key, this.color = Colors.white});

  /// Farbe von Icon und gefuellten Stufen.
  final Color color;

  @override
  ConsumerState<VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends ConsumerState<VolumeButton> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _open = false;

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _portal.show() : _portal.hide();
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final volume = ref.watch(
      playerStateProvider.select((s) => s.value?.volume ?? 1.0),
    );
    final icon = volume <= 0.3
        ? FontAwesomeIcons.volumeLow
        : FontAwesomeIcons.volumeHigh;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) =>
            _Popover(link: _link, color: widget.color, onClose: _close),
        child: Semantics(
          button: true,
          expanded: _open,
          label: _open ? l10n.volumeClose : l10n.volumeOpen,
          excludeSemantics: true,
          onTap: _toggle,
          child: FocusRing(
            borderRadius: 24,
            shape: BoxShape.circle,
            child: SizedBox.square(
              dimension: LinefmMetrics.minTarget,
              child: InkResponse(
                onTap: _toggle,
                radius: 24,
                child: Center(
                  child: FaIcon(icon, size: 21, color: widget.color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Popover extends ConsumerWidget {
  const _Popover({
    required this.link,
    required this.color,
    required this.onClose,
  });

  final LayerLink link;
  final Color color;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final volume = ref.watch(
      playerStateProvider.select((s) => s.value?.volume ?? 1.0),
    );
    final reduce = MediaQuery.disableAnimationsOf(context);

    final bar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(15, 18, 33, 0.95),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusPopover),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.12)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.35),
            blurRadius: 35,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: VolumeSteps(
        volume: volume,
        color: color,
        semanticLabel: l10n.volumeLabel,
        valueLabel: (p) => l10n.volumePercent(p),
        onChanged: (v) => ref.read(playerControllerProvider).setVolume(v),
      ),
    );

    return Stack(
      children: <Widget>[
        // Tippen neben das Popover schliesst es.
        Positioned.fill(
          child: Semantics(
            label: l10n.volumeClose,
            button: true,
            onTap: onClose,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onClose,
            ),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0, -14),
          showWhenUnlinked: false,
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): onClose,
            },
            child: Focus(
              autofocus: true,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: reduce ? 1 : 0, end: 1),
                duration: LinefmMetrics.fast,
                curve: Curves.easeOut,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 8),
                    child: child,
                  ),
                ),
                child: UnconstrainedBox(child: bar),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
