// Waehlt je Plattform die Wecker-Ausfuehrung. Web kennt dart:io und das Paket
// `alarm` nicht und bekommt deshalb eine eigene Datei.
export 'package:linefm_radio/services/alarm/alarm_platform_io.dart'
    if (dart.library.js_interop) 'package:linefm_radio/services/alarm/alarm_platform_web.dart';
