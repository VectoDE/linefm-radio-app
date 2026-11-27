import 'package:linefm_radio/l10n/gen/app_localizations.dart';

/// Alle Texte des Player-Screens. Die Widgets lesen keine Lokalisierung
/// selbst, der Screen uebergibt dieses Objekt (Texte aus P08).
class PlayerStrings {
  const PlayerStrings({
    required this.coverAlt,
    required this.shuffle,
    required this.start,
    required this.connecting,
    required this.stop,
    required this.favoriteAdd,
    required this.favoriteRemove,
    required this.next,
    required this.previous,
    required this.close,
    required this.openSongIn,
    required this.shareSong,
    required this.reconnecting,
    required this.streamError,
    required this.retry,
    required this.unknownTitle,
    required this.trackLoading,
    required this.live,
    required this.listeners,
    required this.musicAppleMusic,
    required this.musicSpotify,
    required this.musicYouTubeMusic,
    required this.linkOpenError,
    this.sleepTimer = 'Sleeptimer',
  });

  /// Knopf "Sleeptimer einstellen" im Player.
  final String sleepTimer;

  factory PlayerStrings.of(AppLocalizations l10n) => PlayerStrings(
    coverAlt: l10n.playerCoverAlt,
    sleepTimer: l10n.playerSleepTimer,
    shuffle: l10n.playerShuffle,
    start: l10n.playerStart,
    connecting: l10n.playerConnecting,
    stop: l10n.playerStop,
    favoriteAdd: l10n.playerFavoriteAdd,
    favoriteRemove: l10n.playerFavoriteRemove,
    next: l10n.playerNext,
    previous: l10n.playerPrevious,
    close: l10n.playerClose,
    openSongIn: l10n.playerOpenSongIn,
    shareSong: l10n.playerShareSong,
    reconnecting: l10n.playerReconnecting,
    streamError: l10n.playerStreamError,
    retry: l10n.playerRetry,
    unknownTitle: l10n.trackUnknownTitle,
    trackLoading: l10n.trackLoading,
    live: l10n.playerLive,
    listeners: l10n.playerListeners,
    musicAppleMusic: l10n.musicAppleMusic,
    musicSpotify: l10n.musicSpotify,
    musicYouTubeMusic: l10n.musicYouTubeMusic,
    linkOpenError: l10n.linkOpenError,
  );

  final String coverAlt;
  final String shuffle;
  final String start;
  final String connecting;
  final String stop;
  final String favoriteAdd;
  final String favoriteRemove;
  final String next;
  final String previous;
  final String close;
  final String openSongIn;
  final String shareSong;
  final String reconnecting;
  final String streamError;
  final String retry;
  final String unknownTitle;
  final String trackLoading;
  final String live;
  final String Function(int count) listeners;
  final String musicAppleMusic;
  final String musicSpotify;
  final String musicYouTubeMusic;
  final String linkOpenError;
}
