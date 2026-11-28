part of '../shell.dart';

/// Bottom navigation: STATIONS (play) · PLAYER (headphones) · HISTORY
/// (clock-rotate-left) · FAVORITES (heart). Same destinations and order as
/// the side rail, plus the player, which is always visible when wide. The
/// settings sit in the header at every width.
class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.screen});

  final AppScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final items = <(AppScreen, FaIconData, String)>[
      (AppScreen.stations, FontAwesomeIcons.play, l10n.navStations),
      (AppScreen.player, FontAwesomeIcons.headphones, l10n.navPlayer),
      (AppScreen.history, FontAwesomeIcons.clockRotateLeft, l10n.navHistory),
      (AppScreen.favorites, FontAwesomeIcons.heart, l10n.navFavorites),
    ];
    final favorites = ref.watch(favoritesProvider.select((f) => f.length));
    // Landmark and name are set by the shell (_ordered).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: const ValueKey<String>('shell-bottom-nav'),
        decoration: BoxDecoration(
          color: c.navBg,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Padding(
          // Narrow margin: four destinations fit from 360 dp without a shrunken
          // label.
          padding: EdgeInsets.fromLTRB(
            LinefmSpace.sm,
            0,
            LinefmSpace.sm,
            bottom,
          ),
          child: SizedBox(
            height: LinefmMetrics.navHeight,
            child: Row(
              children: <Widget>[
                for (final (target, icon, label) in items)
                  Expanded(
                    child: _NavItem(
                      icon: icon,
                      label: target == AppScreen.favorites && favorites > 0
                          ? l10n.favoritesButtonCount(favorites)
                          : label,
                      text: label,
                      badge: target == AppScreen.favorites ? favorites : 0,
                      selected: screen == target,
                      onTap: () =>
                          ref.read(navigationProvider.notifier).go(target),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation entry: pill indicator behind the icon like in the
/// side rail, hover surface and visible focus ring (2 dp, accent).
/// Fixed height: the label is shrunk, never wrapped, so the
/// bar stays the same height in every language.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final FaIconData icon;

  /// Name for the screen reader (with the count for favorites).
  final String label;

  /// Visible label.
  final String text;

  /// Counter on the icon, 0 hides it.
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    final color = selected ? c.accent : c.muted;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        // excludeSemantics also discards the InkResponse's tap action; without
        // its own onTap the bar could not be operated with a screen reader
        // (web: click on the button had no effect, found with tool/a11y).
        onTap: onTap,
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LinefmSpace.xs,
          vertical: LinefmSpace.sm,
        ),
        child: FocusRing(
          offset: 0,
          child: InkResponse(
            onTap: onTap,
            containedInkWell: true,
            highlightShape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
            hoverColor: c.accent.withValues(alpha: 0.08),
            // Focus is shown by the ring, not by a surface.
            focusColor: Colors.transparent,
            // Full cell width: tap target, hover and ring do not depend
            // on the length of the label.
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedContainer(
                    key: selected
                        ? const ValueKey<String>('nav-indicator')
                        : null,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : LinefmMetrics.fast,
                    width: LinefmMetrics.navIndicatorWidth,
                    height: LinefmMetrics.navIndicatorHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? c.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        LinefmMetrics.radiusPill,
                      ),
                    ),
                    child: _NavIcon(icon: icon, badge: badge, color: color),
                  ),
                  const SizedBox(height: LinefmSpace.xs),
                  // Shrink instead of hiding if a language is longer
                  // than the fixed space.
                  // Flexible bounds the height too: at large text scale the
                  // label shrinks instead of overflowing the fixed bar.
                  // The side inset keeps a visible gap between neighbouring
                  // labels even when large system text shrinks them to the
                  // full cell width.
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LinefmSpace.xs,
                      ),
                      child: FittedBox(
                        key: const ValueKey<String>('nav-label'),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text.toUpperCase(),
                          maxLines: 1,
                          softWrap: false,
                          style: LinefmText.nav.copyWith(color: color),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- Notice bars

/// Navigation icon with an optional counter (favorites), from 100 "99+".
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.badge = 0, this.color});

  final FaIconData icon;
  final int badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return Badge(
      isLabelVisible: badge > 0,
      backgroundColor: c.accent,
      textColor: c.onAccent,
      label: Text(badge > 99 ? '99+' : '$badge'),
      child: FaIcon(icon, size: LinefmMetrics.navIcon, color: color),
    );
  }
}
