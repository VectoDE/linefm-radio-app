part of '../shell.dart';

/// Header of the web app: word mark "LINEFM" (Syncopate 2rem) on the left,
/// on the right favorites heart with counter and gear. On the player without
/// background and with a text color chosen by contrast to the station gradient.
class _Header extends ConsumerWidget {
  const _Header({required this.transparent, this.inset = true});

  final bool transparent;

  /// Take the status bar into account (compact layout, header above content).
  final bool inset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final top = inset ? MediaQuery.paddingOf(context).top : 0.0;
    final gutter = PageInsets.gutter(context);
    final gearEnd = math.max(
      0.0,
      gutter - (LinefmMetrics.minTarget - LinefmMetrics.navIcon) / 2,
    );
    final station = ref.watch(activeStationProvider);
    final onSettings = ref.watch(navigationProvider) == AppScreen.settings;
    final tint = transparent
        ? StationStyle.onPlayerTop(
            station.color,
            c,
            Theme.of(context).brightness,
          )
        : c.text;

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : LinefmMetrics.fast,
      height: top + LinefmMetrics.headerHeight,
      // Same left edge as the page content; the gear glyph ends on the
      // content's right edge (its 48 dp target overhangs into the margin).
      padding: EdgeInsets.fromLTRB(gutter, top, gearEnd, 0),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : c.background,
        boxShadow: transparent
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: c.headerShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: <Widget>[
          // Takes the space left of the buttons and scales the brand name
          // down instead of overflowing at large text scales.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                header: true,
                headingLevel: 2,
                container: true,
                label: l10n.brandName,
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.brandName,
                    style: LinefmText.brandHeader.copyWith(color: tint),
                  ),
                ),
              ),
            ),
          ),
          // Favorites live in the navigation; the header keeps only the
          // gear so no destination appears twice.
          QuietTooltip(
            message: l10n.settingsButton,
            child: IconButton(
              onPressed: () {
                final nav = ref.read(navigationProvider.notifier);
                if (ref.read(navigationProvider) == AppScreen.settings) {
                  nav.back();
                } else {
                  nav.go(AppScreen.settings);
                }
              },
              isSelected: onSettings,
              icon: FaIcon(
                FontAwesomeIcons.gear,
                size: LinefmMetrics.navIcon,
                color: onSettings && !transparent ? c.accent : tint,
                semanticLabel: l10n.settingsButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- Navigation
