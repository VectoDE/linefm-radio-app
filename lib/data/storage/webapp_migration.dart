// Einmalige Uebernahme der Web-App-Daten (Spec 2.2). Auf Web per
// package:web (window.localStorage), sonst No-Op. Implementierung: P06.
export 'webapp_migration_stub.dart'
    if (dart.library.js_interop) 'webapp_migration_web.dart';
