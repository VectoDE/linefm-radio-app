# Sender verwalten

Alle Sender der App stehen in einer Datei: [`config/stations.json`](../config/stations.json). Hier steht, wie du Sender hinzufügst, entfernst, umbenennst und umsortierst. Programmierkenntnisse brauchst du dafür nicht.

## So sieht ein Sender aus

```json
{
  "kuerzel": "linefmrap",
  "name": "LineFM +RAP",
  "farbe": "#FF0084",
  "logo": "https://cdn.linefm.de/images/icons/rap.png",
  "logoDatei": "assets/images/stations/rap.png"
}
```

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `kuerzel` | ja | Das Kürzel aus der laut.fm-Adresse. Bei `https://laut.fm/linefmrap` ist es `linefmrap`. Nur Kleinbuchstaben, Ziffern, `_` und `-`. Darüber merkt sich die App Favoriten und Wecker, also später nicht mehr ändern. |
| `name` | ja | So heißt der Sender in der App, höchstens 40 Zeichen. |
| `farbe` | ja | Farbe des Senders, `#` und sechs Zeichen aus 0-9 und A-F. |
| `logo` | ja | Adresse des Logos. Nur `https://cdn.linefm.de/...` oder `https://assets.laut.fm/...`. |
| `logoDatei` | nein | Logo, das die App mitbringt (`assets/images/stations/<name>.png`). Nur nötig, wenn das Logo auch ohne Netz, in Android Auto, im Widget und in CarPlay erscheinen soll. Dafür braucht es eine neue App-Version. |
| `aktiv` | nein | `false` blendet den Sender vorübergehend aus. Fehlt das Feld, wird er angezeigt. |

Die Stream-Adresse trägst du nicht ein. Die App nimmt immer `https://stream.laut.fm/<kuerzel>`.

## Sender hinzufügen

1. Öffne `config/stations.json` auf GitHub und klicke auf den Stift („Edit this file“).
2. Kopiere einen vorhandenen Eintrag von `{` bis `}` und setze ihn an die gewünschte Stelle in der Liste `"sender"`.
3. Zwischen zwei Einträgen steht ein Komma, nach dem letzten keins.
4. Trage Kürzel, Namen, Farbe und Logo-Adresse ein. Lass `logoDatei` weg, wenn es kein mitgeliefertes Logo gibt.
5. Unten „Propose changes“ bzw. einen Pull Request anlegen. Die Prüfung („Konfigurationsordner pruefen“) zeigt dir sofort, ob die Datei stimmt, mit Zeilennummer und Hinweis.

## Sender entfernen

Lösche den ganzen Eintrag von `{` bis `}` samt dem Komma davor oder danach. Was dann passiert:

- Der Sender verschwindet aus Senderliste, Player, Android Auto, CarPlay, Tray und Widget.
- Favoriten auf ihn bleiben im Gerät gespeichert, werden aber nicht angezeigt. Kommt der Sender zurück, ist der Stern wieder da.
- Ein Wecker auf diesen Sender weckt mit dem ersten Sender der Liste.
- Ein Link auf den Sender zeigt einen Hinweis und spielt nichts.

Willst du einen Sender nur kurz ausblenden, setze stattdessen `"aktiv": false`.

## Umbenennen und umsortieren

- Umbenennen: nur `name` ändern. Das Kürzel bleibt gleich, sonst gehen Favoriten verloren.
- Umsortieren: Einträge in der Liste verschieben. Die App zeigt die Sender in dieser Reihenfolge.

## Wann die Änderung ankommt

- **Ohne neue App-Version:** Ist beim Bauen eine feste Adresse für die Senderliste gesetzt (`STATIONS_URL`, siehe [Konfiguration](KONFIGURATION.md)), lade die geprüfte Datei dort hoch. Jede App holt sie beim nächsten Start im Hintergrund. Ist die Adresse nicht erreichbar oder die Datei fehlerhaft, bleibt die bisherige Liste.
- **Mit neuer App-Version:** Die Datei im Repository wird bei jedem Build mitgeliefert.

## Häufige Fehler

| Meldung | Lösung |
|---|---|
| „Das Feld "nmae" kennt die App nicht. Meintest du "name"?“ | Tippfehler im Feldnamen korrigieren. |
| „Farbe muss wie #4B4B7D aussehen“ | Farbe mit `#` und sechs Zeichen angeben. |
| Fehler mit „Zeile 12“ und Komma | Meist fehlt ein Komma zwischen zwei Einträgen oder steht eins zu viel nach dem letzten. |
| Logo-Adresse nicht erlaubt | Logo auf `cdn.linefm.de` ablegen. Weitere Hosts gibt es nur mit einer neuen App-Version. |
