/// Aktuelle Adresse des Tabs; ausserhalb des Browsers nie vorhanden.
Uri? currentBrowserUri() => null;

/// Setzt Pfad (und Suchteil) der Adressleiste, ohne neu zu laden. [push]
/// legt einen neuen Verlaufseintrag an (Zurueck-Taste), sonst wird ersetzt.
void setBrowserPath(String path, {String? query, bool push = false}) {}

/// Zurueck/Vor im Browser; [onChange] bekommt den neuen Pfad. Liefert die
/// Abmeldung.
void Function() listenBrowserPop(void Function(String path) onChange) => () {};
