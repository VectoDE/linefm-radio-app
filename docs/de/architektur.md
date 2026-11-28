# Architektur

Kurzfassung der Schichten. Die Ordnerliste, die Provider und das Vorgehen für neue Funktionen stehen in [Entwicklung](../ENTWICKLUNG.md#architektur-im-überblick).

## Schichten

```mermaid
flowchart TB
    subgraph UI[Oberfläche]
        F[features: Bildschirme]
        U[ui: Theme, Tokens, Widgets]
    end
    subgraph APP[App]
        A[app: Shell, Provider, PlayerController]
    end
    subgraph LOGIK[Logik]
        D[domain: Modelle und reine Logik]
        S[services: Audio, Wecker, Cast, Teilen, Telemetrie]
    end
    subgraph DATEN[Daten und Plattform]
        DA[data: laut.fm, Cover, Live-Daten, Speicher]
        P[platform: Deep Links, Desktop, Web]
    end
    U --> F
    F --> A
    A --> D
    A --> S
    S --> D
    S --> DA
    S --> P
    DA --> D
```

Regel: `domain/` kennt kein Flutter. Dienste sind Schnittstellen mit einer echten Umsetzung und einem Fake für Tests. `main()` tauscht die Standardwerte (Stubs ohne Netzwerk) über `productionOverrides` gegen die echten Dienste.

## Externe Dienste

```mermaid
flowchart LR
    App[LINEFM Radio] -->|Senderdaten, Streams, Titel| L[laut.fm]
    App -->|Cover-Suche, abschaltbar| I[iTunes Search]
    App -->|Sender-Icons| C[cdn.linefm.de]
    App -.->|nur nach Einwilligung| T[Umami, GlitchTip oder Sentry, Firebase, Google Analytics]
```

Es gibt kein eigenes Backend und keine Konten ([ADR 0001](../adr/0001-kein-backend-keine-konten.md)). Favoriten, Verlauf und Einstellungen liegen auf dem Gerät.

## Plattformen

| Plattform | Wiedergabe | Besonderheiten |
|---|---|---|
| Android | just_audio, audio_service | Widget, Android Auto, Chromecast |
| iOS, macOS | just_audio, audio_service | AirPlay und CarPlay vorbereitet |
| Windows, Linux | just_audio mit media_kit | Tray, Mini-Fenster, Tastenkürzel; Windows mit Mediensteuerung |
| Web | just_audio | Links mit `?station=`, Rechtsseiten unter `/impressum/` und `/datenschutz/` |

Begründung der Audio-Wahl: [ADR 0007](../adr/0007-audio-just-audio-audio-service-media-kit.md).
