import 'dart:ui' show Color, PlatformDispatcher;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:linefm_radio/services/audio/audio_handler.dart';
import 'package:linefm_radio/services/audio/native_audio_init_io.dart'
    if (dart.library.js_interop) 'package:linefm_radio/services/audio/native_audio_init_web.dart';
import 'package:linefm_radio/services/audio/playback_service.dart';

/// Kanal-ID der Android-Wiedergabe-Benachrichtigung.
const String audioNotificationChannelId = 'de.linefm.app.audio';

/// Benachrichtigungs-Icon (Android-Ressource). Platzhalter bis P05 ein
/// eigenes einfarbiges Statusleisten-Icon liefert (z. B. drawable/ic_stat_linefm).
const String audioNotificationIcon = 'mipmap/ic_launcher';

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
        androidNotificationChannelId: audioNotificationChannelId,
        androidNotificationChannelName: _channelName(),
        androidNotificationIcon: audioNotificationIcon,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        notificationColor: const Color(0xFF0F1221),
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

String _channelName() => PlatformDispatcher.instance.locale.languageCode == 'de'
    ? 'Wiedergabe'
    : 'Playback';
