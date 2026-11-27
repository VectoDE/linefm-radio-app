# Störungen und Vorfälle

Was zu tun ist, wenn die Web-Version nicht erreichbar ist, die App falsch reagiert oder eine Sicherheitslücke gemeldet wird. Betrieb im Normalfall: [RUNBOOK.md](RUNBOOK.md). Sicherheitslücken melden: [../../SECURITY.md](../../SECURITY.md).

## Schweregrade

| Stufe | Bedeutung | Beispiele | Reaktion |
|---|---|---|---|
| S1 kritisch | Datenschutz oder Sicherheit verletzt, oder die App ist für alle Nutzer unbrauchbar | veröffentlichte Zugangsdaten, manipulierter Release, Absturz beim Start in einer veröffentlichten Version | sofort, noch am selben Tag. Betroffene Version zurücknehmen oder sperren. |
| S2 hoch | Hauptfunktion fällt aus, Umgehung gibt es nicht | Web-Version nicht erreichbar, kein Ton bei allen Sendern, Stream-Adresse eines Senders ungültig | innerhalb eines Werktags |
| S3 mittel | Funktion eingeschränkt, Umgehung vorhanden | Cover fehlen (Apple-Suche down), Titelanzeige hängt (laut.fm-API down, Stream läuft) | innerhalb einer Woche |
| S4 niedrig | Schönheitsfehler, Einzelfall | falsches Logo-Format, Tippfehler | normale Planung als Ticket |

Bei Zweifel die höhere Stufe wählen und später herabstufen.

Fremddienste: Fällt laut.fm oder Apple aus, kann die App nichts beheben. Sie zeigt einen Fehler und versucht es erneut. Der Betreiber informiert dann nur, falls Nutzer fragen, und beobachtet die Statusseite des Anbieters.

## Meldewege

| Von | Wohin | Wofür |
|---|---|---|
| Uptime-Monitor | Ticket mit Label `uptime` im Repository (automatisch) | Web-Version oder laut.fm-API nicht erreichbar |
| Nutzer | GitHub Discussions, Tickets, Kontaktadresse aus dem Impressum | Fehler, Fragen |
| Nutzer, Forscher | vertrauliches Meldeformular nach [SECURITY.md](../../SECURITY.md) | Sicherheitslücken. **Nie** als öffentliches Ticket. |
| Store-Konsolen | E-Mail des Entwicklerkontos (Google Play, App Store Connect, Partner Center) | Ablehnungen, Richtlinienhinweise, Abstürze laut Konsole |
| Betreiber (LineFM Studios) | Betreuer des Repositories | Entscheidungen, Kommunikation nach außen |

Die Kontaktdaten des Betreibers stehen im Impressum der App. Sie stehen absichtlich nicht in diesem Dokument.

## Ablauf

1. Erkennen und bestätigen. Meldung prüfen: Ist das Problem reproduzierbar, welche Version, welche Plattform? Ein Ticket anlegen (bei Sicherheitslücken stattdessen privat im Advisory arbeiten).
2. Stufe festlegen nach der Tabelle oben.
3. Eindämmen. Zuerst stoppen, dann ursächlich beheben:
   - Web: Rollback nach [RUNBOOK.md](RUNBOOK.md).
   - Android, Windows, Linux: gestaffelten Rollout in der Konsole anhalten, falls vorhanden. Eine neue, höhere Version mit dem alten Stand nachschieben.
   - Telemetrie verdächtig: Konfiguration im nächsten Build leeren. Auf dem Server den Eingangspfad sperren.
   - Zugangsdaten betroffen: Secret bei GitHub und beim Anbieter sofort widerrufen und ersetzen, dann Verlauf prüfen. Ein Secret im Git-Verlauf gilt als offengelegt, auch wenn es später gelöscht wurde.
4. Beheben. Fix per Änderungsvorschlag mit Test, Release nach dem üblichen Ablauf (signiert, mit Prüfung nach [../RELEASE-VERIFIZIEREN.md](../RELEASE-VERIFIZIEREN.md)).
5. Informieren.
   - Sicherheitslücke: Melder nach den Fristen in SECURITY.md informieren (Eingang 7 Tage, Einschätzung 14 Tage), Veröffentlichung mit dem Melder abstimmen.
   - Datenpanne mit personenbezogenen Daten: **Meldepflichten nach Art. 33 DSGVO (72 Stunden an die Aufsichtsbehörde) und Art. 34 (Betroffene) prüft ein Anwalt oder die Datenschutzberatung des Betreibers.** Dieses Dokument ersetzt diese Prüfung nicht. Die App speichert selbst keine Nutzerdaten auf Servern des Betreibers. Betroffen sein können Telemetrie-Daten (nur mit Einwilligung).
   - Nutzer: Hinweis in den Release-Notes, bei S1 zusätzlich in den Store-Beschreibungen und auf der Web-Version.
6. Nachbetrachtung innerhalb von fünf Werktagen nach S1 und S2 (Vorlage unten). Maßnahmen als Tickets mit Aufgaben anlegen.

## Vorlage Nachbetrachtung

Als Ticket anlegen. Ziel ist Lernen, nicht Schuldzuweisung.

```markdown
## Nachbetrachtung: <Kurztitel>, <Datum>

**Stufe:** S1 / S2 / S3
**Dauer:** von <Zeit> bis <Zeit> (Entdeckung <Zeit>, Eindämmung <Zeit>, Behebung <Zeit>)
**Betroffen:** <Plattformen, Versionen, geschätzte Nutzer>

### Was ist passiert
<Fakten in Zeitfolge, ohne Wertung>

### Ursache
<technische Ursache, nicht der Mensch>

### Was hat geholfen, was hat gefehlt
- <Erkennung>
- <Eindämmung>
- <Kommunikation>

### Maßnahmen
- [ ] <Maßnahme, Verantwortlicher, Termin>
- [ ] <Test oder Monitor, der es künftig erkennt>
- [ ] <Dokument aktualisiert: RUNBOOK, Bedrohungsmodell>
```

## Übungen

Einmal im Jahr: Rollback auf die Vorversion üben (Web) und prüfen, dass der Zugang zu Store-Konten, Signaturschlüsseln und Domain bei mindestens zwei Personen liegt. Ergebnisse im RUNBOOK eintragen.
