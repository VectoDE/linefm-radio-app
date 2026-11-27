import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/app/stations_provider.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/features/stations/favorite_stations.dart';
import 'package:linefm_radio/features/stations/station_actions.dart';
import 'package:linefm_radio/features/stations/station_card.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:material_ui/material_ui.dart';

/// Ticker text "Artist - Title" (empty if no title is known).
String tickerFor(StationLive live) {
  final track = live.track;
  return track == null ? '' : '${track.artist} - ${track.title}';
}

/// Screen "All stations" (spec 4.1).
///
/// - Compact (< 600 dp): list. Medium and wide: grid with 2 columns, from
///   1200 dp window width 3 columns (web: >= 760 px 2, >= 1000 px 3).
/// - The list lives in code; the tickers come from `stationsProvider` and
///   stay empty as long as no title info is available. If the fetch fails,
///   a notice appears below the heading.
/// - Pull to refresh, long-press on a card opens the menu
///   "Share station".
/// - The star on each card remembers the station as a favorite station
///   (separate from the song favorites).
class StationsScreen extends ConsumerWidget {
  const StationsScreen({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      LinefmSpace.gutter,
      0,
      LinefmSpace.gutter,
      LinefmSpace.xl,
    ),
  });

  /// Outer padding. The shell adds the header at the top and mini player
  /// and navigation at the bottom.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.linefm;
    final live = ref.watch(stationsProvider);
    final active = ref.watch(activeStationProvider);
    final playing = ref.watch(
      playerStateProvider.select((s) => s.value?.isPlaying ?? false),
    );
    final marquee = ref.watch(settingsProvider.select((s) => s.marquee));
    final favoriteSlugs = ref.watch(favoriteStationsProvider);
    final favoriteStations = ref.watch(favoriteStationListProvider);

    final tracks = <String, StationLive>{
      for (final item in live.value ?? const <StationLive>[])
        item.station.slug: item,
    };
    final offline = live.hasError;

    final windowClass = WindowClass.of(context);
    final grid = windowClass != WindowClass.compact;
    final columns = MediaQuery.sizeOf(context).width >= 1200 ? 3 : 2;

    Widget card(Station station) {
      final item = tracks[station.slug];
      final ticker = item == null ? '' : tickerFor(item);
      final favorite = favoriteSlugs.contains(station.slug);
      final label = ticker.isEmpty
          ? l10n.stationCardLabelIdle(station.displayName)
          : l10n.stationCardLabel(station.displayName, ticker);
      return StationCard(
        station: station,
        ticker: ticker,
        active: station == active,
        playing: playing,
        grid: grid,
        marquee: marquee,
        semanticLabel: favorite
            ? '$label, ${l10n.stationFavoriteBadge}'
            : label,
        longPressLabel: l10n.stationLongPressShare,
        favorite: favorite,
        favoriteLabel: favorite
            ? l10n.stationFavoriteRemove(station.displayName)
            : l10n.stationFavoriteAdd(station.displayName),
        onToggleFavorite: () =>
            ref.read(favoriteStationsProvider.notifier).toggle(station),
        onTap: () => ref.openStation(context, station),
        onLongPress: () => _showMenu(context, ref, station),
      );
    }

    Widget section(List<Station> list) {
      if (grid) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 196 * math.max(1, scale * 0.9),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => card(list[i]),
            childCount: list.length,
          ),
        );
      }
      return SliverList.separated(
        itemCount: list.length,
        separatorBuilder: (context, i) =>
            const SizedBox(height: LinefmSpace.sm),
        itemBuilder: (context, i) => card(list[i]),
      );
    }

    // Favorite stations (star) at the top as their own group, only if any
    // are remembered. The full list below stays complete.
    final hasFavorites = favoriteStations.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(nowPlayingRepositoryProvider).refresh(),
      color: colors.accent,
      backgroundColor: colors.surfaceRaised,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: padding,
            sliver: SliverMainAxisGroup(
              slivers: <Widget>[
                if (hasFavorites) ...<Widget>[
                  SliverToBoxAdapter(child: SectionHeading(l10n.stationsYours)),
                  SliverSemantics(
                    container: true,
                    label: l10n.stationsYoursListLabel,
                    sliver: section(favoriteStations),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
                SliverToBoxAdapter(
                  child: SectionHeading(
                    l10n.stationsTitle,
                    headingLevel: hasFavorites ? 2 : 1,
                    padding: EdgeInsets.only(
                      bottom: offline ? LinefmSpace.xs : LinefmSpace.md,
                    ),
                  ),
                ),
                if (offline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: LinefmSpace.lg),
                      child: Semantics(
                        liveRegion: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                                right: LinefmSpace.sm,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.wifi,
                                size: 12,
                                color: colors.muted,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                l10n.stationsOffline,
                                style: LinefmText.listMeta.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverSemantics(
                  container: true,
                  label: l10n.stationsListLabel,
                  sliver: section(ref.watch(stationsCatalogProvider)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Station station,
  ) async {
    final l10n = AppLocalizations.of(context);
    final colors = context.linefm;
    final share = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      showDragHandle: true,
      builder: (context) => NamedSheet(
        label: station.displayName,
        child: SafeArea(
          child: ListTile(
            leading: FaIcon(FontAwesomeIcons.shareNodes, color: colors.text),
            title: Text(
              l10n.stationLongPressShare,
              style: LinefmText.listTitle,
            ),
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
      ),
    );
    if (share != true) return;
    final url = stationShareUrl(
      ref.read(appConfigProvider).webBaseUrl,
      station,
    );
    await ref.read(stationShareFnProvider)(
      l10n.stationShareText(station.displayName, url),
    );
  }
}
