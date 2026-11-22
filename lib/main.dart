import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/app.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/core/perf/perf_marks.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/data/storage/webapp_migration.dart';
import 'package:linefm_radio/l10n/system_l10n.dart';
import 'package:linefm_radio/platform/carplay_bridge.dart';
import 'package:linefm_radio/platform/deep_links.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/desktop_init.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/services/audio/audio_backend.dart';
import 'package:linefm_radio/services/telemetry/telemetry_hub.dart';
import 'package:linefm_radio/services/widgets/home_widget_sync.dart';
import 'package:linefm_radio/ui/theme/font_licenses.dart';
import 'package:linefm_radio/ui/theme/native_licenses.dart';

/// Bootstrap (Besitz P01, danach P11/P28), unabhaengige Schritte parallel:
/// Bindings, Schrift-Lizenzen, Konfiguration, Audio, CarPlay, Desktop,
/// Speicher, Telemetrie (samt Absturz-Handlern), Wecker, Widget,
/// Deep Links, runApp mit den echten Diensten.
///
/// [args]: Startargumente unter Windows und Linux, z. B.
/// `linefm://play?station=linefmrap` (Protokoll-Aktivierung, Startmenue).
Future<void> main(List<String> args) async {
  // Messpunkte (#92) nur mit --dart-define=LINEFM_PERF_MARKS=true, sonst entfernt.
  perfMark('main');
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  registerNativeLicenses();
  final appConfig = AppConfig.fromEnvironment();
  // Unabhaengige Schritte parallel (P30-13): Speicher oeffnen und Web-App-
  // Daten uebernehmen laeuft, waehrend Audio und CarPlay starten.
  final prefsReady = () async {
    final store = await createPrefsStore();
    await migrateWebappData(store);
    perfMark('prefs-ready');
    return store;
  }();
  final playback = await initAudio();
  perfMark('audio-ready');
  // CarPlay direkt nach dem Audio: Start nur ueber CarPlay hat sofort Menue.
  await initCarPlay(playback);
  await initDesktop();
  perfMark('desktop-ready');
  // Links eines zweiten Programmstarts (Windows-Single-Instance).
  DesktopController.instance.secondInstanceArgs.listen(
    DeepLinks.dispatchFromArguments,
  );
  final prefs = await prefsReady;
  // Gewaehlte Sprache fuer Texte ohne BuildContext (Wecker, Tray, Auto-Menue).
  appLanguageOverride = prefs.readSettings().language.code;
  final telemetry = await initTelemetry(config: appConfig, prefs: prefs);
  telemetry.installCrashHandlers();
  perfMark('telemetry-ready');
  await Future.wait(<Future<void>>[initAlarm(), initHomeWidget()]);
  await initDeepLinks();
  DeepLinks.dispatchFromArguments(args);
  perfMark('run-app');
  if (kPerfMarks) {
    WidgetsBinding.instance.waitUntilFirstFrameRasterized
        .then((_) => perfMark('first-frame'))
        .ignore();
  }
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
