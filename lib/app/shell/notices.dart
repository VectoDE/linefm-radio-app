part of '../shell.dart';

/// Area for notices (offline, storage, autoplay). A landmark only while a
/// notice is actually shown; otherwise there would be an empty region.
class _NoticesRegion extends ConsumerWidget {
  const _NoticesRegion({required this.compact, required this.child});

  /// Compact layout: the autoplay bar takes the mini player's space and lets
  /// the storage notice wait (see [_StorageNoticeSlot]).
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = !(ref.watch(onlineProvider).value ?? true);
    final blocked = ref.watch(autoplayBlockedProvider);
    final player = ref.watch(navigationProvider) == AppScreen.player;
    final storage =
        ref.watch(platformInfoProvider).isWeb &&
        !ref.watch(storageConsentProvider) &&
        !(compact && blocked && !player);
    final visible = offline || storage || (!compact && blocked);
    if (!visible) return child;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.region,
      label: AppLocalizations.of(context).regionNotices,
      child: child,
    );
  }
}

/// Storage notice banner (web only) at the bottom above mini player and
/// navigation (16 dp margin, max. 760 dp wide).
class _StorageNoticeSlot extends ConsumerWidget {
  const _StorageNoticeSlot({this.yieldToAutoplay = false});

  /// Hide while the autoplay bar is shown (compact layout).
  final bool yieldToAutoplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmed = ref.watch(storageConsentProvider);
    // Banner only in the browser; app and desktop show a popup (gate).
    if (confirmed || !ref.watch(platformInfoProvider).isWeb) {
      return const SizedBox.shrink();
    }
    if (yieldToAutoplay &&
        ref.watch(autoplayBlockedProvider) &&
        ref.watch(navigationProvider) != AppScreen.player) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: StorageNotice(),
    );
  }
}

/// "No connection. LINEFM keeps trying." (spec 4.2 no. 14).
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(760, width)),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    FaIcon(FontAwesomeIcons.wifi, size: 13, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.offlineBanner,
                        style: LinefmText.notice.copyWith(color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
