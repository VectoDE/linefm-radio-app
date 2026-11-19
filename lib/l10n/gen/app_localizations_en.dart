// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LINEFM | Radio';

  @override
  String get brandName => 'LINEFM';

  @override
  String get navStations => 'Stations';

  @override
  String get navPlayer => 'Player';

  @override
  String get navHistory => 'History';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMain => 'Main navigation';

  @override
  String get loaderSemantics => 'LINEFM is loading';

  @override
  String get creditsMadeBy => 'Made by .jaybelife with ♥';

  @override
  String get creditsMadeByLead => 'Made by ';

  @override
  String get creditsMadeByAuthor => '.jaybelife';

  @override
  String get creditsMadeByTail => ' with ♥';

  @override
  String get creditsOfferedBy => 'A service of';

  @override
  String get creditsDevelopedBy =>
      'Developed by Tim Hauke (VectoDE) for jaybelife';

  @override
  String get creditsOwnership => 'LINEFM and this app belong to jaybelife.';

  @override
  String get creditsDeveloperOpen => 'Open Tim Hauke on GitHub';

  @override
  String get radioGruppeName => 'Radiogruppe';

  @override
  String get radioGruppeOpen => 'Open Radiogruppe';

  @override
  String get storageNoticeBodyWeb =>
      'We store small bits of data in this browser to make the app work better for you.';

  @override
  String get storageNoticeBodyDevice =>
      'We store small bits of data on this device to make the app work better for you.';

  @override
  String get storageNoticePrivacy => 'Privacy';

  @override
  String get storageNoticeDismiss => 'Got it';

  @override
  String get favoritesButton => 'Favorites';

  @override
  String favoritesButtonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Favorites, $_temp0';
  }

  @override
  String get settingsButton => 'Settings';

  @override
  String get stationsTitle => 'All stations';

  @override
  String get stationsListLabel => 'All stations';

  @override
  String stationCardLabel(String station, String track) {
    return '$station, now playing: $track';
  }

  @override
  String stationCardLabelIdle(String station) {
    return '$station';
  }

  @override
  String get stationLongPressShare => 'Share station';

  @override
  String stationShareText(String station, String url) {
    return 'Have a listen: $station on LINEFM. $url';
  }

  @override
  String get playerCoverAlt => 'Album cover';

  @override
  String get playerShuffle => 'Play a random station';

  @override
  String get playerShuffleTooltip => 'Random station';

  @override
  String get playerStart => 'Start stream';

  @override
  String get playerConnecting => 'Connecting to stream';

  @override
  String get playerStop => 'Stop stream';

  @override
  String get playerFavoriteAdd => 'Save song';

  @override
  String get playerFavoriteRemove => 'Remove from favorites';

  @override
  String get playerNext => 'Next station';

  @override
  String get playerPrevious => 'Previous station';

  @override
  String get playerClose => 'Close player';

  @override
  String get playerOpen => 'Open player';

  @override
  String playerListeners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listening now',
      one: '1 person listening now',
    );
    return '$_temp0';
  }

  @override
  String get playerReconnecting => 'Reconnecting …';

  @override
  String get playerStreamError => 'Couldn’t start the stream.';

  @override
  String get playerRetry => 'Try again';

  @override
  String get playerStartRadio => 'Start radio';

  @override
  String get playerPlayNow => 'Play now';

  @override
  String get playerLive => 'LIVE';

  @override
  String get trackUnknownTitle => 'Unknown title';

  @override
  String get trackUnknownArtist => 'Unknown artist';

  @override
  String get trackLoading => 'Loading track …';

  @override
  String get playerOpenSongIn => 'Open song in …';

  @override
  String get playerShareSong => 'Share song';

  @override
  String get musicAppleMusic => 'Apple Music';

  @override
  String get musicSpotify => 'Spotify';

  @override
  String get musicYouTubeMusic => 'YouTube Music';

  @override
  String shareSongText(
    String artist,
    String station,
    String title,
    String url,
  ) {
    return 'I’m listening to “$title” by $artist on $station. $url';
  }

  @override
  String get linkOpenError => 'Couldn’t open the link.';

  @override
  String get historyTitle => 'Recently played';

  @override
  String get historyListLabel => 'Recently played tracks';

  @override
  String get historyEmpty => 'No tracks in the history yet.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesListLabel => 'Saved songs';

  @override
  String get favoritesEmpty => 'No favorites saved yet.';

  @override
  String favoritesRemove(String title) {
    return 'Remove $title from favorites';
  }

  @override
  String get favoritesExport => 'Export favorites';

  @override
  String get favoritesExportCsv => 'As CSV file';

  @override
  String get favoritesExportText => 'As text';

  @override
  String get favoritesExportEmpty => 'There is nothing to export yet.';

  @override
  String favoritesExportSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get favoritesExportFailed => 'The export failed.';

  @override
  String get csvColumnTitle => 'Title';

  @override
  String get csvColumnArtist => 'Artist';

  @override
  String get csvColumnStation => 'Station';

  @override
  String get csvColumnSavedAt => 'Saved on';

  @override
  String get miniOpenPlayer => 'Open player';

  @override
  String get volumeOpen => 'Open volume';

  @override
  String get volumeClose => 'Close volume';

  @override
  String get volumeLabel => 'Volume';

  @override
  String volumePercent(int percent) {
    return 'Volume $percent percent';
  }

  @override
  String volumeSliderValue(int percent) {
    return '$percent percent';
  }

  @override
  String sleepRemainingShort(int minutes) {
    return '$minutes min left';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingMarqueeTitle => 'Scrolling text for long titles';

  @override
  String get settingMarqueeBody => 'Show long song titles as a ticker.';

  @override
  String get settingVolumeTitle => 'Remember volume';

  @override
  String get settingVolumeBodyWeb => 'Keep the chosen volume in this browser.';

  @override
  String get settingVolumeBodyDevice =>
      'Keep the chosen volume on this device.';

  @override
  String get settingThemeTitle => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingAutoplayTitle => 'Play on launch';

  @override
  String get settingAutoplayBody =>
      'The station you listened to last starts automatically.';

  @override
  String get settingAutoplayBodyWeb =>
      'The station you listened to last starts after your first tap or click.';

  @override
  String get settingTrayTitle => 'Keep playing in the tray when closed';

  @override
  String get settingTrayBody => 'The window closes, playback keeps going.';

  @override
  String get settingAlwaysOnTopTitle => 'Always on top';

  @override
  String get settingMiniWindow => 'Mini player';

  @override
  String get settingAlarmTitle => 'Alarm';

  @override
  String get settingAlarmBodyOff => 'No alarm set.';

  @override
  String get settingAboutTitle => 'About LINEFM Radio';

  @override
  String get sleepTimerTitle => 'Sleep timer';

  @override
  String get sleepTimerOff => 'Off';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get sleepTimerEndOfSong => 'End of song';

  @override
  String get sleepTimerStatusNone => 'No sleep timer active.';

  @override
  String sleepTimerStatusRunning(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Playback stops in $minutes minutes.',
      one: 'Playback stops in 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerStatusEndOfSong =>
      'Playback stops at the end of the song.';

  @override
  String get sleepTimerExpired => 'Sleep timer ended.';

  @override
  String get settingStorageTitle => 'Storage';

  @override
  String get settingStorageBody =>
      'Your last station, favorites, volume and settings are stored locally.';

  @override
  String get settingStorageClear => 'Clear storage';

  @override
  String get clearStorageConfirmTitle => 'Clear storage?';

  @override
  String get clearStorageConfirmBody =>
      'Favorites, volume, last station and settings will be removed. This can’t be undone.';

  @override
  String get clearStorageDone => 'Storage cleared.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionClose => 'Close';

  @override
  String get actionOk => 'OK';

  @override
  String get footerWebsite => 'Website';

  @override
  String get footerImprint => 'Imprint';

  @override
  String get footerPrivacy => 'Privacy';

  @override
  String get footerLinksLabel => 'LINEFM links';

  @override
  String get settingTelemetryTitle => 'Usage statistics and error reports';

  @override
  String get settingTelemetryBodyOn =>
      'Allowed. You can withdraw this at any time.';

  @override
  String get settingTelemetryBodyOff => 'Not allowed. Nothing is sent.';

  @override
  String get consentTitle => 'Usage statistics and error reports';

  @override
  String get consentBody =>
      'To see what works and where the app stumbles, we’d like to collect usage and error data, with no name and no account. This is optional. Nothing is sent unless you agree. You can change your choice any time in the settings.';

  @override
  String get consentAllow => 'Allow';

  @override
  String get consentDecline => 'Decline';

  @override
  String get consentPrivacyLink => 'More in the privacy policy';

  @override
  String get legalImprintTitle => 'Imprint';

  @override
  String get legalPrivacyTitle => 'Privacy policy';

  @override
  String get legalOpenInBrowser => 'Open in browser';

  @override
  String legalUpdated(String date) {
    return 'As of: $date';
  }

  @override
  String get legalLoadError => 'The text couldn’t be loaded.';

  @override
  String get aboutTitle => 'About LINEFM Radio';

  @override
  String aboutVersion(String build, String version) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get trustGridinsoft => 'Website check at Gridinsoft';

  @override
  String get trustTrustpilot => 'Reviews on Trustpilot';

  @override
  String get alarmTitle => 'Alarm';

  @override
  String get alarmEnabled => 'Alarm on';

  @override
  String get alarmTime => 'Time';

  @override
  String get alarmDays => 'Days';

  @override
  String get alarmOnce => 'Once';

  @override
  String get alarmEveryDay => 'Every day';

  @override
  String get alarmStation => 'Station';

  @override
  String get alarmVolume => 'Volume';

  @override
  String get alarmSnooze => 'Snooze';

  @override
  String alarmSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String alarmNext(String when) {
    return 'Next alarm: $when';
  }

  @override
  String get alarmNone => 'No alarm set.';

  @override
  String get alarmAdd => 'Add alarm';

  @override
  String get alarmDelete => 'Delete alarm';

  @override
  String get alarmNoteIos =>
      'On iPhone and iPad a notification wakes you. Tap it to start the radio.';

  @override
  String get alarmNoteDesktop =>
      'The alarm only rings while LINEFM Radio is running (the tray counts).';

  @override
  String get alarmNoteWeb => 'The alarm only rings while this tab is open.';

  @override
  String get alarmNoteAndroid =>
      'Your radio starts at the set time, even if the app is closed. If the stream fails, a ringtone plays instead.';

  @override
  String get alarmPermissionTitle => 'The alarm needs permission';

  @override
  String get alarmPermissionBody =>
      'For the alarm to ring on time, Android has to allow exact alarms. You can switch that on in the system settings.';

  @override
  String get alarmOpenSettings => 'Open settings';

  @override
  String get alarmRingingTitle => 'Good morning';

  @override
  String alarmRingingBody(String station) {
    return '$station is about to start.';
  }

  @override
  String get alarmDismiss => 'Turn off';

  @override
  String get alarmSnoozeAction => 'Snooze';

  @override
  String get alarmNotificationTitle => 'LINEFM alarm';

  @override
  String alarmNotificationBody(String station) {
    return '$station starts now.';
  }

  @override
  String get weekdayShort1 => 'Mon';

  @override
  String get weekdayShort2 => 'Tue';

  @override
  String get weekdayShort3 => 'Wed';

  @override
  String get weekdayShort4 => 'Thu';

  @override
  String get weekdayShort5 => 'Fri';

  @override
  String get weekdayShort6 => 'Sat';

  @override
  String get weekdayShort7 => 'Sun';

  @override
  String get offlineBanner => 'No connection. LINEFM keeps trying.';

  @override
  String get genericError => 'Something went wrong.';

  @override
  String get actionRetry => 'Try again';

  @override
  String get loading => 'Loading …';

  @override
  String get stationsOffline => 'Track info isn’t available right now.';

  @override
  String get castButton => 'Cast to device';

  @override
  String get castSearching => 'Looking for devices …';

  @override
  String get castNoDevices => 'No devices found.';

  @override
  String castConnectedTo(String device) {
    return 'Connected to $device';
  }

  @override
  String get castDisconnect => 'Stop casting';

  @override
  String get airplayButton => 'AirPlay';

  @override
  String get notificationChannelName => 'Playback';

  @override
  String get browseFavorites => 'Favorites';

  @override
  String get widgetIdle => 'Tap to play';

  @override
  String get trayShowWindow => 'Show window';

  @override
  String get trayPlay => 'Play';

  @override
  String get trayStop => 'Stop';

  @override
  String get trayStations => 'Stations';

  @override
  String get trayMiniPlayer => 'Mini player';

  @override
  String get trayQuit => 'Quit';
}
