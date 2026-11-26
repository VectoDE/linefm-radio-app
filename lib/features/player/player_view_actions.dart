part of 'player_view.dart';

/// Shuffle, Play/Stop, Herz wie in der Web-App.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.data,
    required this.strings,
    required this.color,
    required this.onShuffle,
    required this.onTogglePlayback,
    required this.onToggleFavorite,
  });

  final PlayerViewData data;
  final PlayerStrings strings;
  final Color color;
  final VoidCallback onShuffle;
  final VoidCallback onTogglePlayback;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final hasTrack = data.track != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _IconAction(
          label: strings.shuffle,
          onPressed: onShuffle,
          color: color.withValues(alpha: 0.8),
          child: FaIcon(
            FontAwesomeIcons.shuffle,
            size: 24,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 26),
        PlayButton(
          status: data.status,
          onPressed: onTogglePlayback,
          color: color,
          labelPlay: strings.start,
          labelConnecting: strings.connecting,
          labelStop: strings.stop,
        ),
        const SizedBox(width: 26),
        _IconAction(
          label: data.isFavorite ? strings.favoriteRemove : strings.favoriteAdd,
          onPressed: hasTrack ? onToggleFavorite : null,
          color: color,
          child: AnimatedSwitcher(
            duration: LinefmMetrics.fast,
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: FaIcon(
              data.isFavorite
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.heart,
              key: ValueKey<bool>(data.isFavorite),
              size: 25,
              color: color.withValues(alpha: hasTrack ? 0.9 : 0.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({
    required this.data,
    required this.strings,
    required this.color,
    required this.onShare,
    required this.onOpenMusicLinks,
    required this.castSlot,
    required this.airPlaySlot,
    this.onSleepTimer,
    this.sleepTimerActive = false,
  });

  final VoidCallback? onSleepTimer;
  final bool sleepTimerActive;
  final PlayerViewData data;
  final PlayerStrings strings;
  final Color color;
  final VoidCallback onShare;
  final VoidCallback onOpenMusicLinks;
  final Widget? castSlot;
  final Widget? airPlaySlot;

  @override
  Widget build(BuildContext context) {
    final hasTrack = data.track != null;
    final border = color.withValues(alpha: 0.32);
    // Abstand nur um sichtbare Elemente: Cast- und AirPlay-Slot sind ohne
    // Geraet leer (SizedBox.shrink) und duerfen die Mitte nicht verschieben.
    Widget gap(Widget child) => SlotGap(child: child);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (hasTrack)
          gap(
            _PillAction(
              label: strings.openSongIn,
              icon: FontAwesomeIcons.music,
              color: color,
              border: border,
              onPressed: onOpenMusicLinks,
            ),
          ),
        if (hasTrack)
          gap(
            _IconAction(
              label: strings.shareSong,
              onPressed: onShare,
              color: color,
              border: border,
              child: FaIcon(
                FontAwesomeIcons.shareNodes,
                size: 18,
                color: color,
              ),
            ),
          ),
        if (onSleepTimer != null)
          gap(
            _IconAction(
              label: strings.sleepTimer,
              onPressed: onSleepTimer,
              color: color,
              border: sleepTimerActive ? color : border,
              child: Icon(
                sleepTimerActive ? Icons.bedtime : Icons.bedtime_outlined,
                size: 20,
                color: color,
              ),
            ),
          ),
        if (castSlot != null) gap(castSlot!),
        if (airPlaySlot != null) gap(airPlaySlot!),
      ],
    );
  }
}

/// Runder Symbolknopf mit mindestens 48 dp Tippflaeche, Tooltip (Desktop)
/// und Fokusring. Optional mit feinem Rand.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.label,
    required this.onPressed,
    required this.child,
    required this.color,
    this.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return QuietTooltip(
      message: label,
      child: SemanticFocus(
        builder: (_, focused, onFocus, child) => Semantics(
          container: true,
          button: true,
          enabled: onPressed != null,
          label: label,
          excludeSemantics: true,
          onTap: onPressed,
          focusable: true,
          focused: focused,
          onFocus: onFocus,
          child: child,
        ),
        child: FocusRing(
          shape: BoxShape.circle,
          borderRadius: LinefmMetrics.minTarget / 2,
          child: SizedBox.square(
            dimension: LinefmMetrics.minTarget,
            child: InkResponse(
              onTap: onPressed,
              radius: LinefmMetrics.minTarget / 2,
              highlightShape: BoxShape.circle,
              containedInkWell: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: border == null ? null : Border.all(color: border!),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abgerundete Schaltflaeche mit Symbol und Text (48 dp hoch).
class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.border,
    required this.onPressed,
  });

  final String label;
  final FaIconData icon;
  final Color color;
  final Color border;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // NEU-4: Eigener, fokussierbarer Semantik-Knoten wie bei _IconAction.
    // Ohne container/focusable gab es kein DOM-Element fuer den Knopf: Der
    // Tastaturfokus landete in Flutter auf dem InkWell, der Browser blieb aber
    // auf "Song merken" stehen (doppelter Tab-Stopp, Knopf fuer Screenreader
    // nicht erreichbar).
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onPressed,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: FocusRing(
        borderRadius: LinefmMetrics.minTarget / 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
          child: Container(
            height: LinefmMetrics.minTarget,
            padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.gutter),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FaIcon(icon, size: 15, color: color),
                const SizedBox(width: LinefmSpace.md),
                Text(
                  label,
                  style: LinefmText.listMeta.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
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
