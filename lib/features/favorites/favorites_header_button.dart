import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Herz im Header mit Zaehler-Badge (`.favorites-button` + `.favorite-count`).
/// Das Badge zeigt die Anzahl gespeicherter Favoriten, ab 100 "99+", und ist
/// bei 0 ausgeblendet. Screenreader: "Favoriten, N Songs". Tippen oeffnet den
/// Favoriten-Screen. [color] erlaubt helle Schrift auf Senderverlauf (Player).
class FavoritesHeaderButton extends ConsumerWidget {
  const FavoritesHeaderButton({super.key, this.color, this.onPressed});

  final Color? color;

  /// Standard: `navigationProvider.go(AppScreen.favorites)`.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final count = ref.watch(favoritesProvider.select((f) => f.length));
    final tint = color ?? c.text;
    final label = count == 0
        ? l10n.favoritesButton
        : l10n.favoritesButtonCount(count);

    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: () => _open(ref),
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: FocusRing(
        shape: BoxShape.circle,
        offset: 0,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: () => _open(ref),
            radius: LinefmMetrics.minTarget / 2,
            containedInkWell: false,
            child: SizedBox.square(
              dimension: LinefmMetrics.minTarget,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.heart, size: 18, color: tint),
                  if (count > 0)
                    Positioned(
                      top: 6,
                      right: 4,
                      child: _CountBadge(count: count),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(WidgetRef ref) {
    if (onPressed != null) {
      onPressed!();
    } else {
      ref.read(navigationProvider.notifier).go(AppScreen.favorites);
    }
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            widthFactor: 1,
            child: Text(
              count > 99 ? '99+' : '$count',
              maxLines: 1,
              style: TextStyle(
                color: c.onAccent,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
