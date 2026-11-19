# Flathub

Manifest: `de.linefm.app.yml`. Metainfo: `linux/de.linefm.app.metainfo.xml` (AppStream, wird im Tarball unter `share/metainfo/` mitgeliefert).

## Ehrliche Einschätzung: proprietäre App auf Flathub

LINEFM Radio steht unter einer proprietären Lizenz (`LicenseRef-proprietary`). Stand der Flathub-Dokumentation (abgerufen am 19.11.2026):

- "All content hosted on Flathub must allow legal redistribution." Proprietäre Apps sind erlaubt, wenn Flathub sie weitergeben darf. Das muss der Rechteinhaber ausdrücklich erlauben.
- Nicht weitergebbare Quellen müssen den Quelltyp `extra-data` nutzen (Download beim Nutzer). Reicht der Entwickler die App selbst ein, ist das in der Regel nicht nötig, weil die Weitergabe damit implizit erlaubt ist.
- Source-available-Software muss vollständig aus Quellcode gebaut werden, Ausnahmen gibt es nur für bekannte Hersteller. Unser Manifest installiert ein **vorgebautes Binär-Tarball**. Das wird ohne Ausnahme voraussichtlich abgelehnt oder verlangt `extra-data`. Vor der Einreichung mit den Flathub-Betreuern klären (Issue im Repo `flathub/flathub`), ob Binär-Tarball erlaubt ist.
- Für die Lizenz verlangt Flathub `LicenseRef-proprietary` mit Link auf den Lizenztext: `<project_license>LicenseRef-proprietary=https://...</project_license>`. Das steht in der Metainfo, der Link ist noch ein Platzhalter. Die Lizenzdatei muss nach `/app/share/licenses/de.linefm.app/` installiert werden (TODO im Manifest).
- Die Domain `linefm.de` muss per `https://linefm.de/.well-known/org.flathub.VerifiedApps.txt` bestätigt werden (App-ID `de.linefm.app`). Das erledigt der Betreiber.
- Runtimes müssen zum Einreichungszeitpunkt aktuell sein. Das Manifest nutzt `org.gnome.Platform//50`, vor der Einreichung auf die dann neueste Version prüfen (`flatpak remote-info flathub org.gnome.Platform`).
- Metainfo muss validieren (`flatpak run org.flathub.flatpak-builder-lint appstream <datei>`), mindestens einen Screenshot, `releases`, `content_rating` (OARS 1.1) und `developer` enthalten. Screenshot-URLs sind Platzhalter (TODO jaybelife).

Quellen:
- https://docs.flathub.org/docs/for-app-authors/requirements
- https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines

Wenn Flathub ablehnt, bleiben Snap Store und der GitHub-Release-Tarball. Rechtlich ersetzt das keinen Anwalt.

## libmpv

`media_kit_libs_linux` nutzt die System-libmpv. Weder die GNOME-Runtime noch die Freedesktop-Runtime liefern sie, deshalb baut das Manifest libass, FFmpeg, libplacebo und mpv als Module. Das ist der aufwendigste Teil und noch ungetestet (kein Linux-Build möglich in dieser Umgebung). Versionen sind per SHA256 bzw. Commit gepinnt.

## Update-Ablauf

1. Release `vX.Y.Z` erzeugt `linefm-radio-X.Y.Z-linux-x64.tar.gz`.
2. `flathub-prep.yml` ersetzt URL und SHA256 in den mit `# release-tarball` markierten Zeilen und legt einen PR an.
3. Manuell testen: siehe Kopf des Manifests.
4. Einreichung: PR gegen `flathub/flathub` (Branch `new-pr`), danach pflegt ein eigenes Repo `flathub/de.linefm.app` das Manifest.
