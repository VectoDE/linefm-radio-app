part of '../shell.dart';

/// Web autoplay block (spec 2.2): a start without a prior user action
/// (autoplay, alarm, link) would have stayed silent. The bar explains this
/// and starts the chosen station with the click as the user action.
///
/// Only the hint text is a live region; the button is its own regular
/// button without an enclosing semantics node.
class AutoplayStartButton extends ConsumerWidget {
  const AutoplayStartButton({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(autoplayBlockedProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final station = ref.watch(activeStationProvider);
    final button = FilledButton.icon(
      key: const ValueKey<String>('autoplay-start'),
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(0, LinefmMetrics.minTarget),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const StadiumBorder(),
        textStyle: LinefmText.listTitle.copyWith(fontWeight: FontWeight.w600),
      ),
      onPressed: () => unawaited(
        ref
            .read(playerControllerProvider)
            .startStation(ref.read(activeStationProvider)),
      ),
      icon: const FaIcon(FontAwesomeIcons.play, size: 16),
      label: Text(l10n.autoplayBlockedStart),
    );
    final hint = Semantics(
      container: true,
      liveRegion: true,
      child: Text(
        l10n.autoplayBlockedHint(station.displayName),
        style: LinefmText.notice.copyWith(color: c.text),
      ),
    );
    // Below 360 dp the button moves under the text, so the hint keeps the
    // full width instead of wrapping into four lines beside the button.
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
            ),
            child: narrow
                ? Padding(
                    padding: const EdgeInsets.all(LinefmSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            LinefmSpace.xs,
                            0,
                            LinefmSpace.xs,
                            LinefmSpace.sm,
                          ),
                          child: hint,
                        ),
                        button,
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: hint),
                        const SizedBox(width: 10),
                        button,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
