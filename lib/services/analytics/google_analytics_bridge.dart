/// Schnittstelle zu `window.linefmAnalytics` (web/analytics.js).
///
/// Die Entscheidung liegt im Web-Speicher des Browsers (localStorage, Schluessel
/// `linefm.googleAnalytics`), nicht in den App-Einstellungen: Sie gilt nur fuer
/// die Web-Version und muss schon vor dem Laden von Google feststehen.
abstract interface class GoogleAnalyticsBridge {
  /// `true` = zugestimmt, `false` = abgelehnt, `null` = noch nicht entschieden.
  bool? get decision;

  /// Uebergibt die IDs; laedt sofort, wenn schon zugestimmt wurde.
  void configure({required String gtmId, required String ga4Id});

  void grant();
  void deny();

  /// Entscheidung vergessen (Speicher loeschen), Cookies entfernen.
  void reset();
}

/// Ohne Wirkung (Tests, andere Plattformen, Seite ohne analytics.js).
class NoopGoogleAnalyticsBridge implements GoogleAnalyticsBridge {
  const NoopGoogleAnalyticsBridge();

  @override
  bool? get decision => null;

  @override
  void configure({required String gtmId, required String ga4Id}) {}

  @override
  void deny() {}

  @override
  void grant() {}

  @override
  void reset() {}
}
