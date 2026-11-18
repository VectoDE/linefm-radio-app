// Uebernahme alter Web-App-Daten: bewusst ein No-Op auf allen Plattformen.
//
// Begruendung (Entscheidung 38, Runde 9): Die Flutter-Web-App laeuft unter der
// neuen Domain app.linefm.de. localStorage ist an die Origin gebunden, die
// Daten der alten Web-App (app.linecast.de) sind von hier aus nicht lesbar.
// Eine Migration waere nur noetig, wenn app.linecast.de spaeter auf dieselbe
// App zeigt; das ist nicht vorgesehen. Die Struktur (Conditional Import) und
// der Aufruf in main() bleiben erhalten, damit dieser Fall ohne Umbau
// nachgeruestet werden kann: Favoriten der Web-App liest bereits
// FavoritesLogic.decode (Format key/station/title/artist/artwork/stationLogo),
// die Schluessel stimmen mit PrefsKeys ueberein.
export 'webapp_migration_stub.dart'
    if (dart.library.js_interop) 'webapp_migration_web.dart';
