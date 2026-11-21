import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/favorites/favorite_actions.dart';
import 'package:linefm_radio/features/favorites/favorites_export_sheet.dart';
import 'package:linefm_radio/features/favorites/favorites_import_action.dart';
import 'package:linefm_radio/features/history/icon_action.dart';
import 'package:linefm_radio/features/history/list_screen.dart';
import 'package:linefm_radio/features/history/stagger_in.dart';
import 'package:linefm_radio/features/history/track_row.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Screen "Favoriten": gemerkte Songs (neueste zuerst) mit Papierkorb zum
/// Entfernen, Import und Export (CSV/Text) und Leerzustand. Meldet
/// `screen_favorites`, `favorite_remove` und `export_favorites`.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(telemetryProvider).screen('favorites'));
  }

  /// Entfernt sofort und bietet 5 s lang "Rueckgaengig" an (U3).
  void _removeWithUndo(Favorite favorite, int index) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final expanded = WindowClass.of(context) == WindowClass.expanded;
    // Kompakt: ueber Mini-Player und Navigation, nicht darauf (U6).
    final bottom = expanded
        ? 16.0
        : MediaQuery.paddingOf(context).bottom + LinefmMetrics.navHeight + 102;
    removeFavoriteWithTelemetry(ref, favorite);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            LinefmSpace.lg,
            0,
            LinefmSpace.lg,
            bottom,
          ),
          duration: const Duration(seconds: 5),
          content: Text(l10n.favoritesRemoved(favorite.title)),
          action: SnackBarAction(
            label: l10n.actionUndo,
            onPressed: () =>
                ref.read(favoritesProvider.notifier).restore(favorite, index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final marquee = ref.watch(settingsProvider.select((s) => s.marquee));

    return ListScreen(
      title: l10n.favoritesTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconAction(
            icon: FontAwesomeIcons.fileImport,
            label: l10n.favoritesImport,
            onPressed: () => unawaited(startFavoritesImport(context, ref)),
          ),
          if (favorites.isNotEmpty)
            IconAction(
              icon: FontAwesomeIcons.fileExport,
              label: l10n.favoritesExport,
              onPressed: () => unawaited(startFavoritesExport(context, ref)),
            ),
        ],
      ),
      itemCount: favorites.length,
      emptyState: Padding(
        padding: const EdgeInsets.only(top: LinefmSpace.xs),
        child: Text(
          l10n.favoritesEmpty,
          style: LinefmText.listTitle.copyWith(
            color: context.linefm.muted,
            fontSize: LinefmType.body,
          ),
        ),
      ),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return StaggerIn(
          key: ValueKey<String>('fav-${favorite.key}'),
          index: index,
          child: _FavoriteRow(
            favorite: favorite,
            marquee: marquee,
            removeLabel: l10n.favoritesRemove(favorite.title),
            onRemoved: () => _removeWithUndo(favorite, index),
          ),
        );
      },
    );
  }
}

/// Zeile mit Papierkorb. Beim Entfernen faehrt die Zeile in 180 ms zu und
/// blendet aus, danach wird der Favorit gespeichert geloescht (bei
/// `disableAnimations` sofort).
class _FavoriteRow extends StatefulWidget {
  const _FavoriteRow({
    required this.favorite,
    required this.marquee,
    required this.removeLabel,
    required this.onRemoved,
  });

  final Favorite favorite;
  final bool marquee;
  final String removeLabel;
  final VoidCallback onRemoved;

  @override
  State<_FavoriteRow> createState() => _FavoriteRowState();
}

class _FavoriteRowState extends State<_FavoriteRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LinefmMetrics.fast,
    value: 1,
  );
  bool _removing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_removing) return;
    _removing = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _controller.reverse();
    }
    widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) {
    final favorite = widget.favorite;
    final Station station =
        stationBySlug(favorite.stationSlug) ?? stationsCatalog.first;
    final row = TrackRow(
      station: station,
      title: favorite.title,
      artist: favorite.artist,
      coverUrl: favorite.artworkUrl ?? favorite.stationLogoUrl,
      marquee: widget.marquee,
      semanticLabel: favorite.artist.isEmpty
          ? favorite.title
          : '${favorite.title}, ${favorite.artist}',
      trailing: IconAction(
        icon: FontAwesomeIcons.trashCan,
        label: widget.removeLabel,
        onPressed: () => unawaited(_remove()),
      ),
    );
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(opacity: _controller, child: row),
    );
  }
}
