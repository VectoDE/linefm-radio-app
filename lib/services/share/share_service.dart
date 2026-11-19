import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/favorites/favorites_export.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/track.dart';

/// Teilen, Export, Musikdienst-Links (Spec 2.2). Echte Implementierung:
/// `SystemShareService`.
///
/// Fehler werden als Ausnahme gemeldet; der Aufrufer zeigt den passenden
/// Hinweis. Rueckmeldungen bei Erfolg ("In die Zwischenablage kopiert",
/// "Gespeichert unter ...") sendet der Dienst selbst ueber `ShareFeedbackBus`.
abstract interface class ShareService {
  /// Teilt "Ich hoere gerade ..." samt Link auf den Sender.
  Future<void> shareSong(Station station, Track track);

  /// Teilt einen fertigen Text (z. B. "Sender teilen").
  Future<void> shareText(String text);

  /// Exportiert die Favoriten als Datei (CSV bzw. Text): mobil ueber das
  /// Teilen-Menue, Web als Download, Linux/Desktop im Download-Ordner.
  Future<void> exportFavorites(List<Favorite> favorites, ExportFormat format);

  /// Oeffnet einen Link ausserhalb der App (Musikdienste).
  Future<void> openUrl(Uri uri);
}

class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<void> shareSong(Station station, Track track) async {}

  @override
  Future<void> shareText(String text) async {}

  @override
  Future<void> exportFavorites(
    List<Favorite> favorites,
    ExportFormat format,
  ) async {}

  @override
  Future<void> openUrl(Uri uri) async {}
}
