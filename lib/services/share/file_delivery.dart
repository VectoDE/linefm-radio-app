/// Dateien ausliefern, die nicht ueber das Teilen-Menue gehen:
/// Web = Browser-Download, Desktop = Download-Ordner.
///
/// Je Plattform eine Datei (Auswahl per bedingtem Export):
/// `file_delivery_web.dart`, `file_delivery_io.dart`, `file_delivery_stub.dart`.
library;

export 'file_delivery_stub.dart'
    if (dart.library.js_interop) 'file_delivery_web.dart'
    if (dart.library.io) 'file_delivery_io.dart';
