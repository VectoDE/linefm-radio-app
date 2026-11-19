// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'LINEFM | Radio';

  @override
  String get brandName => 'LINEFM';

  @override
  String get navStations => 'Sender';

  @override
  String get navPlayer => 'Player';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navFavorites => 'Favoriten';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navMain => 'Hauptnavigation';

  @override
  String get loaderSemantics => 'LINEFM wird geladen';

  @override
  String get creditsMadeBy => 'Made by .jaybelife with ♥';

  @override
  String get creditsMadeByLead => 'Made by ';

  @override
  String get creditsMadeByAuthor => '.jaybelife';

  @override
  String get creditsMadeByTail => ' with ♥';

  @override
  String get creditsOfferedBy => 'Ein Angebot von';

  @override
  String get creditsDevelopedBy =>
      'Entwickelt von Tim Hauke (VectoDE) für jaybelife';

  @override
  String get creditsOwnership => 'LINEFM und die App gehören jaybelife.';

  @override
  String get creditsDeveloperOpen => 'Tim Hauke auf GitHub öffnen';

  @override
  String get radioGruppeName => 'RadioGruppe Deutschland';

  @override
  String get radioGruppeOpen => 'RadioGruppe Deutschland öffnen';

  @override
  String get storageNoticeBodyWeb =>
      'LINEFM Radio speichert Einstellungen, Favoriten und den zuletzt gehörten Sender in diesem Browser, damit die App sie beim nächsten Start kennt.';

  @override
  String get storageNoticeBodyDevice =>
      'LINEFM Radio speichert Einstellungen, Favoriten und den zuletzt gehörten Sender auf diesem Gerät, damit die App sie beim nächsten Start kennt.';

  @override
  String get storageNoticePrivacy => 'Datenschutz';

  @override
  String get storageNoticeDismiss => 'Verstanden';

  @override
  String get favoritesButton => 'Favoriten';

  @override
  String favoritesButtonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Songs',
      one: '1 Song',
    );
    return 'Favoriten, $_temp0';
  }

  @override
  String get settingsButton => 'Einstellungen';

  @override
  String get stationsTitle => 'Alle Sender';

  @override
  String get stationsListLabel => 'Alle Sender';

  @override
  String stationCardLabel(String station, String track) {
    return '$station, läuft: $track';
  }

  @override
  String stationCardLabelIdle(String station) {
    return '$station';
  }

  @override
  String get stationLongPressShare => 'Sender teilen';

  @override
  String stationShareText(String station, String url) {
    return 'Hör mal rein: $station bei LINEFM. $url';
  }

  @override
  String stationFavoriteAdd(String station) {
    return '$station als Favoriten-Sender merken';
  }

  @override
  String stationFavoriteRemove(String station) {
    return '$station aus den Favoriten-Sendern entfernen';
  }

  @override
  String get stationFavoriteBadge => 'Favoriten-Sender';

  @override
  String get playerCoverAlt => 'Albumcover';

  @override
  String get playerShuffle => 'Zufälligen Sender abspielen';

  @override
  String get playerStart => 'Stream starten';

  @override
  String get playerConnecting => 'Stream wird verbunden';

  @override
  String get playerStop => 'Stream stoppen';

  @override
  String get playerFavoriteAdd => 'Song merken';

  @override
  String get playerFavoriteRemove => 'Aus Favoriten entfernen';

  @override
  String get playerNext => 'Nächster Sender';

  @override
  String get playerPrevious => 'Vorheriger Sender';

  @override
  String get playerClose => 'Player schließen';

  @override
  String playerListeners(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hören gerade zu',
      one: '1 Person hört gerade zu',
      zero: 'Gerade hört niemand zu',
    );
    return '$_temp0';
  }

  @override
  String get playerReconnecting => 'Verbindung wird wiederhergestellt …';

  @override
  String get playerStreamError => 'Stream konnte nicht gestartet werden.';

  @override
  String get playerRetry => 'Erneut versuchen';

  @override
  String get playerLive => 'LIVE';

  @override
  String get trackUnknownTitle => 'Unbekannter Titel';

  @override
  String get trackLoading => 'Titel wird geladen …';

  @override
  String get playerOpenSongIn => 'Song öffnen in …';

  @override
  String get playerShareSong => 'Song teilen';

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
    return 'Ich höre gerade „$title“ von $artist auf $station. $url';
  }

  @override
  String get linkOpenError => 'Der Link konnte nicht geöffnet werden.';

  @override
  String get historyTitle => 'Zuletzt gespielt';

  @override
  String get historyEmpty => 'Noch keine Titel im Verlauf.';

  @override
  String get historyLoadFailed => 'Verlauf konnte nicht geladen werden.';

  @override
  String get favoritesTitle => 'Favoriten';

  @override
  String get favoritesEmpty => 'Noch keine Favoriten gespeichert.';

  @override
  String favoritesRemove(String title) {
    return '$title aus Favoriten entfernen';
  }

  @override
  String get favoritesExport => 'Favoriten exportieren';

  @override
  String get favoritesExportCsv => 'Als CSV-Datei';

  @override
  String get favoritesExportText => 'Als Text';

  @override
  String get favoritesExportEmpty => 'Es gibt noch nichts zu exportieren.';

  @override
  String favoritesExportSavedTo(String path) {
    return 'Gespeichert unter $path';
  }

  @override
  String get favoritesExportFailed =>
      'Der Export hat nicht geklappt. Versuche es noch einmal.';

  @override
  String get favoritesImport => 'Favoriten importieren';

  @override
  String favoritesImportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Favoriten importiert.',
      one: '1 Favorit importiert.',
      zero: 'Keine neuen Favoriten in der Datei.',
    );
    return '$_temp0';
  }

  @override
  String favoritesImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge übersprungen (unbekannter Sender oder unlesbar).',
      one: '1 Eintrag übersprungen (unbekannter Sender oder unlesbar).',
    );
    return '$_temp0';
  }

  @override
  String get favoritesImportFailed =>
      'Die Datei ließ sich nicht lesen. Wähle einen Export aus LINEFM Radio (CSV oder Text).';

  @override
  String get autoplayBlockedStart => 'Radio starten';

  @override
  String autoplayBlockedHint(String station) {
    return 'Dein Browser erlaubt Ton erst nach einem Klick. Klicke, um $station zu starten.';
  }

  @override
  String get shareCopied => 'In die Zwischenablage kopiert.';

  @override
  String get shareFailed => 'Teilen hat nicht geklappt.';

  @override
  String get miniOpenPlayer => 'Player öffnen';

  @override
  String get volumeOpen => 'Lautstärke öffnen';

  @override
  String get volumeClose => 'Lautstärke schließen';

  @override
  String get volumeLabel => 'Lautstärke';

  @override
  String volumePercent(int percent) {
    return 'Lautstärke $percent Prozent';
  }

  @override
  String sleepRemainingShort(int minutes) {
    return 'Noch $minutes Min.';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingMarqueeTitle => 'Lauftext für lange Titel';

  @override
  String get settingMarqueeBody => 'Lange Songtitel als Band anzeigen.';

  @override
  String get settingVolumeTitle => 'Lautstärke merken';

  @override
  String get settingVolumeBodyWeb =>
      'Die gewählte Lautstärke in diesem Browser behalten.';

  @override
  String get settingVolumeBodyDevice =>
      'Die gewählte Lautstärke auf diesem Gerät behalten.';

  @override
  String get settingThemeTitle => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingAutoplayTitle => 'Beim Start abspielen';

  @override
  String get settingAutoplayBody =>
      'Der zuletzt gehörte Sender startet automatisch.';

  @override
  String get settingAutoplayBodyWeb =>
      'Der zuletzt gehörte Sender startet nach deinem ersten Tippen oder Klick.';

  @override
  String get settingTrayTitle => 'Beim Schließen im Tray weiterlaufen';

  @override
  String get settingTrayBody =>
      'Das Fenster verschwindet, die Wiedergabe läuft weiter.';

  @override
  String get settingAlarmTitle => 'Wecker';

  @override
  String get settingAlarmBodyOff => 'Kein Wecker gestellt.';

  @override
  String get settingAboutTitle => 'Über LINEFM Radio';

  @override
  String get sleepTimerTitle => 'Sleeptimer';

  @override
  String get sleepTimerOff => 'Aus';

  @override
  String sleepTimerMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get sleepTimerEndOfSong => 'Ende des Songs';

  @override
  String get sleepTimerEndOfSongUnavailable =>
      '„Ende des Songs“ ist bei Live-Sendungen nicht möglich.';

  @override
  String get sleepTimerStatusNone => 'Kein Sleeptimer aktiv.';

  @override
  String sleepTimerStatusRunning(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Wiedergabe stoppt in $minutes Minuten.',
      one: 'Wiedergabe stoppt in 1 Minute.',
    );
    return '$_temp0';
  }

  @override
  String get sleepTimerStatusEndOfSong =>
      'Wiedergabe stoppt am Ende des Songs.';

  @override
  String get sleepTimerExpired => 'Sleeptimer abgelaufen.';

  @override
  String get settingStorageTitle => 'Speicher';

  @override
  String get settingStorageBody =>
      'Lokal gespeichert werden: zuletzt gehörter Sender, Lautstärke, Favoriten, Favoriten-Sender, Wecker, Einstellungen, zwischengespeicherte Cover und am Computer die Fensterposition.';

  @override
  String get settingStorageClear => 'Speicher löschen';

  @override
  String get clearStorageConfirmTitle => 'Speicher löschen?';

  @override
  String get clearStorageConfirmBody =>
      'Zuletzt gehörter Sender, Lautstärke, Favoriten, Favoriten-Sender, Wecker, Einstellungen und zwischengespeicherte Cover werden entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get clearStorageDone => 'Speicher gelöscht.';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get footerWebsite => 'Website';

  @override
  String get footerImprint => 'Impressum';

  @override
  String get footerPrivacy => 'Datenschutz';

  @override
  String get footerLinksLabel => 'LINEFM Links';

  @override
  String get settingTelemetryTitle => 'Statistik und Fehlerberichte';

  @override
  String get settingTelemetryBodyOn =>
      'Erlaubt. Du kannst das jederzeit widerrufen.';

  @override
  String get settingTelemetryBodyOff =>
      'Nicht erlaubt. Es wird nichts gesendet.';

  @override
  String get consentTitle => 'Statistik und Fehlerberichte';

  @override
  String get consentBody =>
      'Damit wir sehen, was gut läuft und wo die App hakt, würden wir gern Angaben zur Nutzung und zu Fehlern auswerten, ohne Namen und ohne Konto. Die Daten gehen an den Betreiber unseres Statistik- und Fehlerbericht-Dienstes (Umami, GlitchTip). Dabei wird technisch deine IP-Adresse übertragen. Das ist freiwillig. Ohne deine Zustimmung wird nichts gesendet. Du kannst deine Wahl jederzeit in den Einstellungen ändern.';

  @override
  String get consentAllow => 'Erlauben';

  @override
  String get consentDecline => 'Ablehnen';

  @override
  String get consentPrivacyLink => 'Mehr in der Datenschutzerklärung';

  @override
  String get legalImprintTitle => 'Impressum';

  @override
  String get legalPrivacyTitle => 'Datenschutz';

  @override
  String get legalOpenInBrowser => 'Im Browser öffnen';

  @override
  String legalUpdated(String date) {
    return 'Stand: $date';
  }

  @override
  String get legalLoadError => 'Der Text konnte nicht geladen werden.';

  @override
  String get aboutTitle => 'Über LINEFM Radio';

  @override
  String aboutVersion(String build, String version) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get trustGridinsoft => 'Website-Prüfung bei Gridinsoft';

  @override
  String get trustTrustpilot => 'Bewertungen bei Trustpilot';

  @override
  String get alarmTitle => 'Wecker';

  @override
  String get alarmEnabled => 'Wecker aktiv';

  @override
  String get alarmTime => 'Uhrzeit';

  @override
  String get alarmDays => 'Wochentage';

  @override
  String get alarmOnce => 'Einmalig';

  @override
  String get alarmEveryDay => 'Jeden Tag';

  @override
  String get alarmStation => 'Sender';

  @override
  String get alarmVolume => 'Lautstärke';

  @override
  String get alarmSnooze => 'Schlummern';

  @override
  String alarmSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String alarmNext(String when) {
    return 'Nächster Wecker: $when';
  }

  @override
  String get alarmNone => 'Kein Wecker gestellt.';

  @override
  String get alarmAdd => 'Wecker hinzufügen';

  @override
  String get alarmDelete => 'Wecker löschen';

  @override
  String get alarmNoteIos =>
      'Auf iPhone und iPad weckt dich eine Mitteilung. Tippe darauf, um das Radio zu starten.';

  @override
  String get alarmNoteDesktop =>
      'Der Wecker klingelt nur, solange LINEFM Radio läuft, auch wenn es im Tray liegt.';

  @override
  String get alarmNoteWeb =>
      'Der Wecker klingelt nur, solange dieser Tab geöffnet ist.';

  @override
  String get alarmNoteAndroid =>
      'Dein Radio startet zur eingestellten Zeit, auch wenn die App geschlossen ist. Klappt der Stream nicht, klingelt ein Weckton.';

  @override
  String get alarmPermissionTitle => 'Wecker braucht eine Freigabe';

  @override
  String get alarmPermissionBody =>
      'Damit der Wecker pünktlich klingelt, muss Android genaue Alarme erlauben. Das stellst du in den Systemeinstellungen ein.';

  @override
  String get alarmOpenSettings => 'Einstellungen öffnen';

  @override
  String alarmRingingBody(String station) {
    return '$station läuft gleich los.';
  }

  @override
  String get alarmExactMissingNote =>
      'Ohne die Freigabe „Alarme und Erinnerungen“ klingelt der Wecker nicht pünktlich. Erlaube sie in den Systemeinstellungen.';

  @override
  String get alarmFullScreenMissingNote =>
      'Ohne die Freigabe „Vollbild-Benachrichtigungen“ erscheint der Wecker nur als Mitteilung, nicht als Vollbild.';

  @override
  String get alarmOpenFullScreenSettings => 'Vollbild erlauben';

  @override
  String get alarmDismiss => 'Ausschalten';

  @override
  String get alarmNotificationTitle => 'LINEFM Wecker';

  @override
  String alarmNotificationBody(String station) {
    return '$station startet jetzt.';
  }

  @override
  String get weekdayShort1 => 'Mo';

  @override
  String get weekdayShort2 => 'Di';

  @override
  String get weekdayShort3 => 'Mi';

  @override
  String get weekdayShort4 => 'Do';

  @override
  String get weekdayShort5 => 'Fr';

  @override
  String get weekdayShort6 => 'Sa';

  @override
  String get weekdayShort7 => 'So';

  @override
  String get offlineBanner => 'Keine Verbindung. LINEFM versucht es weiter.';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get loading => 'Wird geladen …';

  @override
  String get stationsOffline => 'Die Titelinfos sind gerade nicht erreichbar.';

  @override
  String get castButton => 'Auf Gerät übertragen';

  @override
  String get castSearching => 'Suche nach Geräten …';

  @override
  String get castNoDevices => 'Keine Geräte gefunden.';

  @override
  String castConnectedTo(String device) {
    return 'Verbunden mit $device';
  }

  @override
  String get castDisconnect => 'Übertragung beenden';

  @override
  String get airplayButton => 'AirPlay';

  @override
  String get notificationChannelName => 'Wiedergabe';

  @override
  String get browseFavoriteStations => 'Favoriten-Sender';

  @override
  String get browseStations => 'Sender';

  @override
  String get browseRecent => 'Zuletzt gehört';

  @override
  String get widgetIdle => 'Zum Abspielen tippen';

  @override
  String get trayShowWindow => 'Fenster zeigen';

  @override
  String get trayPlay => 'Abspielen';

  @override
  String get trayStop => 'Stoppen';

  @override
  String get trayStations => 'Sender';

  @override
  String get trayMiniPlayer => 'Mini-Player';

  @override
  String get trayQuit => 'Beenden';

  @override
  String get trayAlwaysOnTop => 'Immer im Vordergrund';

  @override
  String get actionUndo => 'Rückgängig';

  @override
  String favoritesRemoved(String title) {
    return '„$title“ entfernt.';
  }

  @override
  String get stationsYours => 'Deine Sender';

  @override
  String get stationsYoursListLabel => 'Deine Favoriten-Sender';

  @override
  String get settingArtworkTitle => 'Cover laden';

  @override
  String get settingArtworkBody =>
      'Sucht zum laufenden Titel das Albumcover bei Apple. Aus: keine Anfrage an Apple, die App zeigt das Senderlogo.';

  @override
  String get settingShortcutsTitle => 'Tastenkürzel mit einer Taste';

  @override
  String get settingShortcutsBody =>
      'F merkt den Song, S spielt einen zufälligen Sender, 1 bis 6 wählen einen Sender.';

  @override
  String get playerSleepTimer => 'Sleeptimer einstellen';

  @override
  String alarmEnabledAt(String time) {
    return 'Wecker $time aktiv';
  }

  @override
  String alarmDeleteAt(String time) {
    return 'Wecker $time löschen';
  }
}
