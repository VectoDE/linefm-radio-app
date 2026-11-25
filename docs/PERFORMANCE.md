# Performance: Messung, Ausgangswerte, Engpässe

Stand 21.11.2026. Vorgabe des Inhabers: App-Start, Laden im Browser, Bedienung und Ton nach Klick sollen dreimal so schnell werden (gemessene Zeiten auf ein Drittel).

Dieses Dokument hält den Ausgangsstand fest. Budgets in der CI gibt es noch nicht; sie folgen, wenn die Maßnahmen umgesetzt und nachgemessen sind.

## Wie gemessen wird

Workflow [`.github/workflows/performance.yml`](../.github/workflows/performance.yml), Skripte in [`tool/perf/`](../tool/perf/). Läuft bei Änderungen an den Messwerkzeugen, wöchentlich (Sonntag 02:37 UTC) und von Hand (`workflow_dispatch`, Eingabe `runs`). Kein Schritt bricht wegen eines Messwerts ab.

| Job | Was | Wie |
|---|---|---|
| Web | Lighthouse mobil und Desktop, je 5 Läufe; Playwright: Erstaufruf und Wiederaufruf, Scrollen, Seitenwechsel, Klick bis Ton | Wasm-Release-Build hinter dem nginx-Container aus `deploy/traefik` (gzip 5, Cache-Header aus `deploy/nginx/snippets`), HTTP/1.1 ohne TLS. Mobil: Slow-4G und CPU 4x per DevTools-Drosselung |
| Windows | Start bis erstes Bild, Speicher und CPU im Leerlauf, Ton per Deep Link, Paketgröße | `tool/perf/windows_start.ps1`, Release-Build, 5 Läufe nach einem Aufwärmlauf |
| Android | APK arm64 (mit `--analyze-size`) und AAB | nur Größen; Kaltstart und Bildrate im Emulator sind noch offen |
| Bericht | Tabelle aus allen Ergebnissen | `tool/perf/summarize.mjs`, in der Zusammenfassung des Laufs und als Artefakt `perf-report-*` |

Messpunkte im Code: [`lib/core/perf/perf_marks.dart`](../lib/core/perf/perf_marks.dart). Sie sind nur mit `--dart-define=LINEFM_PERF_MARKS=true` aktiv. Ohne den Schalter entfernt der Compiler sie, Nutzer-Builds enthalten keinen Messcode.

Alle Werte sind Laborwerte auf GitHub-Runnern (4 Kerne AMD EPYC, ohne GPU). Felddaten (CrUX) gibt es für app.linefm.de noch nicht.

## Ausgangswerte

Lauf [44950025363](https://github.com/VectoDE/linefm-radio-app/actions/runs/44950025363), Commit `b640b22` (Merge-Stand auf `main` 348adff). Median aus 5 Läufen, Streuung = Minimum bis Maximum. Ziel = Median / 3.

### App-Start

| Kennzahl | Median | Streuung | Ziel |
|---|---|---|---|
| Windows: Prozessstart bis erstes Bild | 1,07 s | 0,75 – 1,09 s | 357 ms |
| Windows: Prozessstart bis `runApp` | 139 ms | 137 – 248 ms | 46 ms |
| Windows: `runApp` bis erstes Bild gerastert | ca. 0,93 s | aus den Marken abgeleitet | 310 ms |
| Windows: Speicher nach 30 s Leerlauf (Working Set / Private Bytes) | 211 / 179 MB | 211 – 213 MB | kein Zeitziel |
| Windows: CPU im Leerlauf (% eines Kerns) | 350 % | 343 – 351 % | kein Zeitziel, siehe P92-02 |
| Android: Kaltstart | nicht gemessen | – | – |

### Laden im Browser

| Kennzahl | Mobil (Slow-4G, CPU 4x) | Desktop (ohne Drosselung) | Ziel mobil / Desktop |
|---|---|---|---|
| FCP = LCP (statische Hülle) | 680 ms | 112 ms | 227 / 37 ms |
| Dart `main()` startet | 13,32 s | 440 ms | 4,44 s / 147 ms |
| Erstes Flutter-Bild | 15,11 s (15,07 – 15,45) | 1,56 s (1,52 – 1,65) | 5,04 s / 522 ms |
| Bedienbar (3 s ohne Long Task) | 40,18 s | 8,95 s (7,61 – 25,83) | 13,39 s / 2,98 s |
| Total Blocking Time bis bedienbar | 12,83 s | 1,09 s | 4,28 s / 362 ms |
| Übertragen beim Erstaufruf | 2,02 MB, 34 Anfragen | 2,12 – 3,54 MB, 36 Anfragen | – |
| Erstes Bild beim Wiederaufruf (Cache/SW) | 2,29 s | 1,15 s | 762 / 382 ms |
| Lighthouse Performance | 62 (62 – 69) | 64 (63 – 69) | 100 |
| Lighthouse Accessibility / Best Practices / SEO | 100 / 77 / 100 | 100 / 77 / 100 | 100 |
| Lighthouse TBT | 13,18 s (12,41 – 60,60) | 1,61 s | 4,39 s / 535 ms |
| Lighthouse Speed Index | 8,18 s (3,54 – 8,31) | 2,66 s | 2,73 s / 886 ms |
| CLS | 0,000 | 0,000 | ≤ 0,02 |
| TTFB (lokaler Server) | 1 ms | 1 ms | – |

Größen des Web-Builds: `main.dart.wasm` 3,82 MB roh, `skwasm.wasm` 8,97 MB roh, App-Schriften 0,39 MB. Startdateien gzip 5 (ausgeliefert) 3,03 MB, mit Brotli 11 wären es 2,33 MB.

### Bedienung

| Kennzahl | Mobil | Desktop | Ziel |
|---|---|---|---|
| Scrollen Senderliste: Bilder über 33 ms in 1,5 s | 37 von 39 | 52 von 52 | – |
| Scrollen Senderliste: längstes Bild | 117 ms | 50 ms | 39 / 17 ms |
| Scrollen Einstellungen: längstes Bild | 117 ms | 67 ms | 39 / 22 ms |
Seitenwechsel aus dem Folgelauf [44952902695](https://github.com/VectoDE/linefm-radio-app/actions/runs/44952902695) (gleiche Bedingungen, n=5; im ersten Lauf fehlten sie, weil der Browser im Runner auf Englisch lief und die Suche deutsche Namen erwartete. Behoben mit Locale `de-DE` und englischen Namen als Rückfall):

| Seitenwechsel | Klick bis nächstes Bild mobil | Desktop | längstes Bild mobil / Desktop | Ziel Klick mobil / Desktop |
|---|---|---|---|---|
| Verlauf | 208 ms (200 – 232) | 152 ms (144 – 152) | 317 / 183 ms | 69 / 51 ms |
| Favoriten | 128 ms (128 – 144) | 56 ms (48 – 56) | 100 / 67 ms | 43 / 19 ms |
| Einstellungen | 104 ms (96 – 112) | 96 ms (88 – 104) | 133 / 83 ms | 35 / 32 ms |
| Sender | 104 ms (88 – 144) | 64 ms (64 – 72) | 133 / 100 ms | 35 / 21 ms |

Der Verlauf ist der trägste Wechsel (mobil 18 Bilder über 33 ms, längstes 317 ms); Kandidat ist die gestaffelte Einblendung in `lib/features/history/stagger_in.dart`. Folgelauf Ton: Web 4,12 s (4,07 – 4,28), Windows Senderwechsel 1,17 s (1,00 – 1,57, 5 von 5).

### Ton nach Klick

| Kennzahl | Median | Streuung | Ziel |
|---|---|---|---|
| Web: Klick bis Audio `playing` (erster Sender) | 4,33 s | 4,21 – 4,60 s | 1,44 s |
| Web: davon Stream-URL über die laut.fm-API | ca. 60 ms | | |
| Windows: Anforderung bis Zustand „spielt“ | 3,91 s (4 von 5 Läufen) | 3,86 – 4,41 s | 1,30 s |
| Windows: Senderwechsel bis „spielt“ | 3,91 s (3 von 5) | 3,90 – 4,44 s | 1,30 s |

Der Senderwechsel im Web erreichte in keinem Lauf `playing`; an der Senderwahl wird noch gearbeitet.

## Engpässe (Fundliste)

Nach erwarteter Wirkung sortiert. Belegt heißt: Messwert aus dem Lauf oben und Codestelle.

| ID | Ort | Schwere | Beleg | Maßnahme, erwartete Wirkung |
|---|---|---|---|---|
| P92-01 | Web-Start gesamt (Hauptthread), `web/flutter_bootstrap.js` | Critical | Mobil TBT 12,8 s, bedienbar erst nach 40 s, längster Long Task 1,05 s; Lighthouse Performance 62 | Arbeit nach dem ersten Bild verschieben und zerlegen (Profil per Trace im Folgelauf), Bilder/Cover erst nach dem ersten Bild laden. Größter Hebel für „bedienbar“ |
| P92-02 | Windows Leerlauf; Dauer-Animationen `lib/ui/widgets/marquee_text.dart:103`, `lib/features/loader/app_loader.dart:116` | High | CPU 350 % eines Kerns nach 30 s Leerlauf, ohne Ton. Runner ohne GPU (Software-Rendering) übertreibt den Wert, die Ursache (Bild für Bild neu zeichnen ohne Anlass) bleibt | Laufschrift nur bei Überlänge und sichtbar, `TickerMode` aus, wenn Fenster verdeckt/minimiert; prüfen, welcher Ticker dauerhaft läuft (DevTools-Timeline). Ziel: Leerlauf nahe 0 % |
| P92-03 | `lib/services/audio/audio_handler.dart:37` (`minConnectDuration` 1 s), `:425-427` | High | Ton-Marke `player-playing` frühestens nach 1 s, auch wenn der Stream schneller ist | Mindestdauer nur für die Anzeige, nicht für den Zustand; oder auf 0 setzen. Spart bis 1 s bei schnellem Stream |
| P92-04 | Ton nach Klick, Stream-Puffer von laut.fm | High | Web: URL nach ca. 60 ms bekannt, `playing` erst nach 4,3 s; der Rest ist Puffern des Icecast-Streams im Browser bzw. in media_kit | Nur teilweise beeinflussbar: Verbindung vorwärmen (`preconnect` zu `*.stream.laut.fm`), Stream-URLs beim Start vorab holen (`lib/app/player_controller.dart:291`), media_kit-Puffergröße prüfen. Faktor 3 hier unsicher |
| P92-05 | Windows `runApp` bis erstes Bild, `lib/main.dart:62-78` | High | 139 ms bis `runApp`, dann ca. 0,93 s bis zum ersten gerasterten Bild | Erstes Bild schlanker (Loader ohne Blur/Netzbilder), Schriften und Shader vorwärmen; Trace im Folgelauf |
| P92-06 | `lib/features/loader/app_loader.dart:213-215` | Medium | Fester Ladebildschirm 400 ms (Web) bzw. 300 ms (nativ) plus 350 ms Ausblenden nach dem ersten Bild | Entscheidung des Inhabers (21.11.2026): Splash ohne feste Mindestzeit, nur kurz einblenden. Mindestdauer entfällt, Ausblenden kürzen. Bis 0,75 s schneller bedienbar. Entwurf liegt vor |
| P92-07 | `deploy/nginx/snippets/linefm-headers.conf:26-31` | Medium | Nur gzip 5; Startdateien 3,03 MB statt 2,33 MB mit Brotli 11 | Vorkomprimierte `.br`-Dateien im Build und `brotli_static`, bzw. Brotli bei Cloudflare. Mobil ca. 0,7 MB weniger, bei Slow-4G rund 3,5 s |
| P92-08 | `web/index.html:189-190` | Medium | `main.dart.wasm` und `skwasm.wasm` werden erst nach `flutter_bootstrap.js` und `main.dart.mjs` angefordert (Kaskade); `analytics.js` blockiert den Parser vor dem Bootstrap | `<link rel="preload">` bzw. `modulepreload` für die gehashten Startdateien (Postbuild kennt die Namen), `analytics.js` mit `defer`. Spart mindestens eine Runde Netzlatenz |
| P92-09 | `pubspec.yaml:72-81` | Low | Schriften als TTF, 0,39 MB roh, 0,29 MB übertragen | Untermengen bilden; Flutter Web lädt nur TTF/OTF, daher kein WOFF2. Ca. 0,2 MB weniger |
| P92-10 | Best Practices 77 | Low | Audits `errors-in-console` (CORS bei `cdn.linefm.de/images/icons/*.png`, nur unter `127.0.0.1`), `deprecations` (`SharedArrayBuffer`, `Intl.v8BreakIterator` aus der Engine) | CORS-Kopfzeile am CDN prüfen; Engine-Warnungen sind nicht in unserer Hand |
| P92-11 | `lib/features/mini_player/mini_player.dart:274` | Low | Blur sigma 22 auf dem Cover im Miniplayer, Bild für Bild beim Scrollen | Unscharfes Cover einmal berechnen und zwischenspeichern; Wirkung im Folgelauf über Scrollwerte prüfen |

## Messlücken

- Android Kaltstart und Bildrate (Emulator-Job) fehlen.
- Seitenwechsel im ersten Lauf nicht gemessen (behoben, siehe oben).
- Übertragene Bytes für `main.dart.wasm` zeigt CDP mit 0 (Streaming-Kompilierung); Größe stammt aus dem Build.
- Kein INP aus Feldern, nur Event-Timing im Labor.
- iOS und macOS nicht gemessen.

## Maßnahmenplan

Je Maßnahme ein eigener Änderungsvorschlag mit Vorher/Nachher aus diesem Workflow (gleiche Läufe, gleiche Runner):

1. P92-03 und P92-06: künstliche Wartezeiten (Mindest-Verbindungsdauer, Ladebildschirm). Klein, sofort messbar.
2. P92-02: Dauer-Animationen im Leerlauf.
3. P92-07 und P92-08: Brotli, Preload, `analytics.js` mit `defer`.
4. P92-01 und P92-05: Start-Profil per Trace, Arbeit nach dem ersten Bild verschieben.
5. P92-04: Vorwärmen der Stream-Verbindung, Puffer prüfen.
6. P92-09 bis P92-11.
7. Danach Budgets in der CI (Lighthouse-Assertions, Größenbudget, Startzeit).

## Ist Faktor 3 erreichbar?

- **Laden im Browser, Desktop:** wahrscheinlich ja für „erstes Bild“ und „bedienbar“, weil künstliche Wartezeiten, Kaskade und Hauptthread-Arbeit zusammen einen großen Teil ausmachen.
- **Laden im Browser, mobil:** für „erstes Bild“ (15 s auf 5 s) nicht allein mit unseren Mitteln. Der Großteil ist Übertragung von rund 2 MB über Slow-4G plus Wasm-Kompilierung. Brotli und Preload bringen geschätzt 25 bis 35 %. Für „bedienbar“ (40 s) ist Faktor 3 erreichbar, wenn der Hauptthread entlastet wird.
- **App-Start Windows:** offen. 139 ms bis `runApp` sind schon gut; ob das erste Bild auf 357 ms kommt, zeigt erst ein Trace.
- **Ton nach Klick:** eher nicht. Rund 3 s entfallen auf das Puffern der laut.fm-Streams. Realistisch sind 1 bis 1,5 s weniger (P92-03, P92-04), also etwa Faktor 1,3 bis 1,5.
- **Bedienung:** offen bis die Seitenwechsel gemessen sind. Die Scrollwerte auf dem GPU-losen Runner sind als Vergleichsgröße brauchbar, nicht als absoluter Nutzerwert.

## Public web quality checks

Public measurement. Workflow `.github/workflows/pages.yml` builds the web app for GitHub Pages
(`--base-href /linefm-radio-app/`) and deploys it to https://vectode.github.io/linefm-radio-app/
on every push to `main` that touches the app. Pages must be enabled once
(Settings > Pages > Source: GitHub Actions); until then the deploy step is skipped with a note.

After each deploy the job "Web quality gate" checks the live URL:

- With the repository secret `PAGESPEED_API_KEY`: PageSpeed Insights API, mobile and desktop.
- Without it: Lighthouse on the runner (`tool/perf/lighthouse.mjs`, median of 5 runs, simulated throttling).
- Thresholds (`tool/perf/pagespeed_gate.mjs`): performance >= 95, accessibility, best practices and SEO = 100.
  Below that the job fails. Reports are in the artifact `web-gate-<sha>`.

Seobility (https://www.seobility.net/de/seocheck/) and WebsiteScorer (https://websitescorer.com/)
offer no free API. They are run by hand against the Pages URL after a deploy that changes the
web output; the scores and findings go into the tracker.
