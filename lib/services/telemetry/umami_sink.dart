import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/services/telemetry/telemetry.dart';

/// Umami (selbst gehostet oder Cloud) ueber `POST {UMAMI_URL}/api/send`
/// (Spec 2.3).
///
/// Datensparsam: keine Cookies, keine Geraete- oder Nutzer-IDs. Ereignisse
/// landen in einer Warteschlange (max. 50) und werden gebuendelt alle 30 s
/// gesendet. Schlaegt der Versand fehl (offline), wird der Rest verworfen.
/// Ohne Einwilligung ([setEnabled] mit `true`) wird nichts gespeichert und
/// nichts gesendet.
class UmamiSink implements AnalyticsSink {
  UmamiSink(
    this.config, {
    http.Client? client,
    this.flushInterval = const Duration(seconds: 30),
    this.maxQueue = 50,
    this.hostname = 'app.linefm',
    String Function()? screenSize,
    String Function()? language,
    String? userAgent,
  }) : _client = client ?? http.Client(),
       _screenSize = screenSize ?? _defaultScreenSize,
       _language = language ?? _defaultLanguage,
       // ignore: prefer_initializing_formals
       _userAgent = userAgent;

  final AppConfig config;
  final Duration flushInterval;
  final int maxQueue;
  final String hostname;
  final http.Client _client;
  final String Function() _screenSize;
  final String Function() _language;
  final String? _userAgent;

  final List<Map<String, Object?>> _queue = <Map<String, Object?>>[];
  Timer? _timer;
  bool _enabled = false;
  String _currentUrl = '/';

  /// Anzahl wartender Ereignisse (fuer Tests).
  @visibleForTesting
  int get pending => _queue.length;

  Uri get _endpoint {
    final base = config.umamiUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/api/send');
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _timer = Timer.periodic(flushInterval, (_) => unawaited(flush()));
    } else {
      _timer?.cancel();
      _timer = null;
      _queue.clear();
    }
  }

  @override
  Future<void> screen(String name) async {
    if (!_enabled) return;
    _currentUrl = '/screen/$name';
    _enqueue(<String, Object?>{'url': _currentUrl});
  }

  @override
  Future<void> event(
    String name, [
    Map<String, Object> props = const {},
  ]) async {
    if (!_enabled) return;
    _enqueue(<String, Object?>{
      'url': _currentUrl,
      'name': name,
      if (props.isNotEmpty) 'data': props,
    });
  }

  void _enqueue(Map<String, Object?> part) {
    if (_queue.length >= maxQueue) _queue.removeAt(0);
    _queue.add(<String, Object?>{
      'website': config.umamiWebsiteId,
      'hostname': hostname,
      'language': _language(),
      'screen': _screenSize(),
      ...part,
    });
  }

  /// Sendet die Warteschlange. Fehler verwerfen den Rest (offline).
  Future<void> flush() async {
    if (!_enabled || _queue.isEmpty) return;
    final batch = List<Map<String, Object?>>.of(_queue);
    _queue.clear();
    final headers = <String, String>{'Content-Type': 'application/json'};
    final agent = _userAgent ?? _defaultUserAgent(config);
    // Browser verbieten das Setzen des User-Agent-Headers.
    if (!kIsWeb) headers['User-Agent'] = agent;
    for (final payload in batch) {
      try {
        final response = await _client
            .post(
              _endpoint,
              headers: headers,
              body: jsonEncode(<String, Object?>{
                'type': 'event',
                'payload': payload,
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode >= 400) {
          debugPrint('Umami: HTTP ${response.statusCode}, Rest verworfen');
          return;
        }
      } on Object catch (e) {
        debugPrint('Umami: Versand fehlgeschlagen ($e), Rest verworfen');
        return;
      }
    }
  }

  static String _defaultUserAgent(AppConfig config) =>
      'LINEFM-Radio/${config.appVersion} (${defaultTargetPlatform.name})';

  static String _defaultScreenSize() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return '0x0';
    final size = views.first.physicalSize / views.first.devicePixelRatio;
    return '${size.width.round()}x${size.height.round()}';
  }

  static String _defaultLanguage() =>
      ui.PlatformDispatcher.instance.locale.toLanguageTag();
}
