import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/now_playing.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
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

/// Ticker-Text "Artist - Titel" (leer, wenn kein Titel bekannt ist).
String tickerFor(StationLive live) {
  final track = live.track;
  return track == null ? '' : '${track.artist} - ${track.title}';
}

/// Screen "Alle Stationen" (Spec 4.1).
///
/// - Kompakt (< 600 dp): Liste. Mittel und breit: Raster mit 2 Spalten, ab
///   1200 dp Fensterbreite 3 Spalten (Web: >= 760 px 2, >= 1000 px 3).
/// - Die Liste steht im Code; die Ticker kommen aus `stationsProvider` und
///   bleiben leer, solange keine Titelinfos vorliegen. Faellt der Abruf aus,
///   steht ein Hinweis unter der Ueberschrift.
/// - Ziehen zum Aktualisieren, Long-Press auf eine Karte oeffnet das Menue
///   "Sender teilen".
/// - Der Stern auf jeder Karte merkt den Sender als Favoriten-Sender
///   (Issue #42, getrennt von den Song-Favoriten).
class StationsScreen extends ConsumerWidget {
  const StationsScreen({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  /// Aussenabstand. Die Shell ergaenzt oben den Header und unten Mini-Player
  /// und Navigation.
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
        separatorBuilder: (context, i) => const SizedBox(height: 9),
        itemBuilder: (context, i) => card(list[i]),
      );
    }

    // Favoriten-Sender (Stern) oben als eigene Gruppe, nur wenn welche
    // gemerkt sind (U4). Die Gesamtliste darunter bleibt vollstaendig.
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
                    padding: EdgeInsets.only(bottom: offline ? 10 : 20),
                  ),
                ),
                if (offline)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 8),
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
                  sliver: section(stationsCatalog),
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
