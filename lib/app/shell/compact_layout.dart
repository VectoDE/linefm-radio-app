part of '../shell.dart';

class _CompactLayout extends StatefulWidget {
  const _CompactLayout({required this.screen});

  final AppScreen screen;

  @override
  State<_CompactLayout> createState() => _CompactLayoutState();
}

class _CompactLayoutState extends State<_CompactLayout> {
  /// Measured height of the bottom stack (notices, mini player,
  /// navigation). The content keeps that much space free so that, for
  /// example, the storage notice does not cover player buttons.
  double _bottomStack = 0;

  void _onBottomStack(Size size) {
    if (!mounted || (size.height - _bottomStack).abs() < 0.5) return;
    setState(() => _bottomStack = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.screen;
    final padding = MediaQuery.paddingOf(context);
    final player = screen == AppScreen.player;
    final top = padding.top + LinefmMetrics.headerHeight;
    final bottom = math.max(
      padding.bottom + LinefmMetrics.navHeight + _miniReserve,
      _bottomStack + 12,
    );
    final reduce = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context);

    final Widget content;
    if (player) {
      content = PlayerScreen(
        embedded: false,
        bottomInset:
            math.max(padding.bottom + LinefmMetrics.navHeight, _bottomStack) +
            24,
      );
    } else {
      final inner = _content(
        screen,
        stationsPadding: EdgeInsets.fromLTRB(
          PageInsets.compact,
          LinefmSpace.gutter,
          PageInsets.compact,
          bottom,
        ),
      );
      content = Padding(
        padding: EdgeInsets.only(top: top),
        // Settings have no placeholder of their own at the bottom.
        child: screen == AppScreen.settings
            ? Padding(
                padding: EdgeInsets.only(bottom: bottom - 24),
                child: inner,
              )
            : inner,
      );
    }

    // Order for Tab and screen readers: header, content, notices,
    // mini player, navigation. No wrap-around: after the navigation Tab
    // leaves the app as usual.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _ordered(
              2,
              role: SemanticsRole.main,
              AnimatedSwitcher(
                duration: reduce ? Duration.zero : LinefmMetrics.fast,
                child: KeyedSubtree(
                  key: ValueKey<AppScreen>(screen),
                  child: content,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ordered(
              1,
              role: SemanticsRole.region,
              label: l10n.regionHeader,
              _Header(transparent: player),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SizeReporter(
              onSize: _onBottomStack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ordered(
                    3,
                    const _NoticesRegion(
                      compact: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _OfflineBanner(),
                          // Phone: only one notice at a time. While the start bar
                          // is shown, the storage notice waits so that content stays
                          // visible at 320 x 640.
                          _StorageNoticeSlot(yieldToAutoplay: true),
                        ],
                      ),
                    ),
                  ),
                  _ordered(
                    4,
                    role: player
                        ? SemanticsRole.none
                        : SemanticsRole.complementary,
                    label: player ? null : l10n.navPlayer,
                    const _MiniPlayerOrStart(),
                  ),
                  SizedBox(height: player ? 0 : 12),
                  _ordered(
                    5,
                    role: SemanticsRole.navigation,
                    label: l10n.navMain,
                    _BottomNav(screen: screen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reports the size of the child after each layout when it changes.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}

// --------------------------------------------------------------- Wide
