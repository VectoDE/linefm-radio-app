import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Build-Konfiguration (Spec 2.4). Werte kommen per
/// --dart-define-from-file=config/app.json; fehlende Werte bleiben leer.
class AppConfig {
  const AppConfig({
    this.appEnv = 'dev',
    this.appVersion = '1.0.0',
    this.webBaseUrl = 'https://app.linefm.de',
    this.umamiUrl = '',
    this.umamiWebsiteId = '',
    this.sentryDsn = '',
    this.sentryEnvironment = '',
    this.firebaseEnabled = false,
    this.wsEnabled = false,
    this.gscVerification = '',
    this.gtmId = '',
    this.ga4MeasurementId = '',
    this.trustGridinsoftUrl = '',
    this.trustTrustpilotUrl = '',
    this.stationsUrl = '',
  });

  /// Liest die per --dart-define gesetzten Werte.
  factory AppConfig.fromEnvironment() => const AppConfig(
    appEnv: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    appVersion: String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
    webBaseUrl: String.fromEnvironment(
      'WEB_BASE_URL',
      defaultValue: 'https://app.linefm.de',
    ),
    umamiUrl: String.fromEnvironment('UMAMI_URL'),
    umamiWebsiteId: String.fromEnvironment('UMAMI_WEBSITE_ID'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
    sentryEnvironment: String.fromEnvironment('SENTRY_ENVIRONMENT'),
    firebaseEnabled: bool.fromEnvironment('FIREBASE_ENABLED'),
    wsEnabled: bool.fromEnvironment('WS_ENABLED'),
    gscVerification: String.fromEnvironment('GSC_VERIFICATION'),
    gtmId: String.fromEnvironment('GTM_ID'),
    ga4MeasurementId: String.fromEnvironment('GA4_MEASUREMENT_ID'),
    trustGridinsoftUrl: String.fromEnvironment('TRUST_GRIDINSOFT_URL'),
    trustTrustpilotUrl: String.fromEnvironment('TRUST_TRUSTPILOT_URL'),
    stationsUrl: String.fromEnvironment('STATIONS_URL'),
  );

  final String appEnv;

  /// Wird von Telemetrie (Release, User-Agent) genutzt; CI setzt APP_VERSION.
  final String appVersion;
  final String webBaseUrl;
  final String umamiUrl;
  final String umamiWebsiteId;
  final String sentryDsn;
  final String sentryEnvironment;
  final bool firebaseEnabled;

  /// laut.fm-WebSocket fuer Titelwechsel. Standard aus (Entscheidung 50:
  /// gemessen rund 130 MB/h, fast nur fremde Sender); dann ends_at-Timer
  /// plus Polling.
  final bool wsEnabled;
  final String gscVerification;

  /// Google Tag Manager (`GTM-...`) bzw. GA4 (`G-...`), nur Web (P31). Geladen
  /// wird erst nach eigener Einwilligung "Reichweitenmessung mit Google"
  /// (web/analytics.js, Consent Mode v2). Ohne gueltige ID ist alles aus.
  final String gtmId;
  final String ga4MeasurementId;
  final String trustGridinsoftUrl;
  final String trustTrustpilotUrl;

  /// Feste Adresse der nachladbaren Senderliste (Issue #91), z. B.
  /// `https://app.linefm.de/stations.json`. Leer = nur die mitgelieferte
  /// Liste, kein Netzabruf. Nur https (siehe StationsUpdater.parseUrl).
  final String stationsUrl;

  bool get umamiConfigured => umamiUrl.isNotEmpty && umamiWebsiteId.isNotEmpty;
  bool get sentryConfigured => sentryDsn.isNotEmpty;

  static final RegExp _gtmPattern = RegExp(r'^GTM-[A-Z0-9]{4,12}$');
  static final RegExp _ga4Pattern = RegExp(r'^G-[A-Z0-9]{4,16}$');

  /// Gueltige GTM-ID oder leer (gleiches Muster wie web/analytics.js und
  /// tool/web_postbuild.dart).
  String get validGtmId => _gtmPattern.hasMatch(gtmId) ? gtmId : '';
  String get validGa4Id =>
      _ga4Pattern.hasMatch(ga4MeasurementId) ? ga4MeasurementId : '';

  /// Reichweitenmessung mit Google: nur im Web und nur mit gueltiger ID.
  /// Unabhaengig von [telemetryConfigured] (eigene Einwilligung).
  bool get googleAnalyticsConfigured => kIsWeb && googleAnalyticsIdsSet;

  /// Mindestens eine gueltige ID gesetzt (ohne Plattformpruefung).
  bool get googleAnalyticsIdsSet =>
      validGtmId.isNotEmpty || validGa4Id.isNotEmpty;

  /// Firebase nur dort, wo `LinefmFirebase.supported` es zulaesst (Web,
  /// Android, iOS, macOS). Auf Windows und Linux startet kein Firebase, also
  /// duerfen Einwilligung und Datenschutzerklaerung dort auch keine Google-
  /// bzw. USA-Angaben machen (R4-S05). Muss mit
  /// `packages/linefm_firebase` gleich bleiben (Test in app_config_test).
  static bool get firebasePlatformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  bool get firebaseConfigured => firebaseEnabled && firebasePlatformSupported;

  /// Ist false: kein Einwilligungsdialog, keine Sinks, NoOp-Hub.
  bool get telemetryConfigured =>
      umamiConfigured || sentryConfigured || firebaseConfigured;

  AppConfig copyWith({
    String? appEnv,
    String? appVersion,
    String? webBaseUrl,
    String? umamiUrl,
    String? umamiWebsiteId,
    String? sentryDsn,
    String? sentryEnvironment,
    bool? firebaseEnabled,
    bool? wsEnabled,
    String? gscVerification,
    String? gtmId,
    String? ga4MeasurementId,
    String? trustGridinsoftUrl,
    String? trustTrustpilotUrl,
    String? stationsUrl,
  }) => AppConfig(
    appEnv: appEnv ?? this.appEnv,
    appVersion: appVersion ?? this.appVersion,
    webBaseUrl: webBaseUrl ?? this.webBaseUrl,
    umamiUrl: umamiUrl ?? this.umamiUrl,
    umamiWebsiteId: umamiWebsiteId ?? this.umamiWebsiteId,
    sentryDsn: sentryDsn ?? this.sentryDsn,
    sentryEnvironment: sentryEnvironment ?? this.sentryEnvironment,
    firebaseEnabled: firebaseEnabled ?? this.firebaseEnabled,
    wsEnabled: wsEnabled ?? this.wsEnabled,
    gscVerification: gscVerification ?? this.gscVerification,
    gtmId: gtmId ?? this.gtmId,
    ga4MeasurementId: ga4MeasurementId ?? this.ga4MeasurementId,
    trustGridinsoftUrl: trustGridinsoftUrl ?? this.trustGridinsoftUrl,
    trustTrustpilotUrl: trustTrustpilotUrl ?? this.trustTrustpilotUrl,
    stationsUrl: stationsUrl ?? this.stationsUrl,
  );
}
