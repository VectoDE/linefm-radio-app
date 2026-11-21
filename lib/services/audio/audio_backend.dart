import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:linefm_radio/l10n/system_l10n.dart';
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/native_audio_init_io.dart'
    if (dart.library.js_interop) 'package:linefm_radio/services/audio/native_audio_init_web.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';

/// Kanal-ID der Android-Wiedergabe-Benachrichtigung.
const String audioNotificationChannelId = 'de.linefm.app.audio';

/// MPRIS-Name unter Linux (packaging/flathub, packaging/snap).
const String mprisName = 'linefm_radio';

bool get _isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

/// Einfarbiges Statusleisten-Icon (Android-Ressource aus P05).
const String audioNotificationIcon = 'drawable/ic_stat_linefm';

/// Haelt die Desktop-Medienbruecke (Windows-SMTC) am Leben.
Object? _desktopMediaControls;

/// Initialisiert das Audio-Backend (media_kit unter Windows/Linux,
/// AudioService.init, Audio-Sitzung, Windows-SMTC) und liefert den Dienst
/// fuer den ProviderScope.
Future<PlaybackService> initAudio() async {
  initNativeAudioBackend();

  LinefmAudioHandler handler;
  try {
    handler = await AudioService.init<LinefmAudioHandler>(
      builder: LinefmAudioHandler.new,
      config: AudioServiceConfig(
        // Unter Linux bildet audio_service_mpris daraus den MPRIS-Namen
        // (org.mpris.MediaPlayer2.<ID>.instance<PID>) und die Anzeige im
        // Medien-Widget; Flatpak --own-name und Snap-Slot erwarten
        // "linefm_radio".
        androidNotificationChannelId: _isLinux
            ? mprisName
            : audioNotificationChannelId,
        androidNotificationChannelName: _isLinux
            ? 'LINEFM Radio'
            : _channelName(),
        androidNotificationIcon: audioNotificationIcon,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: LinefmPalette.ink,
        // Live-Radio: kein Vor-/Zuruecksetzen per Zeitsprung.
        fastForwardInterval: const Duration(seconds: 1),
        rewindInterval: const Duration(seconds: 1),
      ),
    );
  } on Object catch (e) {
    // Ohne Systemintegration weiter abspielen statt gar nicht.
    debugPrint('AudioService.init fehlgeschlagen: $e');
    handler = LinefmAudioHandler();
  }

  try {
    await handler.initSession();
  } on Object catch (e) {
    debugPrint('Audio-Sitzung nicht konfiguriert: $e');
  }

  _desktopMediaControls ??= await attachDesktopMediaControls(handler);
  return handler;
}

/// Kanalname der Wiedergabe-Benachrichtigung aus der ARB (I07).
String _channelName() => systemLocalizations().notificationChannelName;
