import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/player/music_links_sheet.dart';
import 'package:linefm_radio/features/player/player_actions.dart';
import 'package:linefm_radio/features/player/player_strings.dart';
import 'package:linefm_radio/features/player/player_view.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/airplay_button.dart';
import 'package:linefm_radio/services/cast/cast_button.dart';
import 'package:linefm_radio/services/share/music_links.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Player-Screen der App. Liest die Provider, uebergibt Daten und Texte an
/// [PlayerView] und verdrahtet die Aktionen ([PlayerActions]).
///
/// - Handy/Tablet hochkant: eigener Screen unter dem Shell-Header, [embedded]
///   ist `false`, der obere Abstand haelt den Header frei.
/// - Breite Layouts (ab 840 dp): feste Spalte rechts. Dort setzt die Shell
///   [embedded] auf `true` (ohne Angabe gilt: Fensterklasse `expanded`).
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    this.embedded,
    this.topInset,
    this.bottomInset,
  });

  /// `null`: automatisch nach Fensterklasse.
  final bool? embedded;

  /// Abstaende fuer Header und Navigation. `null`: Standard (Header-Hoehe
  /// plus Statusleiste, Navigationshoehe plus Gestenleiste).
  final double? topInset;
  final double? bottomInset;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool get _isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    // Fehlerereignis, solange der Player offen ist (Spec 2.3 `error_stream`).
    // Weitere Quellen meldet der PlayerController.
    ref.listenManual<AsyncValue<PlayerUiState>>(playerStateProvider, (
      previous,
      next,
    ) {
      final was = previous?.value?.status;
      final now = next.value?.status;
      if (now == PlayerStatus.error && was != PlayerStatus.error) {
        ref.read(telemetryProvider).event('error_stream', <String, Object>{
          'station': ref.read(activeStationProvider).slug,
        }).ignore();
      }
    });
  }

  Future<void> _openMusicLinks(PlayerStrings strings, Track track) {
    final actions = ref.read(playerActionsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);

    Future<void> open(Future<Uri> Function() resolve) async {
      try {
        await actions.openUrl(await resolve());
      } on Object {
        messenger?.showSnackBar(SnackBar(content: Text(strings.linkOpenError)));
      }
    }

    return showMusicLinksSheet(
      context,
      title: strings.openSongIn,
      items: <MusicLinkItem>[
        MusicLinkItem(
          key: 'apple',
          label: strings.musicAppleMusic,
          icon: FontAwesomeIcons.apple,
          onOpen: () => open(() async {
            return await actions.appleMusicUri(track) ?? _appleSearch(track);
          }),
        ),
        MusicLinkItem(
          key: 'spotify',
          label: strings.musicSpotify,
          icon: FontAwesomeIcons.spotify,
          onOpen: () => open(() async => MusicLinks.spotify(track)),
        ),
        MusicLinkItem(
          key: 'youtube',
          label: strings.musicYouTubeMusic,
          icon: FontAwesomeIcons.youtube,
          onOpen: () => open(() async => MusicLinks.youtubeMusic(track)),
        ),
      ],
    );
  }

  /// Rueckfall, wenn iTunes keinen Treffer (und damit keinen Direktlink)
  /// liefert.
  static Uri _appleSearch(Track track) => Uri.https(
    'music.apple.com',
    '/search',
    <String, String>{'term': '${track.artist} ${track.title}'},
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final strings = PlayerStrings.of(l10n);
    final actions = ref.read(playerActionsProvider);

    final station = ref.watch(activeStationProvider);
    final playerState = ref.watch(playerStateProvider).value;
    final track = ref.watch(currentTrackProvider).value;
    final listeners = ref.watch(listenersProvider).value;
    final favorites = ref.watch(favoritesProvider);
    final marquee = ref.watch(settingsProvider.select((s) => s.marquee));

    final status =
        playerState == null ||
            (playerState.station != null && playerState.station != station)
        ? PlayerStatus.idle
        : playerState.status;
    final isFavorite =
        track != null &&
        FavoritesLogic.contains(
          favorites,
          FavoritesLogic.keyFor(
            stationSlug: station.slug,
            artist: track.artist,
            title: track.title,
          ),
        );

    final embedded =
        widget.embedded ?? WindowClass.of(context) == WindowClass.expanded;
    final padding = MediaQuery.paddingOf(context);
    final topInset =
        widget.topInset ??
        (embedded ? 24.0 : padding.top + LinefmMetrics.headerHeight);
    final bottomInset =
        widget.bottomInset ??
        (embedded ? 24.0 : padding.bottom + LinefmMetrics.navHeight + 24);

    return PlayerView(
      data: PlayerViewData(
        station: station,
        track: track,
        coverUrl: track?.artworkUrl,
        status: status,
        listeners: listeners,
        isFavorite: isFavorite,
        marquee: marquee,
      ),
      strings: strings,
      embedded: embedded,
      topInset: topInset,
      bottomInset: bottomInset,
      onTogglePlayback: () => actions.togglePlayback().ignore(),
      onShuffle: () => actions.shuffle().ignore(),
      onRetry: () => actions.retry().ignore(),
      onToggleFavorite: () {
        if (track != null) actions.toggleFavorite(station, track);
      },
      onShare: () {
        if (track != null) actions.shareSong(station, track).ignore();
      },
      onOpenMusicLinks: () {
        if (track != null) _openMusicLinks(strings, track).ignore();
      },
      onNextStation: () => actions.stepStation(1).ignore(),
      onPreviousStation: () => actions.stepStation(-1).ignore(),
      onClose: embedded
          ? null
          : () => ref.read(navigationProvider.notifier).go(AppScreen.stations),
      castSlot: const CastButton(),
      airPlaySlot: _isApple ? const AirPlayButton() : null,
    );
  }
}
