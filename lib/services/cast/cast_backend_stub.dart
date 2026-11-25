import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/browser_cast_bridge.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';

/// Web (and platforms without dart:io): Google Cast web sender, loaded only
/// after consent (web/cast.js). Elsewhere the bridge is a no-op and this
/// returns `null`.
Future<CastBackend?> createPluginBackend() =>
    createBrowserCastBackend(createBrowserCastBridge());
