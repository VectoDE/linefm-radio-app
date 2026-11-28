part of '../shell.dart';

class _ExpandedLayout extends ConsumerWidget {
  const _ExpandedLayout({required this.screen});

  final AppScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final width = MediaQuery.sizeOf(context).width;
    final playerWidth = (width * 0.34).clamp(380.0, 460.0);
    final shown = screen == AppScreen.player ? AppScreen.stations : screen;
    const railScreens = <AppScreen>[
      AppScreen.stations,
      AppScreen.history,
      AppScreen.favorites,
    ];
    final index = railScreens.indexOf(shown);
    final favorites = ref.watch(favoritesProvider.select((f) => f.length));

    // Tab and screen reader order like the visuals: navigation, header,
    // content, notices, player. Without a fixed order the header came
    // only after the cards.
    return SafeArea(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ordered(
              1,
              role: SemanticsRole.navigation,
              label: l10n.navMain,
              Semantics(
                container: true,
                explicitChildNodes: true,
                child: SizedBox(
                  key: const ValueKey<String>('shell-rail'),
                  width: LinefmMetrics.railWidth,
                  // The first destination sits on the center line of the header, the
                  // word mark stays in the header.
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: LinefmMetrics.railTopInset,
                    ),
                    child: NavigationRail(
                      minWidth: LinefmMetrics.railWidth,
                      selectedIndex: index < 0 ? null : index,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -1,
                      onDestinationSelected: (i) => ref
                          .read(navigationProvider.notifier)
                          .go(railScreens[i]),
                      destinations: <NavigationRailDestination>[
                        _railItem(FontAwesomeIcons.play, l10n.navStations),
                        _railItem(
                          FontAwesomeIcons.clockRotateLeft,
                          l10n.navHistory,
                        ),
                        _railItem(
                          FontAwesomeIcons.heart,
                          l10n.navFavorites,
                          badge: favorites,
                          semanticLabel: favorites > 0
                              ? l10n.favoritesButtonCount(favorites)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: c.line),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ordered(
                    2,
                    role: SemanticsRole.region,
                    label: l10n.regionHeader,
                    const _Header(transparent: false, inset: false),
                  ),
                  Expanded(
                    child: _ordered(
                      3,
                      role: SemanticsRole.main,
                      _content(
                        shown,
                        stationsPadding: const EdgeInsets.fromLTRB(
                          PageInsets.expanded,
                          LinefmSpace.gutter,
                          PageInsets.expanded,
                          LinefmSpace.xxl,
                        ),
                      ),
                    ),
                  ),
                  // In the flow below the content instead of an overlay: covers
                  // nothing and does not lie over the whole app.
                  _ordered(
                    4,
                    const _NoticesRegion(
                      compact: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AutoplayStartButton(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          ),
                          _OfflineBanner(),
                          _StorageNoticeSlot(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: playerWidth,
              child: _ordered(
                5,
                role: SemanticsRole.complementary,
                label: l10n.navPlayer,
                const PlayerScreen(embedded: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static NavigationRailDestination _railItem(
    FaIconData icon,
    String label, {
    int badge = 0,
    String? semanticLabel,
  }) => NavigationRailDestination(
    // The counter is part of the spoken name (semanticLabel), not a separate
    // "1" read before the destination.
    icon: ExcludeSemantics(
      child: _NavIcon(icon: icon, badge: badge),
    ),
    // Fixed width: long words (e.g. "EINSTELLUNGEN") are shrunk
    // instead of widening the bar or being cut off. The screen reader
    // always reads the full text.
    label: Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: SizedBox(
        width: LinefmMetrics.railWidth - 16,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

// -------------------------------------------------------------- Header
