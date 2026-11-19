/// Der vorlaeufige Dienst aus P11 ist durch die echte Implementierung aus P21
/// ersetzt (`lib/services/share/system_share_service.dart`). Diese Datei
/// bleibt nur, damit `providers.dart` unveraendert baut; P28 stellt den Import
/// dort auf den neuen Pfad um und loescht sie.
library;

export 'package:linefm_radio/services/share/system_share_service.dart'
    show SystemShareService;
