import 'package:linefm_radio/services/audio/playback_service.dart';

/// Initialisiert den Audio-Backend (media_kit unter Windows/Linux,
/// AudioService.init) und liefert den Dienst fuer den ProviderScope.
/// Stub: liefert [NoopPlaybackService]. Echte Implementierung: P10.
Future<PlaybackService> initAudio() async => NoopPlaybackService();
