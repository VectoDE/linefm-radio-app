import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// App-Titel, Fenstertitel
  ///
  /// In de, this message translates to:
  /// **'LINEFM | Radio'**
  String get appTitle;

  /// Markenname im Header
  ///
  /// In de, this message translates to:
  /// **'LINEFM'**
  String get brandName;

  /// No description provided for @navStations.
  ///
  /// In de, this message translates to:
  /// **'Sender'**
  String get navStations;

  /// No description provided for @navPlayer.
  ///
  /// In de, this message translates to:
  /// **'Player'**
  String get navPlayer;

  /// No description provided for @navHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get navHistory;

  /// No description provided for @navFavorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get navFavorites;

  /// No description provided for @navSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @navMain.
  ///
  /// In de, this message translates to:
  /// **'Hauptnavigation'**
  String get navMain;

  /// No description provided for @regionHeader.
  ///
  /// In de, this message translates to:
  /// **'Kopfbereich'**
  String get regionHeader;

  /// No description provided for @regionNotices.
  ///
  /// In de, this message translates to:
  /// **'Hinweise'**
  String get regionNotices;

  /// No description provided for @loaderSemantics.
  ///
  /// In de, this message translates to:
  /// **'LINEFM wird geladen'**
  String get loaderSemantics;

  /// Wörtlich, in allen Sprachen gleich
  ///
  /// In de, this message translates to:
  /// **'Made by .jaybelife with ♥'**
  String get creditsMadeBy;

  /// Teil 1 von creditsMadeBy (Name wird fett gesetzt)
  ///
  /// In de, this message translates to:
  /// **'Made by '**
  String get creditsMadeByLead;

  /// Teil 2 von creditsMadeBy
  ///
  /// In de, this message translates to:
  /// **'.jaybelife'**
  String get creditsMadeByAuthor;

  /// Teil 3 von creditsMadeBy (Herz farbig)
  ///
  /// In de, this message translates to:
  /// **' with ♥'**
  String get creditsMadeByTail;

  /// No description provided for @creditsOfferedBy.
  ///
  /// In de, this message translates to:
  /// **'Ein Angebot von'**
  String get creditsOfferedBy;

  /// No description provided for @creditsDevelopedBy.
  ///
  /// In de, this message translates to:
  /// **'Entwickelt von Tim Hauke (VectoDE) für jaybelife'**
  String get creditsDevelopedBy;

  /// No description provided for @creditsOwnership.
  ///
  /// In de, this message translates to:
  /// **'LINEFM und die App gehören jaybelife.'**
  String get creditsOwnership;

  /// No description provided for @creditsDeveloperOpen.
  ///
  /// In de, this message translates to:
  /// **'Tim Hauke auf GitHub öffnen'**
  String get creditsDeveloperOpen;

  /// No description provided for @radioGruppeName.
  ///
  /// In de, this message translates to:
  /// **'RadioGruppe Deutschland'**
  String get radioGruppeName;

  /// No description provided for @radioGruppeOpen.
  ///
  /// In de, this message translates to:
  /// **'RadioGruppe Deutschland öffnen'**
  String get radioGruppeOpen;

  /// No description provided for @storageNoticeBodyWeb.
  ///
  /// In de, this message translates to:
  /// **'LINEFM Radio speichert Einstellungen, Favoriten und den zuletzt gehörten Sender in diesem Browser, damit die App sie beim nächsten Start kennt.'**
  String get storageNoticeBodyWeb;

  /// No description provided for @storageNoticeBodyDevice.
  ///
  /// In de, this message translates to:
  /// **'LINEFM Radio speichert Einstellungen, Favoriten und den zuletzt gehörten Sender auf diesem Gerät, damit die App sie beim nächsten Start kennt.'**
  String get storageNoticeBodyDevice;

  /// No description provided for @storageNoticePrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get storageNoticePrivacy;

  /// No description provided for @storageNoticeDismiss.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get storageNoticeDismiss;

  /// No description provided for @favoritesButton.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favoritesButton;

  /// No description provided for @favoritesButtonCount.
  ///
  /// In de, this message translates to:
  /// **'Favoriten, {count, plural, =1{1 Song} other{{count} Songs}}'**
  String favoritesButtonCount(int count);

  /// No description provided for @settingsButton.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsButton;

  /// No description provided for @stationsTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Sender'**
  String get stationsTitle;

  /// No description provided for @stationsListLabel.
  ///
  /// In de, this message translates to:
  /// **'Alle Sender'**
  String get stationsListLabel;

  /// No description provided for @stationCardLabel.
  ///
  /// In de, this message translates to:
  /// **'{station}, läuft: {track}'**
  String stationCardLabel(String station, String track);

  /// No description provided for @stationCardLabelIdle.
  ///
  /// In de, this message translates to:
  /// **'{station}'**
  String stationCardLabelIdle(String station);

  /// No description provided for @stationLongPressShare.
  ///
  /// In de, this message translates to:
  /// **'Sender teilen'**
  String get stationLongPressShare;

  /// No description provided for @stationShareText.
  ///
  /// In de, this message translates to:
  /// **'Hör mal rein: {station} bei LINEFM. {url}'**
  String stationShareText(String station, String url);

  /// Stern auf der Stationskarte (Screenreader/Tooltip), Issue #42
  ///
  /// In de, this message translates to:
  /// **'{station} als Favoriten-Sender merken'**
  String stationFavoriteAdd(String station);

  /// No description provided for @stationFavoriteRemove.
  ///
  /// In de, this message translates to:
  /// **'{station} aus den Favoriten-Sendern entfernen'**
  String stationFavoriteRemove(String station);

  /// Zusatz im Screenreader-Text einer gemerkten Stationskarte
  ///
  /// In de, this message translates to:
  /// **'Favoriten-Sender'**
  String get stationFavoriteBadge;

  /// No description provided for @playerCoverAlt.
  ///
  /// In de, this message translates to:
  /// **'Albumcover'**
  String get playerCoverAlt;

  /// No description provided for @playerShuffle.
  ///
  /// In de, this message translates to:
  /// **'Zufälligen Sender abspielen'**
  String get playerShuffle;

  /// No description provided for @playerStart.
  ///
  /// In de, this message translates to:
  /// **'Stream starten'**
  String get playerStart;

  /// No description provided for @playerConnecting.
  ///
  /// In de, this message translates to:
  /// **'Stream wird verbunden'**
  String get playerConnecting;

  /// No description provided for @playerStop.
  ///
  /// In de, this message translates to:
  /// **'Stream stoppen'**
  String get playerStop;

  /// No description provided for @playerFavoriteAdd.
  ///
  /// In de, this message translates to:
  /// **'Song merken'**
  String get playerFavoriteAdd;

  /// No description provided for @playerFavoriteRemove.
  ///
  /// In de, this message translates to:
  /// **'Aus Favoriten entfernen'**
  String get playerFavoriteRemove;

  /// No description provided for @playerNext.
  ///
  /// In de, this message translates to:
  /// **'Nächster Sender'**
  String get playerNext;

  /// No description provided for @playerPrevious.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Sender'**
  String get playerPrevious;

  /// No description provided for @playerClose.
  ///
  /// In de, this message translates to:
  /// **'Player schließen'**
  String get playerClose;

  /// No description provided for @playerListeners.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Gerade hört niemand zu} =1{1 Person hört gerade zu} other{{count} hören gerade zu}}'**
  String playerListeners(int count);

  /// No description provided for @playerReconnecting.
  ///
  /// In de, this message translates to:
  /// **'Verbindung wird wiederhergestellt …'**
  String get playerReconnecting;

  /// No description provided for @playerStreamError.
  ///
  /// In de, this message translates to:
  /// **'Stream konnte nicht gestartet werden.'**
  String get playerStreamError;

  /// No description provided for @playerRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get playerRetry;

  /// No description provided for @playerLive.
  ///
  /// In de, this message translates to:
  /// **'LIVE'**
  String get playerLive;

  /// No description provided for @trackUnknownTitle.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Titel'**
  String get trackUnknownTitle;

  /// No description provided for @trackLoading.
  ///
  /// In de, this message translates to:
  /// **'Titel wird geladen …'**
  String get trackLoading;

  /// No description provided for @playerOpenSongIn.
  ///
  /// In de, this message translates to:
  /// **'Song öffnen in …'**
  String get playerOpenSongIn;

  /// No description provided for @playerShareSong.
  ///
  /// In de, this message translates to:
  /// **'Song teilen'**
  String get playerShareSong;

  /// No description provided for @musicAppleMusic.
  ///
  /// In de, this message translates to:
  /// **'Apple Music'**
  String get musicAppleMusic;

  /// No description provided for @musicSpotify.
  ///
  /// In de, this message translates to:
  /// **'Spotify'**
  String get musicSpotify;

  /// No description provided for @musicYouTubeMusic.
  ///
  /// In de, this message translates to:
  /// **'YouTube Music'**
  String get musicYouTubeMusic;

  /// No description provided for @shareSongText.
  ///
  /// In de, this message translates to:
  /// **'Ich höre gerade „{title}“ von {artist} auf {station}. {url}'**
  String shareSongText(String artist, String station, String title, String url);

  /// No description provided for @linkOpenError.
  ///
  /// In de, this message translates to:
  /// **'Der Link konnte nicht geöffnet werden.'**
  String get linkOpenError;

  /// No description provided for @historyTitle.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gespielt'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Titel im Verlauf.'**
  String get historyEmpty;

  /// No description provided for @historyLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Verlauf konnte nicht geladen werden.'**
  String get historyLoadFailed;

  /// No description provided for @favoritesTitle.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Favoriten gespeichert.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesRemove.
  ///
  /// In de, this message translates to:
  /// **'{title} aus Favoriten entfernen'**
  String favoritesRemove(String title);

  /// No description provided for @favoritesExport.
  ///
  /// In de, this message translates to:
  /// **'Favoriten exportieren'**
  String get favoritesExport;

  /// No description provided for @favoritesExportCsv.
  ///
  /// In de, this message translates to:
  /// **'Als CSV-Datei'**
  String get favoritesExportCsv;

  /// No description provided for @favoritesExportText.
  ///
  /// In de, this message translates to:
  /// **'Als Text'**
  String get favoritesExportText;

  /// No description provided for @favoritesExportEmpty.
  ///
  /// In de, this message translates to:
  /// **'Es gibt noch nichts zu exportieren.'**
  String get favoritesExportEmpty;

  /// No description provided for @favoritesExportSavedTo.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert unter {path}'**
  String favoritesExportSavedTo(String path);

  /// No description provided for @favoritesExportFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Export hat nicht geklappt. Versuche es noch einmal.'**
  String get favoritesExportFailed;

  /// Knopf/Tooltip: Favoriten aus einer eigenen Export-Datei (CSV oder Text) einlesen, Issue #9
  ///
  /// In de, this message translates to:
  /// **'Favoriten importieren'**
  String get favoritesImport;

  /// No description provided for @favoritesImportDone.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine neuen Favoriten in der Datei.} =1{1 Favorit importiert.} other{{count} Favoriten importiert.}}'**
  String favoritesImportDone(int count);

  /// No description provided for @favoritesImportSkipped.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Eintrag übersprungen (unbekannter Sender oder unlesbar).} other{{count} Einträge übersprungen (unbekannter Sender oder unlesbar).}}'**
  String favoritesImportSkipped(int count);

  /// No description provided for @favoritesImportFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ließ sich nicht lesen. Wähle einen Export aus LINEFM Radio (CSV oder Text).'**
  String get favoritesImportFailed;

  /// Großer Knopf, wenn der Browser den automatischen Start blockiert (Web-Autoplay-Sperre, Spec 2.2)
  ///
  /// In de, this message translates to:
  /// **'Radio starten'**
  String get autoplayBlockedStart;

  /// No description provided for @autoplayBlockedHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Browser erlaubt Ton erst nach einem Klick. Klicke, um {station} zu starten.'**
  String autoplayBlockedHint(String station);

  /// No description provided for @shareCopied.
  ///
  /// In de, this message translates to:
  /// **'In die Zwischenablage kopiert.'**
  String get shareCopied;

  /// No description provided for @shareFailed.
  ///
  /// In de, this message translates to:
  /// **'Teilen hat nicht geklappt.'**
  String get shareFailed;

  /// No description provided for @miniOpenPlayer.
  ///
  /// In de, this message translates to:
  /// **'Player öffnen'**
  String get miniOpenPlayer;

  /// No description provided for @volumeOpen.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke öffnen'**
  String get volumeOpen;

  /// No description provided for @volumeClose.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke schließen'**
  String get volumeClose;

  /// No description provided for @volumeLabel.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke'**
  String get volumeLabel;

  /// No description provided for @volumePercent.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke {percent} Prozent'**
  String volumePercent(int percent);

  /// No description provided for @sleepRemainingShort.
  ///
  /// In de, this message translates to:
  /// **'Noch {minutes} Min.'**
  String sleepRemainingShort(int minutes);

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingMarqueeTitle.
  ///
  /// In de, this message translates to:
  /// **'Lauftext für lange Titel'**
  String get settingMarqueeTitle;

  /// No description provided for @settingMarqueeBody.
  ///
  /// In de, this message translates to:
  /// **'Lange Songtitel als Band anzeigen.'**
  String get settingMarqueeBody;

  /// No description provided for @settingVolumeTitle.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke merken'**
  String get settingVolumeTitle;

  /// No description provided for @settingVolumeBodyWeb.
  ///
  /// In de, this message translates to:
  /// **'Die gewählte Lautstärke in diesem Browser behalten.'**
  String get settingVolumeBodyWeb;

  /// No description provided for @settingVolumeBodyDevice.
  ///
  /// In de, this message translates to:
  /// **'Die gewählte Lautstärke auf diesem Gerät behalten.'**
  String get settingVolumeBodyDevice;

  /// No description provided for @settingThemeTitle.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get settingThemeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @settingAutoplayTitle.
  ///
  /// In de, this message translates to:
  /// **'Beim Start abspielen'**
  String get settingAutoplayTitle;

  /// No description provided for @settingAutoplayBody.
  ///
  /// In de, this message translates to:
  /// **'Der zuletzt gehörte Sender startet automatisch.'**
  String get settingAutoplayBody;

  /// No description provided for @settingAutoplayBodyWeb.
  ///
  /// In de, this message translates to:
  /// **'Der zuletzt gehörte Sender startet nach deinem ersten Tippen oder Klick.'**
  String get settingAutoplayBodyWeb;

  /// No description provided for @settingTrayTitle.
  ///
  /// In de, this message translates to:
  /// **'Beim Schließen im Tray weiterlaufen'**
  String get settingTrayTitle;

  /// No description provided for @settingTrayBody.
  ///
  /// In de, this message translates to:
  /// **'Das Fenster verschwindet, die Wiedergabe läuft weiter.'**
  String get settingTrayBody;

  /// No description provided for @settingAlarmTitle.
  ///
  /// In de, this message translates to:
  /// **'Wecker'**
  String get settingAlarmTitle;

  /// No description provided for @settingAlarmBodyOff.
  ///
  /// In de, this message translates to:
  /// **'Kein Wecker gestellt.'**
  String get settingAlarmBodyOff;

  /// No description provided for @settingAboutTitle.
  ///
  /// In de, this message translates to:
  /// **'Über LINEFM Radio'**
  String get settingAboutTitle;

  /// No description provided for @sleepTimerTitle.
  ///
  /// In de, this message translates to:
  /// **'Sleeptimer'**
  String get sleepTimerTitle;

  /// No description provided for @sleepTimerOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get sleepTimerOff;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes} Min.'**
  String sleepTimerMinutes(int minutes);

  /// No description provided for @sleepTimerEndOfSong.
  ///
  /// In de, this message translates to:
  /// **'Ende des Songs'**
  String get sleepTimerEndOfSong;

  /// No description provided for @sleepTimerEndOfSongUnavailable.
  ///
  /// In de, this message translates to:
  /// **'„Ende des Songs“ ist bei Live-Sendungen nicht möglich.'**
  String get sleepTimerEndOfSongUnavailable;

  /// No description provided for @sleepTimerStatusNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Sleeptimer aktiv.'**
  String get sleepTimerStatusNone;

  /// No description provided for @sleepTimerStatusRunning.
  ///
  /// In de, this message translates to:
  /// **'{minutes, plural, =1{Wiedergabe stoppt in 1 Minute.} other{Wiedergabe stoppt in {minutes} Minuten.}}'**
  String sleepTimerStatusRunning(int minutes);

  /// No description provided for @sleepTimerStatusEndOfSong.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe stoppt am Ende des Songs.'**
  String get sleepTimerStatusEndOfSong;

  /// No description provided for @sleepTimerExpired.
  ///
  /// In de, this message translates to:
  /// **'Sleeptimer abgelaufen.'**
  String get sleepTimerExpired;

  /// No description provided for @settingStorageTitle.
  ///
  /// In de, this message translates to:
  /// **'Speicher'**
  String get settingStorageTitle;

  /// No description provided for @settingStorageBody.
  ///
  /// In de, this message translates to:
  /// **'Lokal gespeichert werden: zuletzt gehörter Sender, Lautstärke, Favoriten, Favoriten-Sender, Wecker, Einstellungen, zwischengespeicherte Cover und am Computer die Fensterposition.'**
  String get settingStorageBody;

  /// No description provided for @settingStorageClear.
  ///
  /// In de, this message translates to:
  /// **'Speicher löschen'**
  String get settingStorageClear;

  /// No description provided for @clearStorageConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Speicher löschen?'**
  String get clearStorageConfirmTitle;

  /// No description provided for @clearStorageConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gehörter Sender, Lautstärke, Favoriten, Favoriten-Sender, Wecker, Einstellungen und zwischengespeicherte Cover werden entfernt. Das lässt sich nicht rückgängig machen. Nur „Cover laden: aus“ bleibt gespeichert, damit danach keine Anfragen an Apple gehen.'**
  String get clearStorageConfirmBody;

  /// No description provided for @clearStorageDone.
  ///
  /// In de, this message translates to:
  /// **'Speicher gelöscht.'**
  String get clearStorageDone;

  /// No description provided for @actionCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// No description provided for @footerWebsite.
  ///
  /// In de, this message translates to:
  /// **'Website'**
  String get footerWebsite;

  /// No description provided for @footerImprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get footerImprint;

  /// No description provided for @footerPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get footerPrivacy;

  /// No description provided for @footerLinksLabel.
  ///
  /// In de, this message translates to:
  /// **'LINEFM Links'**
  String get footerLinksLabel;

  /// No description provided for @settingTelemetryTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik und Fehlerberichte'**
  String get settingTelemetryTitle;

  /// No description provided for @settingTelemetryBodyOn.
  ///
  /// In de, this message translates to:
  /// **'Erlaubt. Du kannst das jederzeit widerrufen.'**
  String get settingTelemetryBodyOn;

  /// No description provided for @settingTelemetryBodyOff.
  ///
  /// In de, this message translates to:
  /// **'Nicht erlaubt. Es wird nichts gesendet.'**
  String get settingTelemetryBodyOff;

  /// No description provided for @consentTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik und Fehlerberichte'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In de, this message translates to:
  /// **'Damit wir sehen, was gut läuft und wo die App hakt, würden wir gern Angaben zur Nutzung und zu Fehlern auswerten, ohne Namen und ohne Konto.'**
  String get consentIntro;

  /// No description provided for @consentRecipients.
  ///
  /// In de, this message translates to:
  /// **'Die Daten gehen an: {services}. Dabei wird technisch deine IP-Adresse übertragen.'**
  String consentRecipients(String services);

  /// No description provided for @consentServiceUmami.
  ///
  /// In de, this message translates to:
  /// **'Umami (Nutzungsstatistik)'**
  String get consentServiceUmami;

  /// No description provided for @consentServiceSentry.
  ///
  /// In de, this message translates to:
  /// **'GlitchTip bzw. Sentry (Fehlerberichte)'**
  String get consentServiceSentry;

  /// No description provided for @consentServiceFirebase.
  ///
  /// In de, this message translates to:
  /// **'Google (Firebase Analytics und Crashlytics)'**
  String get consentServiceFirebase;

  /// No description provided for @consentFirebaseTransfer.
  ///
  /// In de, this message translates to:
  /// **'Google kann die Daten in die USA übermitteln. Grundlage ist das EU-US Data Privacy Framework, für das die EU-Kommission ein angemessenes Datenschutzniveau festgestellt hat.'**
  String get consentFirebaseTransfer;

  /// No description provided for @consentOutro.
  ///
  /// In de, this message translates to:
  /// **'Das ist freiwillig. Ohne deine Zustimmung wird nichts gesendet. Du kannst die Einwilligung jederzeit in den Einstellungen mit Wirkung für die Zukunft widerrufen.'**
  String get consentOutro;

  /// No description provided for @consentAllow.
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get consentAllow;

  /// No description provided for @consentDecline.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get consentDecline;

  /// No description provided for @consentPrivacyLink.
  ///
  /// In de, this message translates to:
  /// **'Mehr in der Datenschutzerklärung'**
  String get consentPrivacyLink;

  /// No description provided for @settingGoogleTitle.
  ///
  /// In de, this message translates to:
  /// **'Reichweitenmessung mit Google'**
  String get settingGoogleTitle;

  /// No description provided for @settingGoogleBodyOn.
  ///
  /// In de, this message translates to:
  /// **'Erlaubt. Google Analytics läuft in der Web-Version. Du kannst das jederzeit widerrufen; die Seite lädt dann einmal neu.'**
  String get settingGoogleBodyOn;

  /// No description provided for @settingGoogleBodyOff.
  ///
  /// In de, this message translates to:
  /// **'Nicht erlaubt. Die Seite lädt nichts von Google.'**
  String get settingGoogleBodyOff;

  /// No description provided for @googleConsentTitle.
  ///
  /// In de, this message translates to:
  /// **'Reichweitenmessung mit Google'**
  String get googleConsentTitle;

  /// No description provided for @googleConsentIntro.
  ///
  /// In de, this message translates to:
  /// **'Wir würden gern zählen, wie viele Menschen die Web-Version nutzen und welche Bereiche sie aufrufen. Dafür setzen wir Google Analytics ein, eingebunden über das Google-Tag.'**
  String get googleConsentIntro;

  /// No description provided for @googleConsentRecipient.
  ///
  /// In de, this message translates to:
  /// **'Anbieter ist Google Ireland Limited (Dublin, Irland). Google erhält dabei deine IP-Adresse, Angaben zu Browser und Gerät, die aufgerufenen Bereiche und eine zufällige Kennung, die in Cookies gespeichert wird. Werbefunktionen bleiben ausgeschaltet.'**
  String get googleConsentRecipient;

  /// No description provided for @googleConsentTransfer.
  ///
  /// In de, this message translates to:
  /// **'Google kann die Daten an Google LLC in den USA übermitteln. Grundlage ist das EU-US Data Privacy Framework, für das die EU-Kommission ein angemessenes Datenschutzniveau festgestellt hat.'**
  String get googleConsentTransfer;

  /// No description provided for @googleConsentOutro.
  ///
  /// In de, this message translates to:
  /// **'Diese Frage ist getrennt von Statistik und Fehlerberichten und freiwillig. Ohne deine Zustimmung lädt die Seite nichts von Google. Du kannst die Einwilligung jederzeit in den Einstellungen mit Wirkung für die Zukunft widerrufen.'**
  String get googleConsentOutro;

  /// No description provided for @legalImprintTitle.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get legalImprintTitle;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get legalPrivacyTitle;

  /// No description provided for @legalOpenInBrowser.
  ///
  /// In de, this message translates to:
  /// **'Im Browser öffnen'**
  String get legalOpenInBrowser;

  /// No description provided for @legalUpdated.
  ///
  /// In de, this message translates to:
  /// **'Stand: {date}'**
  String legalUpdated(String date);

  /// No description provided for @legalLoadError.
  ///
  /// In de, this message translates to:
  /// **'Der Text konnte nicht geladen werden.'**
  String get legalLoadError;

  /// No description provided for @aboutTitle.
  ///
  /// In de, this message translates to:
  /// **'Über LINEFM Radio'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In de, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String build, String version);

  /// No description provided for @aboutLicenses.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get aboutLicenses;

  /// No description provided for @trustGridinsoft.
  ///
  /// In de, this message translates to:
  /// **'Website-Prüfung bei Gridinsoft'**
  String get trustGridinsoft;

  /// No description provided for @trustTrustpilot.
  ///
  /// In de, this message translates to:
  /// **'Bewertungen bei Trustpilot'**
  String get trustTrustpilot;

  /// No description provided for @alarmTitle.
  ///
  /// In de, this message translates to:
  /// **'Wecker'**
  String get alarmTitle;

  /// No description provided for @alarmTime.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit'**
  String get alarmTime;

  /// No description provided for @alarmDays.
  ///
  /// In de, this message translates to:
  /// **'Wochentage'**
  String get alarmDays;

  /// No description provided for @alarmOnce.
  ///
  /// In de, this message translates to:
  /// **'Einmalig'**
  String get alarmOnce;

  /// No description provided for @alarmEveryDay.
  ///
  /// In de, this message translates to:
  /// **'Jeden Tag'**
  String get alarmEveryDay;

  /// No description provided for @alarmStation.
  ///
  /// In de, this message translates to:
  /// **'Sender'**
  String get alarmStation;

  /// No description provided for @alarmVolume.
  ///
  /// In de, this message translates to:
  /// **'Lautstärke'**
  String get alarmVolume;

  /// No description provided for @alarmSnooze.
  ///
  /// In de, this message translates to:
  /// **'Schlummern'**
  String get alarmSnooze;

  /// No description provided for @alarmSnoozeMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes, plural, =1{1 Minute} other{{minutes} Minuten}}'**
  String alarmSnoozeMinutes(int minutes);

  /// No description provided for @alarmNext.
  ///
  /// In de, this message translates to:
  /// **'Nächster Wecker: {when}'**
  String alarmNext(String when);

  /// No description provided for @alarmNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Wecker gestellt.'**
  String get alarmNone;

  /// No description provided for @alarmAdd.
  ///
  /// In de, this message translates to:
  /// **'Wecker hinzufügen'**
  String get alarmAdd;

  /// No description provided for @alarmNoteIos.
  ///
  /// In de, this message translates to:
  /// **'Auf iPhone und iPad weckt dich eine Mitteilung. Tippe darauf, um das Radio zu starten.'**
  String get alarmNoteIos;

  /// No description provided for @alarmNoteDesktop.
  ///
  /// In de, this message translates to:
  /// **'Der Wecker klingelt nur, solange LINEFM Radio läuft, auch wenn es im Tray liegt.'**
  String get alarmNoteDesktop;

  /// No description provided for @alarmNoteWeb.
  ///
  /// In de, this message translates to:
  /// **'Der Wecker klingelt nur, solange dieser Tab geöffnet ist.'**
  String get alarmNoteWeb;

  /// No description provided for @alarmNoteAndroid.
  ///
  /// In de, this message translates to:
  /// **'Dein Radio startet zur eingestellten Zeit, auch wenn die App geschlossen ist. Klappt der Stream nicht, klingelt ein Weckton.'**
  String get alarmNoteAndroid;

  /// No description provided for @alarmPermissionTitle.
  ///
  /// In de, this message translates to:
  /// **'Wecker braucht eine Freigabe'**
  String get alarmPermissionTitle;

  /// No description provided for @alarmPermissionBody.
  ///
  /// In de, this message translates to:
  /// **'Damit der Wecker pünktlich klingelt, muss Android genaue Alarme erlauben. Das stellst du in den Systemeinstellungen ein.'**
  String get alarmPermissionBody;

  /// No description provided for @alarmOpenSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get alarmOpenSettings;

  /// No description provided for @alarmRingingBody.
  ///
  /// In de, this message translates to:
  /// **'{station} läuft gleich los.'**
  String alarmRingingBody(String station);

  /// No description provided for @alarmExactMissingNote.
  ///
  /// In de, this message translates to:
  /// **'Ohne die Freigabe „Alarme und Erinnerungen“ klingelt der Wecker nicht pünktlich. Erlaube sie in den Systemeinstellungen.'**
  String get alarmExactMissingNote;

  /// No description provided for @alarmFullScreenMissingNote.
  ///
  /// In de, this message translates to:
  /// **'Ohne die Freigabe „Vollbild-Benachrichtigungen“ erscheint der Wecker nur als Mitteilung, nicht als Vollbild.'**
  String get alarmFullScreenMissingNote;

  /// No description provided for @alarmOpenFullScreenSettings.
  ///
  /// In de, this message translates to:
  /// **'Vollbild erlauben'**
  String get alarmOpenFullScreenSettings;

  /// No description provided for @alarmDismiss.
  ///
  /// In de, this message translates to:
  /// **'Ausschalten'**
  String get alarmDismiss;

  /// No description provided for @alarmNotificationTitle.
  ///
  /// In de, this message translates to:
  /// **'LINEFM Wecker'**
  String get alarmNotificationTitle;

  /// No description provided for @alarmNotificationBody.
  ///
  /// In de, this message translates to:
  /// **'{station} startet jetzt.'**
  String alarmNotificationBody(String station);

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'Mo'**
  String get weekdayShort1;

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'Di'**
  String get weekdayShort2;

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'Mi'**
  String get weekdayShort3;

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'Do'**
  String get weekdayShort4;

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'Fr'**
  String get weekdayShort5;

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'Sa'**
  String get weekdayShort6;

  /// Wochentag kurz, 1 = Montag
  ///
  /// In de, this message translates to:
  /// **'So'**
  String get weekdayShort7;

  /// No description provided for @offlineBanner.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. LINEFM versucht es weiter.'**
  String get offlineBanner;

  /// No description provided for @actionRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get actionRetry;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get loading;

  /// No description provided for @stationsOffline.
  ///
  /// In de, this message translates to:
  /// **'Die Titelinfos sind gerade nicht erreichbar.'**
  String get stationsOffline;

  /// No description provided for @castButton.
  ///
  /// In de, this message translates to:
  /// **'Auf Gerät übertragen'**
  String get castButton;

  /// No description provided for @castSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Geräten …'**
  String get castSearching;

  /// No description provided for @castNoDevices.
  ///
  /// In de, this message translates to:
  /// **'Keine Geräte gefunden.'**
  String get castNoDevices;

  /// No description provided for @castConnectedTo.
  ///
  /// In de, this message translates to:
  /// **'Verbunden mit {device}'**
  String castConnectedTo(String device);

  /// No description provided for @castDisconnect.
  ///
  /// In de, this message translates to:
  /// **'Übertragung beenden'**
  String get castDisconnect;

  /// No description provided for @airplayButton.
  ///
  /// In de, this message translates to:
  /// **'AirPlay'**
  String get airplayButton;

  /// No description provided for @notificationChannelName.
  ///
  /// In de, this message translates to:
  /// **'Wiedergabe'**
  String get notificationChannelName;

  /// Ordner im Auto-Menü (Android Auto/CarPlay): gemerkte Sender, Issue #42
  ///
  /// In de, this message translates to:
  /// **'Favoriten-Sender'**
  String get browseFavoriteStations;

  /// Ordner im Auto-Menü: alle Sender
  ///
  /// In de, this message translates to:
  /// **'Sender'**
  String get browseStations;

  /// Ordner im Auto-Menü: zuletzt gehörte Station
  ///
  /// In de, this message translates to:
  /// **'Zuletzt gehört'**
  String get browseRecent;

  /// No description provided for @widgetIdle.
  ///
  /// In de, this message translates to:
  /// **'Zum Abspielen tippen'**
  String get widgetIdle;

  /// No description provided for @trayShowWindow.
  ///
  /// In de, this message translates to:
  /// **'Fenster zeigen'**
  String get trayShowWindow;

  /// No description provided for @trayPlay.
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get trayPlay;

  /// No description provided for @trayStop.
  ///
  /// In de, this message translates to:
  /// **'Stoppen'**
  String get trayStop;

  /// No description provided for @trayStations.
  ///
  /// In de, this message translates to:
  /// **'Sender'**
  String get trayStations;

  /// No description provided for @trayMiniPlayer.
  ///
  /// In de, this message translates to:
  /// **'Mini-Player'**
  String get trayMiniPlayer;

  /// No description provided for @trayQuit.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get trayQuit;

  /// No description provided for @trayAlwaysOnTop.
  ///
  /// In de, this message translates to:
  /// **'Immer im Vordergrund'**
  String get trayAlwaysOnTop;

  /// No description provided for @actionUndo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get actionUndo;

  /// No description provided for @favoritesRemoved.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ entfernt.'**
  String favoritesRemoved(String title);

  /// Gruppe der Favoriten-Sender oben in der Senderliste
  ///
  /// In de, this message translates to:
  /// **'Deine Sender'**
  String get stationsYours;

  /// No description provided for @stationsYoursListLabel.
  ///
  /// In de, this message translates to:
  /// **'Deine Favoriten-Sender'**
  String get stationsYoursListLabel;

  /// No description provided for @settingArtworkTitle.
  ///
  /// In de, this message translates to:
  /// **'Cover laden'**
  String get settingArtworkTitle;

  /// No description provided for @settingArtworkBody.
  ///
  /// In de, this message translates to:
  /// **'Sucht zum laufenden Titel das Albumcover bei Apple. Aus: keine Anfragen an Apple, die App zeigt das Cover von laut.fm oder das Senderlogo. Diese Einstellung bleibt auch ohne bestätigten Speicher-Hinweis und nach „Speicher löschen“ gespeichert.'**
  String get settingArtworkBody;

  /// No description provided for @settingShortcutsTitle.
  ///
  /// In de, this message translates to:
  /// **'Tastenkürzel mit einer Taste'**
  String get settingShortcutsTitle;

  /// No description provided for @settingShortcutsBody.
  ///
  /// In de, this message translates to:
  /// **'F merkt den Song, S spielt einen zufälligen Sender, 1 bis 6 wählen einen Sender.'**
  String get settingShortcutsBody;

  /// No description provided for @playerSleepTimer.
  ///
  /// In de, this message translates to:
  /// **'Sleeptimer einstellen'**
  String get playerSleepTimer;

  /// No description provided for @alarmEnabledAt.
  ///
  /// In de, this message translates to:
  /// **'Wecker {time} aktiv'**
  String alarmEnabledAt(String time);

  /// No description provided for @alarmDeleteAt.
  ///
  /// In de, this message translates to:
  /// **'Wecker {time} löschen'**
  String alarmDeleteAt(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
