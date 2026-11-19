/// Aktuelle Adresse des Tabs; ausserhalb des Browsers nie vorhanden.
Uri? currentBrowserUri() => null;

/// Ersetzt Pfad (und Suchteil) der Adressleiste, ohne neu zu laden.
void replaceBrowserPath(String path, {String? query}) {}
