import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';

/// Standard: keine Firebase-Sinks. tool/enable_firebase.dart (P07) ersetzt
/// diese Datei durch die echte Variante aus packages/linefm_firebase.
({AnalyticsSink? analytics, CrashSink? crash}) registerFirebase(
  AppConfig config,
) => (analytics: null, crash: null);
