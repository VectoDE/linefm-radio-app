import 'package:linefm_radio/services/cast/cast_backend.dart';

/// Web: kein Cast (Chrome-Web bräuchte das Cast-Sender-SDK und damit ein
/// zusätzliches Paket, siehe P19-Bericht).
Future<CastBackend?> createPluginBackend() async => null;
