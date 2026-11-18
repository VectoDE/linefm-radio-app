import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/data/storage/webapp_migration.dart';
import 'package:linefm_radio/platform/deep_links.dart';
import 'package:linefm_radio/platform/desktop/desktop_init.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/audio/audio_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';

/// Bootstrap in fester Reihenfolge (Besitz P01, danach P28):
/// Bindings, Konfiguration, Audio, Desktop, Speicher, Telemetrie, Wecker,
/// Cast, Widget, Deep Links, runApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appConfig = AppConfig.fromEnvironment();
  final playback = await initAudio();
  await initDesktop();
  final prefs = await createPrefsStore();
  await migrateWebappData(prefs);
  final telemetry = await initTelemetry(config: appConfig, prefs: prefs);
  await initAlarm();
  await initCast();
  await initHomeWidget();
  await initDeepLinks();
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
        prefsProvider.overrideWithValue(prefs),
        playbackServiceProvider.overrideWithValue(playback),
        telemetryProvider.overrideWithValue(telemetry),
      ],
      child: const LinefmApp(),
    ),
  );
}
