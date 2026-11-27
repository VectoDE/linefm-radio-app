# Sender verwalten

Alle Sender der App stehen in einer Datei: [`config/stations.yaml`](../config/stations.yaml). Hier steht, wie du Sender hinzufügst, entfernst, umbenennst und umsortierst. Programmierkenntnisse brauchst du dafür nicht. Oben in der Datei ist jedes Feld noch einmal als Kommentar erklärt.

## So sieht ein Sender aus

```yaml
  - kuerzel: linefmrap
    name: "LineFM +RAP"
    farbe: "#FF0084"
    logo: https://cdn.linefm.de/images/icons/rap.png
    logoDatei: assets/images/stations/rap.png
```

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `kuerzel` | ja | Das Kürzel aus der laut.fm-Adresse. Bei `https://laut.fm/linefmrap` ist es `linefmrap`. Nur Kleinbuchstaben, Ziffern, `_` und `-`. Darüber merkt sich die App Favoriten und Wecker, also später nicht mehr ändern. |
| `name` | ja | So heißt der Sender in der App, höchstens 40 Zeichen. |
| `farbe` | ja | Farbe des Senders, `#` und sechs Zeichen aus 0-9 und A-F, **in Anführungszeichen**. Ohne sie gilt alles ab `#` als Kommentar. |
| `logo` | ja | Adresse des Logos. Nur `https://cdn.linefm.de/...` oder `https://assets.laut.fm/...`. |
| `logoDatei` | nein | Logo, das die App mitbringt (`assets/images/stations/<name>.png`). Nur nötig, wenn das Logo auch ohne Netz, in Android Auto, im Widget und in CarPlay erscheinen soll. Dafür braucht es eine neue App-Version. |
| `aktiv` | nein | `false` blendet den Sender vorübergehend aus. Fehlt das Feld, wird er angezeigt. |

Die Stream-Adresse trägst du nicht ein. Die App nimmt immer `https://stream.laut.fm/<kuerzel>`.

## Sender hinzufügen

1. Öffne `config/stations.yaml` auf GitHub und klicke auf den Stift („Edit this file“).
2. Kopiere einen vorhandenen Sender ab der Zeile mit `- kuerzel:` bis vor den nächsten und setze ihn an die gewünschte Stelle unter `sender:`.
3. Achte auf die Einrückung: `- kuerzel` mit zwei Leerzeichen davor, die übrigen Felder mit vier. Keine Tabs.
4. Trage Kürzel, Namen, Farbe und Logo-Adresse ein. Lass `logoDatei` weg, wenn es kein mitgeliefertes Logo gibt.
5. Unten „Propose changes“ bzw. einen Änderungsvorschlag anlegen. Die Prüfung („Konfigurationsordner pruefen“) zeigt dir sofort, ob die Datei stimmt, mit Zeilennummer und Hinweis.

## Sender entfernen

Lösche alle Zeilen des Senders, von `- kuerzel:` bis vor den nächsten Sender. Was dann passiert:

- Der Sender verschwindet aus Senderliste, Player, Android Auto, CarPlay, Tray und Widget.
- Favoriten auf ihn bleiben im Gerät gespeichert, werden aber nicht angezeigt. Kommt der Sender zurück, ist der Stern wieder da.
- Ein Wecker auf diesen Sender weckt mit dem ersten Sender der Liste.
- Ein Link auf den Sender zeigt einen Hinweis und spielt nichts.

Willst du einen Sender nur kurz ausblenden, setze stattdessen `aktiv: false`.

## Umbenennen und umsortieren

- Umbenennen: nur `name` ändern. Das Kürzel bleibt gleich, sonst gehen Favoriten verloren.
- Umsortieren: Sender in der Liste verschieben. Die App zeigt sie in dieser Reihenfolge.

## Wann die Änderung ankommt

- Ohne neue App-Version: Ist beim Bauen eine feste Adresse für die Senderliste gesetzt (`STATIONS_URL`, siehe [Konfiguration](KONFIGURATION.md)), lade die geprüfte Datei dort hoch. Jede App holt sie beim nächsten Start im Hintergrund. Ist die Adresse nicht erreichbar oder die Datei fehlerhaft, bleibt die bisherige Liste.
- Mit neuer App-Version: Die Datei im Repository wird bei jedem Build mitgeliefert.

## Häufige Fehler

| Meldung | Lösung |
|---|---|
| „Das Feld "nmae" kennt die App nicht. Meintest du "name"?“ | Tippfehler im Feldnamen korrigieren. |
| „farbe“ fehlt, obwohl sie dasteht | Die Farbe steht ohne Anführungszeichen. Schreibe `farbe: "#4B4B7D"`. |
| „Kein gültiges YAML“ mit Zeilennummer | Meist ein Tab statt Leerzeichen oder eine verrutschte Einrückung in dieser Zeile. |
| Logo-Adresse nicht erlaubt | Logo auf `cdn.linefm.de` ablegen. Weitere Hosts gibt es nur mit einer neuen App-Version. |
