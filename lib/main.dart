import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/data/storage/webapp_migration.dart';
import 'package:linefm_radio/platform/carplay_bridge.dart';
import 'package:linefm_radio/platform/deep_links.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/desktop_init.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/audio/audio_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';
import 'package:linefm_radio/ui/theme/font_licenses.dart';

/// Bootstrap in fester Reihenfolge (Besitz P01, danach P11/P28):
/// Bindings, Schrift-Lizenzen, Konfiguration, Audio, CarPlay, Desktop,
/// Speicher, Telemetrie (samt Absturz-Handlern), Wecker, Cast, Widget,
/// Deep Links, runApp mit den echten Diensten.
///
/// [args]: Startargumente unter Windows und Linux, z. B.
/// `linefm://play?station=linefmrap` (Protokoll-Aktivierung, Startmenue).
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final appConfig = AppConfig.fromEnvironment();
  final playback = await initAudio();
  // CarPlay direkt nach dem Audio: Start nur ueber CarPlay hat sofort Menue.
  await initCarPlay(playback);
  await initDesktop();
  // Links eines zweiten Programmstarts (Windows-Single-Instance).
  DesktopController.instance.secondInstanceArgs.listen(
    DeepLinks.dispatchFromArguments,
  );
  final prefs = await createPrefsStore();
  await migrateWebappData(prefs);
  final telemetry = await initTelemetry(config: appConfig, prefs: prefs);
  telemetry.installCrashHandlers();
  await initAlarm();
  await initCast();
  await initHomeWidget();
  await initDeepLinks();
  DeepLinks.dispatchFromArguments(args);
  runApp(
    ProviderScope(
      overrides: productionOverrides(
        config: appConfig,
        prefs: prefs,
        playback: playback,
        telemetry: telemetry,
      ),
      child: const LinefmApp(),
    ),
  );
}
