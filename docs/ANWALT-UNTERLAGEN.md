# Unterlagen für die anwaltliche Prüfung

Stand: 27.11.2026. Diese Mappe sammelt, was ein Anwalt vor der Veröffentlichung von LINEFM Radio (App-Stores, Web-Version unter app.linefm.de, Windows- und Linux-Pakete) prüfen soll. Sie ist eine technische Zusammenstellung des Entwicklers und keine Rechtsberatung.

## Beteiligte

| Rolle | Wer |
|---|---|
| Hersteller (Entwickler, Urheber des Codes) | Tim Hauke (VectoDE) |
| Herausgeber, Store-Publisher, Windows-CompanyName | LineFM Studios |
| Inhaber von LineFM Studios, Impressumsangaben, Verantwortlicher nach MStV, Kontakt Barrierefreiheit | Julian Gebauer |
| Sender in der App | LINEFM, Radio3FM, FobFM (Streams über laut.fm, LAUT AG) |
| Betreiber von LineFM laut Impressum | RadioGruppe Deutschland im Auftrag der LINEFM Gruppe |

Schriftliche Freigaben liegen laut LineFM Studios vor (Stand 21.11.2026): App-Icon und Logos, Veröffentlichung des Quellcodes, Radio3FM und FobFM samt Logos, radiogruppe.de, laut.fm/GEMA/GVL, Impressum- und Datenschutztext, Store-Texte, Rechte und Übergabe. Die Schreiben selbst liegen bei LineFM Studios, nicht im Repository.

## Was das Produkt tut

Die App spielt die Livestreams der drei Sender, zeigt Titel und Cover und kann auf Chromecast, AirPlay, Android Auto und CarPlay übertragen. Es gibt kein Backend und keine Nutzerkonten. Telemetrie (Statistik, Fehlerberichte) ist optional, austauschbar und läuft nur nach Einwilligung. Technischer Überblick: [ENTWICKLUNG.md](ENTWICKLUNG.md), Architekturentscheidungen: [adr/](adr/README.md).

## Prüfpunkte

Jeder Punkt nennt die Stelle, an der der heutige Text oder die Umsetzung steht.

### Impressum und Medienrecht

1. **Impressum nach § 5 DDG**, Angaben nach § 18 Abs. 2 MStV und § 27a UStG. Texte: [assets/legal/de/impressum.json](../assets/legal/de/impressum.json) (verbindlich), [assets/legal/en/impressum.json](../assets/legal/en/impressum.json), Web: [web/impressum/index.html](../web/impressum/index.html). Die Platzhalter füllt LineFM Studios über [assets/legal/placeholders.json](../assets/legal/placeholders.json). Bis zur Prüfung zeigen App und Web oben den Hinweis „ENTWURF“.
2. **MStV:** Ist die App ein journalistisch-redaktionelles Telemedium im Sinne von § 18 Abs. 2 MStV, und wer ist verantwortlich? Zuständige Aufsicht (Landesmedienanstalt).
3. **Formulierung zu Anbieter und Entwickler** im Abschnitt „Über diese App“ (Betreiber, RadioGruppe, LineFM Studios, Entwickler Tim Hauke).

### Datenschutz (DSGVO, TDDDG)

4. **Datenschutzerklärung insgesamt:** [assets/legal/de/datenschutz.json](../assets/legal/de/datenschutz.json), Web: [web/datenschutz/index.html](../web/datenschutz/index.html). Blöcke mit `requires` erscheinen nur, wenn der jeweilige Dienst konfiguriert ist (Erklärung im Feld `reviewNote` der Datei).
5. **Rolle von laut.fm:** Die App lädt Stream und Titeldaten direkt von laut.fm. Eigene Verantwortung von LAUT AG, Auftragsverarbeitung oder gemeinsame Verantwortung?
6. **Google Cast auf Android und iOS:** SDK startet erst beim ersten Tippen auf den Cast-Knopf. Ausnahme Android: Das Plugin kann das SDK beim Beenden der App initialisieren, auch ohne Nutzung. Reicht Offenlegen, oder braucht es nach § 25 TDDDG eine Einwilligung? Gemeinsame Verantwortung mit Google (Art. 26 DSGVO)? Technik: [ENTWICKLUNG.md](ENTWICKLUNG.md), Abschnitt Google Cast; Code: `lib/services/cast/`.
7. **Google Cast im Web:** Das Skript von www.gstatic.com wird erst nach Einwilligung geladen, die Entscheidung liegt in `localStorage` (`linefm.googleCast`), Widerruf in den Einstellungen mit einmaligem Neuladen. Code: [web/cast.js](../web/cast.js). Text: Datenschutzerklärung, Abschnitt 7.
8. **Speichern ohne Einwilligung nach § 25 Abs. 2 Nr. 2 TDDDG:** gewählte App-Sprache, die Cast-Entscheidung und ein Opt-out (Telemetrie aus, Cover aus). Trägt die Begründung „unbedingt erforderlich“?
9. **Telemetrie:** Umami und GlitchTip (selbst gehostet), Firebase, Sentry, alle optional. Einwilligungstexte, Empfänger, USA-Übermittlung (EU-US Data Privacy Framework) bei Google und Sentry, AVV je genutztem Dienst. Technik: [telemetry.md](telemetry.md), [adr/0006-telemetrie-austauschbar-mit-einwilligung.md](adr/0006-telemetrie-austauschbar-mit-einwilligung.md).
10. **GA4 in der Web-Version** mit Consent Mode: Datenverarbeitungsbedingungen in der GA4-Verwaltung, Einwilligungstext. Einrichtung: [EINRICHTUNG.md](EINRICHTUNG.md), Schritte 2.4 und 10.2; Code: [web/analytics.js](../web/analytics.js).
11. **Werbe-ID (AD_ID) auf Android**, die Play-Dienste-Bibliotheken (Cast, Firebase) einbringen können. Kommentar in `android/app/src/main/AndroidManifest.xml`.
12. **Store-Datenschutzangaben** (Google Play Data safety, Apple Privacy Nutrition Label, Absturz- und Nutzungsdaten als „verknüpft“): [STORE-DATENSCHUTZANGABEN.md](STORE-DATENSCHUTZANGABEN.md).

### Urheberrecht, Marken, Lizenzen

13. **Proprietäre Lizenz bei öffentlichem Quellcode:** [LICENSE](../LICENSE), Begründung in [adr/0005-proprietaere-lizenz-bei-oeffentlichem-code.md](adr/0005-proprietaere-lizenz-bei-oeffentlichem-code.md). Rechteinhaber ist nach Entscheidung von LineFM Studios vom 27.11.2026 in beiden Sprachen LineFM Studios; der Wortlaut steht bis zur Prüfung unter Vorbehalt.
14. **Entwurf der Nennungsklausel** in der `LICENSE` (Abschnitt „ENTWURF … NENNUNG DES ENTWICKLERS“ bzw. „DRAFT … DEVELOPER ATTRIBUTION“): Nutzung nur mit Nennung von Tim Hauke (VectoDE) und Link, Hersteller Tim Hauke, Herausgeber LineFM Studios. Wirksamkeit, Verhältnis zum Satz „keine Lizenz wird erteilt“, Formulierung.
15. **Nutzungsrechtevertrag Code** zwischen Entwickler und LineFM Studios: Urheberrecht bleibt beim Entwickler, Nutzungsrechte übertragbar. Vertrag liegt noch nicht vor.
16. **libmpv und FFmpeg (LGPL)** in den Windows- und Linux-Paketen: Windows-Build ist nachweislich LGPL 3, Flatpak laut Manifest LGPL 2.1, der Snap baut mpv und FFmpeg jetzt selbst als LGPL (Nachweis nur über die CI-Prüfung, Snap-Bau noch nicht gelaufen). Lizenztexte und ein Quellcode-Angebot liegen bei (`assets/licenses/NATIVE-LIBRARIES.txt`): Wortlaut und Frist des Angebots prüfen. Pflichten aus LGPL 3, insbesondere ob die `LICENSE` das nach LGPL 3 Abschnitt 4 nötige Reverse Engineering zur Fehlersuche erlaubt. Belege und Stand: [LIZENZEN-DRITTE.md](LIZENZEN-DRITTE.md).
17. **Albumcover aus der iTunes Search API** (Apple): Darf die App sie anzeigen und an Cast-Geräte weitergeben? Hinweis im Impressum unter „Rechte an Namen, Logos und Covern“.
18. **Sendernamen und Logos** Dritter (Radio3FM, FobFM, radiogruppe.de, laut.fm): Freigaben liegen vor, Formulierung im Impressum und in der `LICENSE` prüfen.

### Barrierefreiheit

19. **BFSG:** Fällt die App darunter, und reicht die Erklärung? Stand und Erklärung: [BARRIEREFREIHEIT.md](BARRIEREFREIHEIT.md).

### Stores

20. **Store-Richtlinien und Store-Texte** (Werbeaussagen nach UWG, Angaben zum Entwickler): [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md), [STORE-TEXTE.md](STORE-TEXTE.md).

## Weitere Unterlagen

- Freigabe-Checkliste mit den harten Sperren vor Veröffentlichung: [FREIGABE-CHECKLISTE.md](FREIGABE-CHECKLISTE.md)
- Bedrohungsmodell und Vorfallbehandlung: [betrieb/BEDROHUNGSMODELL.md](betrieb/BEDROHUNGSMODELL.md), [betrieb/INCIDENT.md](betrieb/INCIDENT.md)
- Hosting der Web-Version: [hosting-uebersicht.md](hosting-uebersicht.md)

## Ergebnis zurückmelden

Bitte je Prüfpunkt kurz: in Ordnung, Änderung (mit Wortlaut) oder offene Frage an LineFM Studios. Nach der Prüfung entfernt die Entwicklung die Entwurfshinweise in Impressum und `LICENSE`.
