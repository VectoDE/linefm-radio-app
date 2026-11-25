import 'dart:ui' show Locale;

import 'context.dart' show HostOs;

/// Texte der Setup-Oberfläche auf Deutsch und Englisch. Sprache folgt der
/// Windows-Anzeigesprache (Deutsch für `de`, sonst Englisch).
class S {
  const S._(this.de, [this.os = HostOs.windows]);

  static const S german = S._(true);
  static const S english = S._(false);

  static S forLocale(Locale? locale, [HostOs os = HostOs.windows]) =>
      S._(locale?.languageCode == 'de', os);

  final bool de;

  /// Operating system; only OS-specific wording differs, never the steps.
  final HostOs os;

  @override
  bool operator ==(Object other) =>
      other is S && other.de == de && other.os == os;

  @override
  int get hashCode => Object.hash(de, os);

  String _t(String german, String english) => de ? german : english;

  /// Picks the Windows, macOS or Linux variant of a text.
  String _os(String windows, String macos, String linux) => switch (os) {
    HostOs.windows => windows,
    HostOs.macos => macos,
    HostOs.linux => linux,
  };

  /// "PC", "Mac" or "computer" in running text.
  String get _device => _os('PC', 'Mac', _t('Computer', 'computer'));

  String get languageCode => de ? 'de' : 'en';

  // Fenster und Schritte
  String windowTitle(String product) => _t('$product Setup', '$product Setup');
  String uninstallTitle(String product) =>
      _t('$product deinstallieren', 'Uninstall $product');
  String get windowMinimize => _t('Minimieren', 'Minimise');
  String get windowClose => _t('Schließen', 'Close');
  String get stepWelcome => _t('Willkommen', 'Welcome');
  String get stepLicense => _t('Lizenz', 'Licence');
  String get stepOptions => _t('Optionen', 'Options');
  String get stepProgress => _t('Installation', 'Installing');
  String get stepDone => _t('Fertig', 'Done');
  String get stepConfirm => _t('Bestätigen', 'Confirm');
  String get stepRemoving => _t('Entfernen', 'Removing');
  String stepOf(int current, int total) =>
      _t('Schritt $current von $total', 'Step $current of $total');
  String get stepsLabel => _t('Schritte', 'Steps');

  // Knöpfe
  String get next => _t('Weiter', 'Next');
  String get back => _t('Zurück', 'Back');
  String get cancel => _t('Abbrechen', 'Cancel');
  String get install => _t('Installieren', 'Install');
  String get update => _t('Aktualisieren', 'Update');
  String get uninstall => _t('Deinstallieren', 'Uninstall');
  String get finish => _t('Fertig', 'Finish');
  String get close => _t('Schließen', 'Close');
  String get browse => _t('Durchsuchen …', 'Browse …');
  String get retry => _t('Erneut versuchen', 'Try again');

  // Willkommen
  String welcomeHeading(String product) =>
      _t('$product installieren', 'Install $product');
  String welcomeBody(String product) => _t(
    'Alle Sender von $product auf deinem $_device: live hören, Favoriten '
        'speichern, Wecker und Schlaftimer stellen. Das Setup dauert nur '
        'einen Moment.',
    'All $product stations on your $_device: listen live, save favourites, set an '
        'alarm or a sleep timer. Setup only takes a moment.',
  );
  String updateHeading(String product) =>
      _t('$product aktualisieren', 'Update $product');
  String updateBody(String product, String from, String to) => _t(
    'Version $from ist installiert. Das Setup bringt $product auf Version '
        '$to. Deine Einstellungen, Favoriten und Wecker bleiben erhalten.',
    'Version $from is installed. Setup will update $product to version $to. '
        'Your settings, favourites and alarms are kept.',
  );
  String sameVersionBody(String product, String version) => _t(
    'Version $version ist bereits installiert. Du kannst sie neu '
        'installieren, deine Einstellungen bleiben erhalten.',
    'Version $version is already installed. You can reinstall it; your '
        'settings are kept.',
  );
  String downgradeBody(String installed, String offered) => _t(
    'Auf diesem $_device ist bereits die neuere Version $installed installiert. '
        'Dieses Setup enthält Version $offered und wird deshalb nicht '
        'ausgeführt.',
    'The newer version $installed is already installed on this $_device. This '
        'setup contains version $offered and will not run.',
  );
  String versionLine(String version) =>
      _t('Version $version', 'Version $version');
  String publisherLine(String publisher) =>
      _t('Herausgeber: $publisher', 'Publisher: $publisher');
  String manufacturerLine(String manufacturer) =>
      _t('Hersteller: $manufacturer', 'Developer: $manufacturer');
  String sizeLine(String size) =>
      _t('Benötigter Speicher: $size', 'Disk space required: $size');

  // Lizenz
  String get licenseHeading => _t('Lizenzbedingungen', 'Licence terms');
  String get licenseIntro => _t(
    'Bitte lies die Bedingungen. Zum Installieren musst du ihnen zustimmen.',
    'Please read the terms. You need to accept them to install.',
  );
  String get licenseAccept =>
      _t('Ich akzeptiere die Lizenzbedingungen', 'I accept the licence terms');
  String get licenseMissing => _t(
    'Der Lizenztext fehlt in diesem Setup. Die Bedingungen stehen unter '
        'https://github.com/VectoDE/linefm-radio-app/blob/main/LICENSE.',
    'The licence text is missing from this setup. The terms are available '
        'at https://github.com/VectoDE/linefm-radio-app/blob/main/LICENSE.',
  );

  // Optionen
  String get optionsHeading =>
      _t('Wie soll installiert werden?', 'How should it be installed?');
  String get scopeLabel => _t('Installieren für', 'Install for');
  String get scopeUser => _t('Nur für mich', 'Just me');
  String get scopeUserHint => _t(
    'Empfohlen. Keine Administratorrechte nötig.',
    'Recommended. No administrator rights needed.',
  );
  String get scopeMachine => _os(
    _t('Alle Benutzer dieses PCs', 'Everyone on this PC'),
    _t('Alle Benutzer dieses Macs', 'Everyone on this Mac'),
    _t('Alle Benutzer dieses Computers', 'Everyone on this computer'),
  );
  String get scopeMachineHint => _os(
    _t(
      'Windows fragt nach Administratorrechten.',
      'Windows will ask for administrator rights.',
    ),
    _t(
      'macOS fragt nach dem Passwort eines Administrators.',
      'macOS will ask for an administrator password.',
    ),
    _t(
      'Linux fragt nach dem Passwort eines Administrators.',
      'Linux will ask for an administrator password.',
    ),
  );
  String get scopeLocked => _t(
    'Beim Aktualisieren bleiben Bereich und Ordner der vorhandenen '
        'Installation.',
    'When updating, the existing installation keeps its scope and folder.',
  );
  String get folderLabel => _t('Zielordner', 'Destination folder');
  String get folderPickTitle =>
      _t('Zielordner wählen', 'Choose destination folder');
  String get folderEmpty => _t(
    'Bitte einen Zielordner angeben.',
    'Please enter a destination folder.',
  );
  String get folderInvalid => _os(
    _t(
      'Bitte einen vollständigen Pfad mit Laufwerk angeben, z. B. C:\\Programme\\LINEFM Radio.',
      'Please enter a full path including the drive, e.g. C:\\Program Files\\LINEFM Radio.',
    ),
    _t(
      'Bitte einen vollständigen Pfad angeben, der auf .app endet, z. B. /Applications/LINEFM Radio.app.',
      'Please enter a full path ending in .app, e.g. /Applications/LINEFM Radio.app.',
    ),
    _t(
      'Bitte einen vollständigen Pfad in deinem Home-Ordner angeben, z. B. ~/.local/share/linefm-radio.',
      'Please enter a full path inside your home folder, e.g. ~/.local/share/linefm-radio.',
    ),
  );
  String get shortcutsLabel =>
      _t('Verknüpfungen und Start', 'Shortcuts and start-up');
  String get desktopShortcut => _os(
    _t('Verknüpfung auf dem Desktop', 'Desktop shortcut'),
    _t('Alias auf dem Schreibtisch', 'Alias on the desktop'),
    _t('Verknüpfung auf dem Desktop', 'Desktop shortcut'),
  );
  String get startMenuShortcut => _os(
    _t('Eintrag im Startmenü', 'Start menu entry'),
    _t('Im Dock behalten', 'Keep in the Dock'),
    _t('Eintrag im App-Menü', 'App menu entry'),
  );
  String get autostart => _t(
    'Beim Anmelden automatisch starten',
    'Start automatically when I sign in',
  );
  String get linkSchemeNote => _t(
    'Links wie linefm://play öffnen danach direkt die App.',
    'Links such as linefm://play will open the app directly.',
  );
  String get elevationDenied => _t(
    'Ohne Administratorrechte geht die Installation für alle Benutzer nicht. '
        '${_os('Wähle „Nur für mich“ oder bestätige die Windows-Abfrage.', 'Wähle „Nur für mich“ oder gib das Administratorpasswort ein.', 'Wähle „Nur für mich“ oder gib das Administratorpasswort ein.')}',
    'Installing for everyone needs administrator rights. '
        '${_os('Choose “Just me” or confirm the Windows prompt.', 'Choose “Just me” or enter the administrator password.', 'Choose “Just me” or enter the administrator password.')}',
  );
  String get startFailed => _t(
    'Das Setup konnte nicht starten. Bitte lade die Datei erneut herunter.',
    'Setup could not start. Please download the file again.',
  );

  // Fortschritt
  String progressHeading(String product) =>
      _t('$product wird installiert', 'Installing $product');
  String removingHeading(String product) =>
      _t('$product wird entfernt', 'Removing $product');
  String phase(String name) => switch (name) {
    'prepare' => _t('Vorbereiten …', 'Preparing …'),
    'closing' => _t('App wird beendet …', 'Closing the app …'),
    'copying' => _t('Dateien werden kopiert …', 'Copying files …'),
    'registry' => _os(
      _t('Windows wird eingerichtet …', 'Setting up Windows …'),
      _t('macOS wird eingerichtet …', 'Setting up macOS …'),
      _t('Desktop wird eingerichtet …', 'Setting up the desktop …'),
    ),
    'finalizing' => _t('Abschließen …', 'Finishing …'),
    'elevating' => _t(
      'Warte auf die Administratorrechte …',
      'Waiting for administrator rights …',
    ),
    'rollback' => _t('Änderungen werden zurückgenommen …', 'Undoing changes …'),
    'removing' => _t('Dateien werden entfernt …', 'Removing files …'),
    _ => _t('Bitte warten …', 'Please wait …'),
  };
  String percent(int value) => _t('$value Prozent', '$value percent');

  String _clockText(Duration d) {
    final m = d.inMinutes;
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  String elapsed(Duration d) =>
      _t('Bisher ${_clockText(d)}', 'Elapsed ${_clockText(d)}');

  String remaining(Duration? d) {
    if (d == null) {
      return _t('Restzeit wird berechnet …', 'Estimating time left …');
    }
    if (d.inSeconds < 60) {
      return _t('Noch weniger als eine Minute', 'Less than a minute left');
    }
    final minutes = (d.inSeconds / 60).ceil();
    return _t(
      'Noch etwa $minutes ${minutes == 1 ? 'Minute' : 'Minuten'}',
      'About $minutes ${minutes == 1 ? 'minute' : 'minutes'} left',
    );
  }

  String get waitingForWindows => _t(
    'Warte auf die Bestätigung in ${_os('Windows', 'macOS', 'Linux')} …',
    'Waiting for confirmation in ${_os('Windows', 'macOS', 'Linux')} …',
  );

  // Laufende App
  String get runningHeading =>
      _t('LINEFM Radio läuft noch', 'LINEFM Radio is still running');
  String runningBody(String apps) => _t(
    'Zum Fortfahren muss das Setup diese Programme beenden: $apps. Nicht '
        'gespeicherte Änderungen gibt es in der App nicht, die Wiedergabe '
        'stoppt.',
    'To continue, setup needs to close: $apps. The app has no unsaved '
        'changes; playback will stop.',
  );
  String get runningClose => _t('Beenden und fortfahren', 'Close and continue');

  // Abbrechen
  String get cancelHeading => _t('Setup abbrechen?', 'Cancel setup?');
  String get cancelBody => _t(
    'Alle bisherigen Änderungen werden zurückgenommen.',
    'All changes made so far will be undone.',
  );
  String get cancelYes => _t('Ja, abbrechen', 'Yes, cancel');
  String get cancelNo => _t('Weitermachen', 'Continue');

  // Fertig
  String doneHeading(String product) =>
      _t('$product ist installiert', '$product is installed');
  String updatedHeading(String product) =>
      _t('$product ist aktualisiert', '$product has been updated');
  String doneBody(String dir) => _t('Installiert in $dir', 'Installed in $dir');
  String get launchNow =>
      _t('LINEFM Radio jetzt starten', 'Start LINEFM Radio now');
  String get launchFailed => _t(
    'Die App ließ sich nicht starten. Du findest sie '
        '${_os('im Startmenü', 'im Launchpad und im Ordner „Programme“', 'im App-Menü')}.',
    'The app could not be started. You will find it '
        '${_os('in the Start menu', 'in Launchpad and the Applications folder', 'in the app menu')}.',
  );
  String get failedHeading => _t('Das hat nicht geklappt', 'That did not work');
  String get cancelledHeading => _t('Abgebrochen', 'Cancelled');
  String get cancelledBody =>
      _t('Es wurde nichts verändert.', 'Nothing was changed.');
  String get details => _t('Details', 'Details');
  String exitCodeLine(int code) => _t('Exit-Code $code', 'Exit code $code');

  String error(int code) => switch (code) {
    1 => _t('Ungültige Parameter.', 'Invalid parameters.'),
    3 => _t('Die Installation ist fehlgeschlagen.', 'Installation failed.'),
    4 => _t(
      'Die Setup-Datei ist beschädigt. Bitte lade sie erneut herunter.',
      'The setup file is damaged. Please download it again.',
    ),
    5 => _t(
      'LINEFM Radio läuft noch. Bitte beende die App und versuche es erneut.',
      'LINEFM Radio is still running. Please close the app and try again.',
    ),
    6 => _t(
      'Eine neuere Version ist bereits installiert.',
      'A newer version is already installed.',
    ),
    7 => _t(
      'Dafür sind Administratorrechte nötig.',
      'Administrator rights are required.',
    ),
    8 => _t(
      'Der Zielordner ist nicht geeignet.',
      'The destination folder is not suitable.',
    ),
    9 => _t(
      'Nicht alle Änderungen ließen sich zurücknehmen. Details stehen unten.',
      'Not all changes could be undone. See the details below.',
    ),
    10 => _t(
      'LINEFM Radio ist nicht (mehr) installiert.',
      'LINEFM Radio is not installed (anymore).',
    ),
    11 => _t(
      'Auf dem Laufwerk ist nicht genug Platz.',
      'There is not enough space on the drive.',
    ),
    12 => _t(
      'LINEFM Radio ist bereits in einem anderen Bereich installiert '
          '(nur für mich bzw. alle Benutzer). Bitte deinstalliere es zuerst.',
      'LINEFM Radio is already installed in another scope (just me or '
          'everyone). Please uninstall it first.',
    ),
    _ => _t('Unbekannter Fehler.', 'Unknown error.'),
  };

  // Deinstallation
  String uninstallHeading(String product) =>
      _t('$product deinstallieren?', 'Uninstall $product?');
  String uninstallBody(String product, String version, String dir) => _t(
    '$product $version wird aus $dir entfernt, dazu die Verknüpfungen und '
        'die Einträge in ${_os('Windows', 'macOS', 'der Desktop-Umgebung')}.',
    '$product $version will be removed from $dir, together with its '
        'shortcuts and ${_os('Windows entries', 'macOS entries', 'desktop entries')}.',
  );
  String get deleteUserData => _t(
    'Auch meine Einstellungen, Favoriten und Wecker löschen',
    'Also delete my settings, favourites and alarms',
  );
  String get deleteUserDataHint => _t(
    'Ohne Haken bleiben sie für eine spätere Installation erhalten.',
    'If unticked, they are kept for a later installation.',
  );
  String uninstalledHeading(String product) =>
      _t('$product ist entfernt', '$product has been removed');
  String get uninstalledKept => _t(
    'Deine Einstellungen und Favoriten bleiben gespeichert.',
    'Your settings and favourites are still saved.',
  );
  String get uninstalledDeleted => _t(
    'Auch deine Einstellungen und Favoriten wurden gelöscht.',
    'Your settings and favourites were deleted as well.',
  );

  String formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    final text = mb >= 10 ? mb.toStringAsFixed(0) : mb.toStringAsFixed(1);
    return '${de ? text.replaceAll('.', ',') : text} MB';
  }
}
