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
    this.trustGridinsoftUrl = '',
    this.trustTrustpilotUrl = '',
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
    trustGridinsoftUrl: String.fromEnvironment('TRUST_GRIDINSOFT_URL'),
    trustTrustpilotUrl: String.fromEnvironment('TRUST_TRUSTPILOT_URL'),
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
  final String trustGridinsoftUrl;
  final String trustTrustpilotUrl;

  bool get umamiConfigured => umamiUrl.isNotEmpty && umamiWebsiteId.isNotEmpty;
  bool get sentryConfigured => sentryDsn.isNotEmpty;
  bool get firebaseConfigured => firebaseEnabled;

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
    String? trustGridinsoftUrl,
    String? trustTrustpilotUrl,
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
    trustGridinsoftUrl: trustGridinsoftUrl ?? this.trustGridinsoftUrl,
    trustTrustpilotUrl: trustTrustpilotUrl ?? this.trustTrustpilotUrl,
  );
}
