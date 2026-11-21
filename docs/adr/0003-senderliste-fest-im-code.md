# ADR 0003: Senderliste fest im Code

Status: angenommen
Quelle: Entscheidung 7 des Inhabers (18.11.2026)

## Kontext

Die Web-App liest ihre Sender aus einer JSON-Datei (`streams.json`). Es gibt sechs Sender: vier von LINEFM (+MAIN, +RAP, +GAMING, +LOFI) und die Partnersender Radio3FM und FobFM. Sie ändern sich selten.

## Entscheidung

Senderliste, Farben, Logos und Stream-Adressen stehen fest im Code (`lib/domain/stations_catalog.dart`). Die Senderlogos liegen zusätzlich als Asset im Paket. Eine Änderung der Liste ist ein App-Update.

## Folgen

- Kein Konfigurationsserver und kein Abruf einer Liste beim Start. Damit gibt es auch keine Angriffsfläche über eine manipulierte Liste ([Bedrohungsmodell](../betrieb/BEDROHUNGSMODELL.md)).
- Ändert sich eine Stream-Adresse bei laut.fm oder kommt ein Sender hinzu, braucht es ein Update samt Prüfung in den Stores. Das dauert Tage. Der Uptime-Monitor und die Live-Probe (`tool/dev/now_playing_probe.dart`) sollen eine Änderung früh zeigen.
- Deep Links nehmen nur Sender aus dieser Liste an.

## Verworfene Alternativen

Senderliste von einem Server laden: flexibler, aber ein zusätzlicher Dienst mit eigener Betriebslast und Angriffsfläche. Für sechs selten wechselnde Sender nicht gerechtfertigt. Verworfen.
