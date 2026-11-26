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
  String get regionHeader => 'Header';

  @override
  String get regionNotices => 'Notices';

  @override
  String get loaderSemantics => 'LINEFM is loading';

  @override
  String get creditsMadeBy => 'Made by Tim Hauke with ♥';

  @override
  String get creditsMadeByLead => 'Made by ';

  @override
  String get creditsMadeByAuthor => 'Tim Hauke';

  @override
  String get creditsMadeByTail => ' with ♥';

  @override
  String get creditsOfferedBy => 'A service of';

  @override
  String get creditsDevelopedBy =>
      'Developed by Tim Hauke (VectoDE) for LineFM Studios';

  @override
  String get creditsOwnership =>
      'LINEFM and this app belong to LineFM Studios.';

  @override
  String get creditsDeveloperOpen => 'Open Tim Hauke on GitHub';

  @override
  String get radioGruppeName => 'RadioGruppe Deutschland';

  @override
  String get radioGruppeOpen => 'Open RadioGruppe Deutschland';

  @override
  String get storageNoticeBodyWeb =>
      'LINEFM Radio stores your settings, favorites, last station and recently played tracks in this browser so the app remembers them next time.';

  @override
  String get storageNoticeBodyDevice =>
      'LINEFM Radio stores your settings, favorites, last station and recently played tracks on this device so the app remembers them next time.';

  @override
  String get storageNoticePrivacy => 'Privacy';

  @override
  String get storageNoticeDismiss => 'Got it';

  @override
  String get storageNoticeTitle => 'Storage on this device';

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
  String stationFavoriteAdd(String station) {
    return 'Add $station to favorite stations';
  }

  @override
  String stationFavoriteRemove(String station) {
    return 'Remove $station from favorite stations';
  }

  @override
  String get stationFavoriteBadge => 'Favorite station';

  @override
  String get playerCoverAlt => 'Album cover';

  @override
  String get playerShuffle => 'Play a random station';

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
  String playerListeners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listening now',
      one: '1 person listening now',
      zero: 'No one is listening right now',
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
  String get playerLive => 'LIVE';

  @override
  String get trackUnknownTitle => 'Unknown title';

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
  String get trackLastSeen => 'Last seen';

  @override
  String get historyEmpty => 'No tracks in the history yet.';

  @override
  String get historyLoadFailed => 'Couldn’t load the history.';

  @override
  String get favoritesTitle => 'Favorites';

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
  String get favoritesExportFailed =>
      'The export didn’t work. Please try again.';

  @override
  String get favoritesImport => 'Import favorites';

  @override
  String favoritesImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favorites imported.',
      one: '1 favorite imported.',
      zero: 'No new favorites in this file.',
    );
    return '$_temp0';
  }

  @override
  String favoritesImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skipped $count entries (unknown station or unreadable).',
      one: 'Skipped 1 entry (unknown station or unreadable).',
    );
    return '$_temp0';
  }

  @override
  String get favoritesImportFailed =>
      'This file could not be read. Pick an export from LINEFM Radio (CSV or text).';

  @override
  String get autoplayBlockedStart => 'Start radio';

  @override
  String autoplayBlockedHint(String station) {
    return 'Your browser only allows sound after a click. Click to start $station.';
  }

  @override
  String get shareCopied => 'Copied to the clipboard.';

  @override
  String get shareFailed => 'Sharing didn’t work.';

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
  String get settingLanguageTitle => 'Language';

  @override
  String get settingLanguageBody =>
      'System language, or fixed to German or English. The change applies right away.';

  @override
  String get languageSystem => 'System language';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get exportColumnTitle => 'Title';

  @override
  String get exportColumnArtist => 'Artist';

  @override
  String get exportColumnStation => 'Station';

  @override
  String get exportColumnSavedAt => 'Saved on';

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
  String get sleepTimerEndOfSongUnavailable =>
      '“End of song” is not available during live shows.';

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
  String get settingCoverCacheTitle => 'Cover storage';

  @override
  String get settingCoverCacheBody =>
      'How much space cached covers may take up on this device. A lower value clears space right away.';

  @override
  String coverCacheSizeMb(int size) {
    return '$size MB';
  }

  @override
  String get settingStorageTitle => 'Storage';

  @override
  String get settingStorageBody =>
      'Stored locally: your last station, recently played tracks and history, volume, favorites, favorite stations, alarms, settings, cached covers and, on a computer, the window position.';

  @override
  String get settingStorageClear => 'Clear storage';

  @override
  String get clearStorageConfirmTitle => 'Clear storage?';

  @override
  String get clearStorageConfirmBody =>
      'Your last station, recently played tracks and history, volume, favorites, favorite stations, alarms, settings and cached covers will be removed. This can’t be undone. Only “Load covers: off” is kept, so no requests go to Apple afterwards.';

  @override
  String get clearStorageDone => 'Storage cleared.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

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
  String get consentIntro =>
      'To see what works and where the app stumbles, we’d like to collect usage and error data, with no name and no account.';

  @override
  String consentRecipients(String services) {
    return 'The data goes to: $services. Your IP address is transmitted in the process.';
  }

  @override
  String get consentServiceUmami => 'Umami (usage statistics)';

  @override
  String get consentServiceSentry => 'GlitchTip or Sentry (error reports)';

  @override
  String get consentServiceFirebase =>
      'Google (Firebase Analytics and Crashlytics)';

  @override
  String get consentFirebaseTransfer =>
      'Google may transfer the data to the USA. This relies on the EU-US Data Privacy Framework, for which the European Commission has found an adequate level of data protection.';

  @override
  String get consentOutro =>
      'This is optional. Nothing is sent unless you agree. You can change your choice any time in the settings.';

  @override
  String get consentAllow => 'Allow';

  @override
  String get consentDecline => 'Decline';

  @override
  String get consentPrivacyLink => 'More in the privacy policy';

  @override
  String get settingGoogleTitle => 'Audience measurement with Google';

  @override
  String get settingGoogleBodyOn =>
      'Allowed. Google Analytics runs in the web version. You can withdraw this at any time; the page then reloads once.';

  @override
  String get settingGoogleBodyOff =>
      'Not allowed. The page loads nothing from Google.';

  @override
  String get googleConsentTitle => 'Audience measurement with Google';

  @override
  String get googleConsentIntro =>
      'We would like to count how many people use the web version and which parts they open. For this we use Google Analytics, embedded through the Google tag.';

  @override
  String get googleConsentRecipient =>
      'The provider is Google Ireland Limited (Dublin, Ireland). Google receives your IP address, details about your browser and device, the parts you open and a random identifier stored in cookies. Advertising features stay switched off.';

  @override
  String get googleConsentTransfer =>
      'Google may transfer the data to Google LLC in the USA. This is based on the EU-US Data Privacy Framework, for which the EU Commission has found an adequate level of data protection.';

  @override
  String get googleConsentOutro =>
      'This question is separate from statistics and error reports and voluntary. Without your consent the page loads nothing from Google. You can withdraw your consent at any time in the settings, with effect for the future.';

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
  String aboutDevVersion(String commit) {
    return 'Development version ($commit)';
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
  String get alarmNoteIos =>
      'On iPhone and iPad a notification wakes you. Tap it to start the radio.';

  @override
  String get alarmNoteDesktop =>
      'The alarm only rings while LINEFM Radio is running, also when it is minimized to the tray.';

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
  String alarmRingingBody(String station) {
    return '$station is about to start.';
  }

  @override
  String get alarmExactMissingNote =>
      'Without the “Alarms & reminders” permission the alarm will not ring on time. Allow it in the system settings.';

  @override
  String get alarmFullScreenMissingNote =>
      'Without the “Full-screen notifications” permission the alarm only shows as a notification, not full screen.';

  @override
  String get alarmOpenFullScreenSettings => 'Allow full screen';

  @override
  String get alarmDismiss => 'Turn off';

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
  String get castUnavailable =>
      'Google Cast is not available on this device. On Android it needs Google Play services.';

  @override
  String get castChooseDevice => 'Choose a device';

  @override
  String get castConsentTitle => 'Casting with Google Cast';

  @override
  String get castConsentIntro =>
      'To send the radio to a Chromecast or a speaker with Google Cast, the page needs a script from Google. It only loads once you agree here.';

  @override
  String get castConsentRecipient =>
      'The provider is Google Ireland Limited (Dublin, Ireland). When the script loads, Google receives your IP address and details about your browser and device. While casting, the Cast device gets the stream address, title, artist and cover and plays the stream directly from laut.fm.';

  @override
  String get castConsentTransfer =>
      'Google may transfer the data to Google LLC in the USA. This is based on the EU-US Data Privacy Framework, for which the EU Commission has found an adequate level of data protection.';

  @override
  String get castConsentOutro =>
      'Your consent is voluntary and separate from audience measurement. You can withdraw it at any time in the settings. If Cast was already loaded, the page then reloads once.';

  @override
  String get settingCastTitle => 'Google Cast (Chromecast)';

  @override
  String get settingCastBodyOn =>
      'Allowed. The page may load the Cast script from Google. You can withdraw this at any time; the page then reloads once.';

  @override
  String get settingCastBodyOff =>
      'Not allowed. The page loads nothing from Google for Cast.';

  @override
  String get airplayButton => 'AirPlay';

  @override
  String get notificationChannelName => 'Playback';

  @override
  String get browseFavoriteStations => 'Favorite stations';

  @override
  String get browseStations => 'Stations';

  @override
  String get browseRecent => 'Recently played';

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

  @override
  String get trayAlwaysOnTop => 'Always on top';

  @override
  String get actionUndo => 'Undo';

  @override
  String favoritesRemoved(String title) {
    return 'Removed “$title”.';
  }

  @override
  String get stationsYours => 'Your stations';

  @override
  String get stationsYoursListLabel => 'Your favorite stations';

  @override
  String get settingArtworkTitle => 'Load covers';

  @override
  String get settingArtworkBody =>
      'Looks up the album cover for the current track at Apple. Off: no requests to Apple, the app shows the laut.fm cover or the station logo. This setting is kept even without a confirmed storage notice and after “Clear storage”.';

  @override
  String get settingShortcutsTitle => 'Single-key shortcuts';

  @override
  String get settingShortcutsBody =>
      'F saves the song, S plays a random station, 1 to 6 pick the first six stations in the list.';

  @override
  String get playerSleepTimer => 'Set sleep timer';

  @override
  String alarmEnabledAt(String time) {
    return 'Alarm $time on';
  }

  @override
  String alarmDeleteAt(String time) {
    return 'Delete alarm $time';
  }

  @override
  String get stationUnavailable =>
      'This station is no longer available in the app.';

  @override
  String alarmStationUnavailable(String station) {
    return 'The selected station is no longer available. The alarm will play $station.';
  }

  @override
  String get windowTitleProduct => 'Radio';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowRestore => 'Restore';

  @override
  String get windowClose => 'Close';
}
