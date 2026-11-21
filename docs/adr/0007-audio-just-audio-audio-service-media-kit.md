# ADR 0007: Audio mit just_audio und audio_service, media_kit auf dem Desktop

Status: angenommen
Quelle: Spec und Plan vom 18.11.2026 (Recherche-Ergebnis)

## Kontext

Die App muss einen Live-Stream abspielen, im Hintergrund weiterlaufen, über Sperrbildschirm, Medientasten, Android Auto und CarPlay steuerbar sein und auf Android, iOS, macOS, Windows, Linux und im Web laufen.

## Entscheidung

Die Wiedergabe läuft über `just_audio`, `audio_service` übernimmt Hintergrunddienst und Systemsteuerung. Auf Windows und Linux liefert `just_audio_media_kit` (libmpv) den Player. Die Mediensteuerung dort übernehmen `smtc_windows` (Windows) und `audio_service_mpris` (Linux). Unter Android läuft ein Vordergrunddienst vom Typ `mediaPlayback`. Der Titel kommt aus der API und nicht aus den ICY-Metadaten, weil diese nur auf Android, iOS und macOS verfügbar sind.

## Folgen

- Eine Codebasis für alle Plattformen, mit nativen Systemfunktionen.
- Auf dem Desktop hängt die Wiedergabe an libmpv, einer nativen Bibliothek. Sie muss mitgeliefert werden und taucht in den Lizenzen auf.
- Die Windows-Mediensteuerung braucht Rust (`flutter_rust_bridge`, festgelegte Version, siehe [ENTWICKLUNG.md](../ENTWICKLUNG.md)).
- Google verlangt für den Vordergrunddienst eine Erklärung in der Play Console ([STORE-TEXTE.md](../STORE-TEXTE.md)).
- Die Pfade für Linux und macOS sind noch nicht auf echter Hardware geprüft.

## Verworfene Alternativen

Ein eigener nativer Player je Plattform: viel Aufwand und Pflege. Nur `media_kit` überall: bietet keine Hintergrund- und Systemintegration wie `audio_service`. Beides verworfen.
