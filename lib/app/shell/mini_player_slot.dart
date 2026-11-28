part of '../shell.dart';

/// Compact layout: in the mini player's place the start bar is shown when
/// autoplay is blocked. That way it covers no card and the content
/// stays visible even at 320 x 640.
class _MiniPlayerOrStart extends ConsumerWidget {
  const _MiniPlayerOrStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(autoplayBlockedProvider);
    final player = ref.watch(navigationProvider) == AppScreen.player;
    if (blocked && !player) {
      return const AutoplayStartButton(
        padding: EdgeInsets.symmetric(horizontal: 12),
      );
    }
    return const MiniPlayerSlot();
  }
}
