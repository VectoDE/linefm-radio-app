# ADR 0002: laut.fm-WebSocket aus, Titel per Polling

Status: angenommen
Quelle: Entscheidung 50 des Inhabers (19.11.2026)

## Kontext

laut.fm bietet einen WebSocket (`wss://api.laut.fm/song_change.ws.json`), der Titelwechsel meldet. Gemessen am 19.11.2026 lieferte er rund 130 MB pro Stunde, davon 99,97 Prozent Daten fremder Sender. Für ein Handy mit Mobilfunk ist das nicht tragbar.

## Entscheidung

Der WebSocket ist auf allen Plattformen aus (`WS_ENABLED=false` ist der Standard). Die App fragt den aktuellen Titel über die REST-API ab. Sie setzt einen Timer auf das gemeldete Ende des Titels (`ends_at`) fragt im Vordergrund alle 60 Sekunden nach und bei Live-Sendungen ohne bekanntes Ende alle 30 Sekunden. Antworten hält ein HTTP-Cache. Der Code für den WebSocket bleibt erhalten und lässt sich zu Testzwecken einschalten.

## Folgen

- Der Datenverbrauch bleibt klein.
- Der Titelwechsel kommt mit kleiner Verzögerung an, bei Live-Sendungen bis zu 30 Sekunden.
- Wir belasten die API von laut.fm mit regelmäßigen Anfragen. Ein Rate-Limit ist nicht dokumentiert. Sollte laut.fm Anfragen drosseln, müssen die Intervalle angepasst werden.
- Der WebSocket-Code muss mitgepflegt oder später entfernt werden. Entscheidung dazu offen.

## Verworfene Alternativen

WebSocket mit Filter auf den eigenen Sender: laut.fm bietet keinen Filter an. Verworfen.
