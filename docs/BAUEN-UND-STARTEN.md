# Bauen und Starten

Diese Anleitung zeigt dir, wie du LINEFM Radio selbst bauen, öffnen und benutzen kannst, ohne den Entwickler zu fragen. Es gibt zwei Wege. Teil A lässt GitHub die App bauen, du lädst nur herunter. Teil B baut auf deinem eigenen Rechner. Teil C ist ein Skript, das Teil B mit einem Befehl erledigt.

Stand der Angaben: 21.11.2026. Wo etwas nicht auf diesem Weg nachgespielt wurde, steht "nicht geprüft".

Unbekannte Wörter (Workflow, Branch, Secret und andere) erklärt die Begriffstabelle am Anfang von [EINRICHTUNG.md](EINRICHTUNG.md). Die Abläufe "SonarCloud" und "Snyk" in der Actions-Liste prüfen nur den Code und sind für das Bauen ohne Bedeutung. Sie überspringen sich selbst, solange der Repo-Eigentümer keine Konten dafür angelegt hat (Schritt 12.6 in EINRICHTUNG.md).

## Wohin mit meinem Ziel?

| Ich will ... | Gehe zu |
|---|---|
| die App ausprobieren, ohne etwas zu installieren | [A1 bis A3](#a1-den-bau-auf-github-starten) |
| die Windows-App starten | [A5 Windows](#windows) |
| die App aufs Android-Handy bringen | [A5 Android](#android) |
| die Web-Version auf meinem Rechner ansehen | [A5 Web](#web) und [B6](#b6-web-bauen-und-ansehen) |
| alles selbst auf meinem Rechner bauen | [Teil B](#teil-b-lokal-selbst-bauen) |
| das mit einem einzigen Befehl tun | [Teil C](#teil-c-start-skripte) |
| wissen, was bei einem Fehler zu tun ist | [Wenn etwas schiefgeht](#wenn-etwas-schiefgeht) |
| eine geprüfte Version zum Verteilen | [A4 Release](#a4-der-weg-über-ein-release) |

## Teil A: Bauen lassen auf GitHub, ohne Installation

Du brauchst nur einen Browser und ein GitHub-Konto, das im Repository mitarbeiten darf. Wenn du den Knopf "Run workflow" in A1 nicht siehst, fehlt dir das Schreibrecht. Dann bitte den Entwickler, dich als Collaborator einzuladen (Schritt dazu in [EINRICHTUNG.md](EINRICHTUNG.md)).

### A1 Den Bau auf GitHub starten

1. Öffne <https://github.com/VectoDE/linefm-radio-app> und melde dich bei GitHub an.
2. Klicke oben auf den Reiter **Actions**.
3. Klicke links in der Liste auf **Build**.
4. Klicke rechts auf **Run workflow**. Ein kleines Fenster klappt auf.
5. Bei **Use workflow from** lass `main` stehen.
6. Beim Schalter **macOS- und iOS-Build einschliessen** setzt du den Haken, wenn du auch die Mac-App und die iOS-Prüfung willst. Ohne Haken baut GitHub Android, Web, Windows und Linux.
7. Klicke auf den grünen Knopf **Run workflow**.

Ein **Lauf** ist ein einzelner Durchgang eines automatischen Ablaufs. Du erkennst, dass er gestartet ist, wenn nach ein paar Sekunden oben in der Liste ein neuer Eintrag mit einem gelben Punkt erscheint (nach einem Neuladen der Seite). Der Punkt wird grün, wenn alles fertig ist, und rot, wenn etwas schiefging.

Wie lange es dauert: Der Lauf vom 21.11.2026 brauchte etwa 13 Minuten, der längste Teil war Android mit gut 13 Minuten. Die einzelnen Plattformen laufen gleichzeitig.

Wenn der Knopf fehlt: Du bist nicht angemeldet, oder dir fehlt das Schreibrecht (siehe oben).

### A2 Die Ergebnisse herunterladen

1. Warte, bis der Lauf einen grünen Haken hat. Klicke dann auf seinen Titel (**Build**).
2. Scrolle auf der Seite ganz nach unten bis zum Abschnitt **Artifacts**.
3. Klicke auf den Namen, den du brauchst (Tabelle unten). Der Browser lädt eine ZIP-Datei herunter.
4. Entpacke diese ZIP-Datei. Darin liegen die eigentlichen Dateien.

Gut zu wissen:

- Die Dateien sind nur für angemeldete GitHub-Nutzer abrufbar. Es gibt keinen öffentlichen Link zum Weitergeben.
- GitHub bewahrt sie **14 Tage** auf (`retention-days: 14` in `build.yml`). Danach sind sie gelöscht und du startest einen neuen Bau.
- Ein Artefakt ist immer eine ZIP-Datei mit den eigentlichen Dateien darin, auch wenn die Datei darin selbst schon ein ZIP oder eine EXE ist.
- Die Version in den Dateinamen sieht bei einem manuellen Bau so aus: `0.0.0-dev+1a2b3c4`. Hinter dem Plus steht die Kurz-ID des Commits (so heißt ein gespeicherter Änderungsstand im Repository). Echte Versionsnummern gibt es nur über Releases (A4).

Was in welchem Artefakt liegt, abgeglichen mit dem Lauf vom 21.11.2026 ([Lauf 44909292173](https://github.com/VectoDE/linefm-radio-app/actions/runs/44909292173), Branch `main`):

| Artefakt | Inhalt (Dateinamen mit Beispielversion) | Größe der ZIP im Lauf |
|---|---|---|
| `dist-android` | `linefm-radio-0.0.0-dev+1a2b3c4-android.apk` (zum Installieren), `...-android.aab` (nur für den Play Store) | 110 MB |
| `dist-web` | `...-web.zip` (die Web-Version), `...-web-hosting.zip` (Server-Einstellungsdateien, 14 KB) | 49 MB |
| `dist-windows` | `...-windows-x64.zip` (portable App), `...-windows-x64-setup.exe` (Installer) | 42 MB |
| `dist-linux` | `...-linux-x64.tar.gz`, `...-linux-x64.deb`, `...-linux-x64.rpm`, `...-linux-x64.AppImage` (die App), `...-linux-x64-setup.AppImage` (Installer) | 14 MB (Stand vor deb, rpm und AppImage, danach größer) |
| `dist-macos` | `...-macos.dmg` (nur mit dem Haken bei macOS und iOS) | 29 MB |

Stand dieses Laufs: Android, Web, Windows, Linux und macOS waren grün. Die iOS-Prüfung war rot. Sie ist eine reine Kompilierprüfung und liefert keine Datei (siehe A6). Der Fehler wird in einem eigenen Änderungsvorschlag behoben, die Version dafür ist iOS 16 als Mindestversion. Ob sie danach grün ist, siehst du in der Lauf-Liste unter Actions.

Windows-MSIX: `build.yml` legt eine MSIX-Datei ins Artefakt (belegt im [Lauf 44953548872](https://github.com/VectoDE/linefm-radio-app/actions/runs/44953548872)). Fehlt sie, schlägt der Schritt fehl. Ohne Signatur lässt sie sich aber nicht installieren (siehe unten). Nimm den Installer (`...-setup.exe`) oder die ZIP.

### A3 Dasselbe auf der Kommandozeile

Das ist für Leute gedacht, die mit einem Terminal (einem Fenster, in das man Befehle tippt) umgehen können. Alles aus A1 und A2 geht auch ohne Browser. Du brauchst die [GitHub-CLI](https://cli.github.com/) (`gh`) und musst dich einmal mit `gh auth login` anmelden.

```bash
gh workflow run build.yml --repo VectoDE/linefm-radio-app --ref main -f apple=true
gh run list --repo VectoDE/linefm-radio-app --workflow build.yml --limit 3
gh run watch --repo VectoDE/linefm-radio-app
gh run download <Lauf-Nummer> --repo VectoDE/linefm-radio-app
```

Ersetze `apple=true` durch `apple=false`, wenn du keinen Mac-Bau brauchst. `gh run watch` zeigt den Fortschritt und fragt, welchen Lauf du meinst. `gh run download` legt für jedes Artefakt einen Ordner an (`dist-android`, `dist-web` und so weiter), die Dateien liegen schon entpackt darin. Die Lauf-Nummer steht in der Adresse des Laufs und in der Ausgabe von `gh run list`.

### A4 Der Weg über ein Release

Jeder Merge auf `main` (eine geprüfte Änderung wird in die Hauptlinie übernommen) erzeugt automatisch ein Release (`release.yml`). Du setzt dafür keinen Tag. Der Ablauf baut alle Plattformen und legt die Dateien mit Prüfsummen (`SHA256SUMS.txt`), cosign-Signaturen (`*.sigstore.json`), Herkunftsnachweis und SBOM (SPDX und CycloneDX) in ein GitHub-Release. Die Release Notes entstehen aus den Titeln der gemergten Änderungsvorschläge. Wie du Release-Dateien auf Echtheit prüfst, steht in [RELEASE-VERIFIZIEREN.md](RELEASE-VERIFIZIEREN.md).

Die Versionsnummer steht in keiner Datei, `pubspec.yaml` trägt nur den Platzhalter `0.0.0-dev`. Der Ablauf berechnet sie aus dem letzten Release und den offenen Tickets:

| Stand der offenen Tickets | Stufe | Beispiel |
| --- | --- | --- |
| noch kein Release | Start | `0.1.0-alpha.1` |
| mindestens ein Ticket mit `typ:feature` offen | Alpha | `0.1.0-alpha.2`, `0.1.0-alpha.3` |
| kein `typ:feature` mehr offen | Beta | `0.1.0-beta.1` |
| nur noch Tickets mit `nur-noch:linefm-studios` offen | Release-Kandidat | `1.0.0-rc.1` |
| kein Ticket mehr offen | Stabil | `1.0.0` |

Jeder Merge zählt die letzte Zahl hoch. Eine Stufe fällt nie zurück, auch wenn ein Ticket wieder aufgeht. Nach `1.0.0` richtet sich die nächste Nummer nach den Commit-Titeln (`fix:` ergibt 1.0.1, `feat:` 1.1.0, `feat!:` 2.0.0). Die Build-Nummer für die Stores steigt mit jedem Lauf.

Alpha-, Beta- und RC-Versionen sind GitHub-Vorabversionen und gehen in keinen Store. Erst ab `1.0.0` laden die Store-Abläufe zu Google Play, Snap, Microsoft, Apple und Flathub hoch und die Web-Version wird aktualisiert, soweit eingerichtet. Der Windows-Installer kommt später dazu.

**Welche Datei für welches Gerät.** Jedes Release enthält diese Dateien (`X.Y.Z` steht für die Version). Zu jeder Datei gehört eine cosign-Signatur `<Datei>.sigstore.json`, alle Prüfsummen stehen in `SHA256SUMS.txt` (selbst signiert als `SHA256SUMS.txt.sigstore.json`).

| Gerät | Datei | Weg |
| --- | --- | --- |
| Windows | `linefm-radio-X.Y.Z-windows-x64-setup.exe` | Installer mit eigener Oberfläche, empfohlen |
| Windows | `linefm-radio-X.Y.Z-windows-x64.msix` | Paket für den Microsoft Store, lokal nur mit vertrautem Zertifikat |
| Windows | `linefm-radio-X.Y.Z-windows-x64.zip` | Ohne Installation entpacken und starten |
| macOS | `linefm-radio-X.Y.Z-macos-setup.dmg` | Installer mit eigener Oberfläche, auch für alle Benutzer |
| macOS | `linefm-radio-X.Y.Z-macos.dmg` | App ins Fenster „Programme“ ziehen, Anleitung im DMG-Hintergrund |
| Linux | `linefm-radio-X.Y.Z-linux-x64-setup.AppImage` | Installer mit eigener Oberfläche |
| Linux | `linefm-radio-X.Y.Z-linux-x64.deb` | Debian, Ubuntu, Linux Mint |
| Linux | `linefm-radio-X.Y.Z-linux-x64.rpm` | Fedora, openSUSE, RHEL |
| Linux | `linefm-radio-X.Y.Z-linux-x64.AppImage` | Jede Distribution, ohne Installation |
| Linux | `linefm-radio-X.Y.Z-linux-x64.tar.gz` | Archiv zum Entpacken |
| Android | `linefm-radio-X.Y.Z-android.apk` | Direkt aufs Handy (siehe A5); regulär über Google Play |
| Android | `linefm-radio-X.Y.Z-android.aab` | Nur für den Upload in die Play Console |
| iOS | keine Datei | Nur über den App Store (siehe A5, iOS) |
| Web | `linefm-radio-X.Y.Z-web.zip`, `...-web-hosting.zip` | Auf einen Webserver legen (siehe A5, Web) |
| alle | `linefm-radio-X.Y.Z-sbom.spdx.json`, `...-sbom.cdx.json` | Stückliste der Abhängigkeiten |

Flatpak (Flathub) und Snap kommen über die jeweiligen Stores, nicht als Release-Datei. Der Ablauf bricht ab, wenn einer der drei Installer oder eines der Linux-Pakete fehlt.

Eine selbst gebaute App (A2) zeigt unter „Über“ statt einer Nummer „Entwicklungsversion“ mit der Kurz-ID des Commits.

### A5 Die Ergebnisse öffnen und nutzen

#### Windows

Es gibt zwei Wege.

**Portable ZIP** (`...-windows-x64.zip`), ohne Installation:

1. Entpacke die ZIP in einen Ordner, zum Beispiel `C:\LINEFM`. Rechtsklick auf die Datei, **Alle extrahieren**.
2. Öffne den Ordner und starte `linefm_radio.exe` per Doppelklick.
3. Lass den Ordnerinhalt zusammen. Die EXE läuft nur mit den Dateien daneben, kopiere sie nicht allein weg.

**Installer** (`...-windows-x64-setup.exe`): siehe den nächsten Abschnitt.

Woran du erkennst, dass es klappt: Das Fenster "LINEFM Radio" öffnet sich mit der Senderliste.

#### Windows: Installer benutzen

Der Installer hat ein eigenes Fenster im Look der App, auf Deutsch oder Englisch (je nach Windows-Sprache) und hell oder dunkel (je nach Windows-Einstellung). Er lässt sich komplett mit der Tastatur bedienen: Tab wechselt zwischen den Feldern, Enter drückt den hervorgehobenen Knopf, Esc fragt, ob du abbrechen willst. Screenreader wie die Sprachausgabe von Windows oder NVDA lesen Schritte, Knöpfe und Fortschritt vor. Geprüft wird das automatisch mit Axe.Windows (Microsoft) und mit Tests der Bildschirmleser-Beschriftungen. Ein Test mit einem echten Screenreader steht noch aus.

1. Doppelklick auf `...-windows-x64-setup.exe`.
2. **Willkommen**: zeigt Version, Herausgeber (LineFM Studios), Hersteller (Tim Hauke) und den Platzbedarf. Ist LINEFM Radio schon installiert, steht hier, von welcher auf welche Version aktualisiert wird. Ist eine neuere Version installiert, geht es nicht weiter (kein versehentliches Zurückstufen).
3. **Lizenz**: Bedingungen lesen, Haken bei "Ich akzeptiere" setzen.
4. **Optionen**:
   - **Nur für mich** (Standard, empfohlen): keine Administratorrechte, Ziel `%LOCALAPPDATA%\Programs\LINEFM Radio`.
   - **Alle Benutzer dieses PCs**: Ziel `C:\Program Files\LINEFM Radio`. Erst beim Klick auf **Installieren** fragt Windows nach Administratorrechten (UAC), sonst nie.
   - Zielordner (mit **Durchsuchen …** wählbar), Desktop-Verknüpfung, Startmenü-Eintrag, Autostart beim Anmelden.
   - Bei einem Update stehen Bereich und Ordner fest, deine bisherigen Optionen sind vorausgewählt.
5. **Installation**: Fortschrittsbalken. Läuft die App noch, fragt das Setup, ob es sie beenden darf. **Abbrechen** nimmt alle Änderungen zurück.
6. **Fertig**: Haken bei "LINEFM Radio jetzt starten" lassen oder entfernen, dann **Fertig**.

Was der Installer einrichtet: einen Eintrag unter **Einstellungen > Apps > Installierte Apps**, die Verknüpfungen, das Link-Schema `linefm://` (Links wie `linefm://play?station=...` öffnen die App) und den App-Pfad (Start über **Win+R** mit `linefm_radio`). Einstellungen, Favoriten und Wecker liegen getrennt von den Programmdateien und bleiben bei jedem Update erhalten.

**Deinstallieren**: **Einstellungen > Apps > Installierte Apps > LINEFM Radio > Deinstallieren**. Es öffnet sich ein Fenster im selben Look. Dort entscheidest du, ob auch Einstellungen, Favoriten und Wecker gelöscht werden. Ohne Haken bleiben sie für eine spätere Installation liegen.

**Für Admins (stille Installation)**, etwa für die Softwareverteilung:

```powershell
# Nur für den angemeldeten Benutzer, ohne Fenster
.\linefm-radio-X.Y.Z-windows-x64-setup.exe /S
# Für alle Benutzer (Administrator-Konsole), ohne Desktop-Verknüpfung, mit Protokoll
.\linefm-radio-X.Y.Z-windows-x64-setup.exe /S /ALLUSERS /DESKTOPSHORTCUT=0 /LOG="C:\Temp\linefm-setup.log"
# Still deinstallieren (steht auch in der Registry als QuietUninstallString)
& "$env:LOCALAPPDATA\Programs\LINEFM Radio\uninstall.exe" /S
```

Alle Parameter und Exit-Codes stehen in [packaging/windows/README.md](../packaging/windows/README.md), `setup.exe /?` zeigt sie ebenfalls.

Windows-Warnung "Der Computer wurde durch Windows geschützt" (SmartScreen): Die Dateien sind nicht mit einem Zertifikat signiert, solange keins eingerichtet ist. Klicke auf **Weitere Informationen** und dann auf **Trotzdem ausführen**. Bei einem Herunterladen aus GitHub ist das normal.

MSIX: Eine MSIX-Datei lässt sich nur installieren, wenn sie signiert ist und Windows dem Zertifikat vertraut. Eine unsignierte MSIX weist Windows ab. Deshalb gibt es sie hier nur im Zusammenhang mit dem Microsoft Store (siehe [packaging/windows/README.md](../packaging/windows/README.md)). Für dich zählen ZIP und Installer.

#### macOS und Linux: Installer benutzen

Auf dem Mac und unter Linux gibt es denselben Installer wie unter Windows: gleiches Fenster, gleiche Schritte (Willkommen, Lizenz, Optionen, Installation, Fertig), gleiche Texte. Nur wo sich das System unterscheidet, heißt eine Option anders. Das Fenster hat auf allen drei Systemen dieselbe eigene Titelleiste im LINEFM-Design: Minimieren und Schließen rechts, verschieben durch Ziehen an der Leiste, bedienbar mit Tastatur und Screenreader. Eine Titelleiste des Systems gibt es nicht.

Während der Installation, beim Update und beim Deinstallieren zeigt das Setup den echten Fortschritt in Prozent, die vergangene Zeit und, sobald sie sich schätzen lässt, die Restzeit. 100 % erscheint erst, wenn wirklich alles fertig ist.

**macOS** (`...-macos-setup.dmg`):

1. DMG öffnen und auf **LINEFM Radio Setup** doppelklicken. Ohne Apple-Entwicklerkonto ist der Installer nicht notarisiert. Dann einmal Rechtsklick auf **LINEFM Radio Setup** und **Öffnen** wählen.
2. **Optionen**:
   - **Alle Benutzer dieses Macs**: Ziel `/Applications/LINEFM Radio.app`. macOS fragt dafür einmal nach dem Passwort eines Administrators.
   - **Nur für mich**: Ziel `~/Applications/LINEFM Radio.app`, ohne Passwort.
   - **Alias auf dem Schreibtisch**, **Im Dock behalten**, **Beim Anmelden automatisch starten** (Anmeldeobjekt).
3. **Deinstallieren**: Bei **Nur für mich** `~/Library/Application Support/LINEFM Radio Setup/Uninstall LINEFM Radio.app` öffnen, bei **Alle Benutzer** `/Library/Application Support/LINEFM Radio Setup/Uninstall LINEFM Radio.app` (fragt wieder nach dem Administrator-Passwort). Es erscheint dasselbe Fenster wie unter Windows, mit der Wahl, ob auch Einstellungen, Favoriten und Wecker gelöscht werden.

**Linux** (`...-linux-x64-setup.AppImage`):

1. Datei ausführbar machen und starten: `chmod +x linefm-radio-X.Y.Z-linux-x64-setup.AppImage && ./linefm-radio-X.Y.Z-linux-x64-setup.AppImage`. Fehlt FUSE, geht es mit `APPIMAGE_EXTRACT_AND_RUN=1` davor.
2. **Optionen**:
   - **Nur für mich** (ohne Root-Rechte): Ziel `~/.local/share/linefm-radio`, Autostart über `~/.config/autostart`.
   - **Alle Benutzer**: Ziel `/opt/linefm-radio`, dazu ein Eintrag in `/usr/share/applications`, Icons in `/usr/share/icons/hicolor`, der Befehl `linefm-radio` (`/usr/local/bin`) und auf Wunsch Autostart für alle (`/etc/xdg/autostart`). Das System fragt über polkit (pkexec) nach dem Administrator-Passwort. Läuft kein polkit-Agent, bricht das Setup mit einer klaren Meldung ab und ändert nichts.
   - Wählbar sind **Verknüpfung auf dem Desktop**, **Eintrag im App-Menü** und **Beim Anmelden automatisch starten**. Links wie `linefm://play` öffnen danach die App.
3. **Deinstallieren**: Rechtsklick auf LINEFM Radio im App-Menü und **LINEFM Radio deinstallieren** wählen. Alternativ bei **Nur für mich** `~/.local/share/linefm-radio-setup/uninstaller/linefm_setup` starten, bei **Alle Benutzer** `/var/lib/linefm-radio-setup/uninstaller/linefm_setup`.

Auf beiden Systemen prüft das Setup vor dem Kopieren den SHA-256 der mitgelieferten App, verhindert ein Zurückstufen auf eine ältere Version und nimmt bei **Abbrechen** alles zurück. Bei **Alle Benutzer** läuft nur ein kleiner Hilfsteil mit Administratorrechten. Er schreibt ausschließlich in feste Systemordner, prüft den SHA-256 dort noch einmal und folgt keinen symbolischen Links. Die `.tar.gz` (Linux) und das App-DMG (macOS) gibt es weiterhin für alle, die ohne Installer auspacken wollen. Aufbau und Sicherheit: [installer/ui/README.md](../installer/ui/README.md).

#### Android

1. Lade `dist-android` herunter und entpacke es auf dem Rechner. Kopiere die Datei `...-android.apk` aufs Handy (USB-Kabel, Cloud-Ordner oder Mail an dich selbst).
2. Tippe auf dem Handy die APK-Datei an.
3. Android fragt, ob dieser Quelle das Installieren erlaubt ist. Tippe auf **Einstellungen** und aktiviere **Aus dieser Quelle zulassen** (der Name hängt vom Hersteller ab, oft "Unbekannte Apps installieren").
4. Gehe zurück und tippe auf **Installieren**.

Woran du erkennst, dass es klappt: Die App "LINEFM Radio" erscheint in der App-Liste.

Die Datei `...-android.aab` ist ein App Bundle. Sie ist nur für den Play Store gedacht und lässt sich nicht aufs Handy installieren. Die APK ist unsigniert, solange kein Upload-Schlüssel eingerichtet ist. Sie installiert sich trotzdem.

#### Web

1. Entpacke `dist-web` und darin `...-web.zip` in einen Ordner, zum Beispiel `C:\LINEFM-web`.
2. Du musst die Seite über einen kleinen Server laden. Ein Doppelklick auf `index.html` funktioniert **nicht**, weil der Browser die Programmdateien dann blockiert.
3. Öffne im Ordner ein Terminal (ein Fenster, in das du Befehle tippst): im Explorer in den Ordner gehen, in die Adresszeile `powershell` tippen, Eingabetaste. Starte dort den Server, Python 3 vorausgesetzt:

```powershell
python -m http.server 8090 --bind 127.0.0.1
```

4. Öffne im Browser <http://localhost:8090>. Beenden kannst du den Server mit Strg+C.

Beachte: Die Dateien aus dem Artefakt sind für die Adresse `https://app.linefm.de` gebaut. Ob sich die Seite so unter `localhost` vollständig bedienen lässt, wurde nicht geprüft. Der Bau mit lokaler Adresse in B6 ist dafür der geprüfte Weg. Für ein echtes Hosting auf einem Server siehe [hosting-uebersicht.md](hosting-uebersicht.md). Die Server-Einstellungsdateien dafür liegen in `...-web-hosting.zip`.

#### Linux

1. Entpacke das Archiv in einen eigenen Ordner:

```bash
mkdir -p ~/linefm-radio && tar -xzf linefm-radio-*-linux-x64.tar.gz -C ~/linefm-radio
cd ~/linefm-radio && ./linefm_radio
```

2. Das Archiv enthält direkt den Inhalt des Bundles, es gibt keinen Unterordner. Deshalb der eigene Zielordner.
3. Startet die App nicht und meldet eine fehlende Bibliothek, fehlt ein System-Paket. Auf Debian und Ubuntu hilft meistens `sudo apt install libmpv2 libgtk-3-0 libayatana-appindicator3-1`. Diese Paketnamen sind nicht geprüft, in der CI laufen nur die Entwicklungspakete (siehe B8).

Statt des Archivs gibt es drei Pakete der App. Alle legen die App gleich ab: Programm in `/usr/lib/linefm-radio`, Befehl `linefm-radio`, Eintrag im App-Menü, Icons und den Handler für `linefm://`-Links. Nimm entweder ein Paket oder den Installer (Abschnitt oben), nicht beides: Der Installer schreibt bei **Alle Benutzer** denselben Menüeintrag.

**.deb** (Debian, Ubuntu, Linux Mint):

```bash
sudo apt install ./linefm-radio-X.Y.Z-linux-x64.deb
linefm-radio
```

`apt` holt die nötigen Bibliotheken (GTK 3, libmpv, AppIndicator, Keybinder, libcurl) selbst. Das Paket ist auf Ubuntu 24.04 gebaut und verlangt deren glibc-Stand, läuft also ab Ubuntu 24.04, Debian 13 und Linux Mint 22. Auf älteren Systemen weist `apt` das Paket mit einer Meldung zu `libc6` ab. Update: neueres Paket genauso installieren. Deinstallieren: `sudo apt remove linefm-radio`.

**.rpm** (Fedora, openSUSE, RHEL und Ableger):

```bash
sudo dnf install ./linefm-radio-X.Y.Z-linux-x64.rpm      # Fedora, RHEL
sudo zypper install ./linefm-radio-X.Y.Z-linux-x64.rpm   # openSUSE
```

Das Paket nennt seine Bibliotheken über deren Dateinamen (zum Beispiel `libmpv.so.2`), deshalb findet jede Distribution das passende Paket selbst. Auf RHEL und Ablegern liegen libmpv und einige weitere Bibliotheken nicht in den Grundquellen. Dort braucht es vorher EPEL und RPM Fusion (auf RHEL nicht nachgespielt). Deinstallieren: `sudo dnf remove linefm-radio` bzw. `sudo zypper remove linefm-radio`.

**AppImage** (jede Distribution, ohne Installation):

```bash
chmod +x linefm-radio-X.Y.Z-linux-x64.AppImage
./linefm-radio-X.Y.Z-linux-x64.AppImage
```

Fehlt FUSE, geht es mit `APPIMAGE_EXTRACT_AND_RUN=1` davor. Das AppImage enthält die App, aber nicht libmpv, GTK und die übrigen System-Bibliotheken. Die müssen installiert sein (Debian, Ubuntu: `sudo apt install libmpv2 libayatana-appindicator3-1 libkeybinder-3.0-0`). Einen Menüeintrag legt das AppImage selbst nicht an. Wer das möchte, nimmt ein Werkzeug wie Gear Lever oder AppImageLauncher, oder gleich den Installer. Entfernen: Datei löschen.

Was die CI bei jedem Bau prüft: Das .deb wird in einem frischen Ubuntu-24.04-Container installiert, das .rpm in einem frischen Fedora-42-Container. Geprüft werden jeweils Installation samt Abhängigkeiten, alle Dateien, der Menüeintrag (`desktop-file-validate`), der registrierte `linefm://`-Handler, dass jede Bibliothek gefunden wird, dass die App startet und 10 Sekunden läuft, das Update auf ein Paket mit höherer Version aus demselben Bundle, dass ein älteres Paket nicht stillschweigend zurückstuft, und dass nach dem Deinstallieren nichts zurückbleibt. Beim AppImage prüft die CI Inhalt, Menüeintrag, Icons und den Start. openSUSE, RHEL, Debian und Mint werden nicht eigens getestet. Englische Fassung: [packaging/linux/README.md](../packaging/linux/README.md). Bau und Prüfung: [packaging/linux/build-packages.sh](../packaging/linux/build-packages.sh) und [packaging/linux/test-packages.sh](../packaging/linux/test-packages.sh).

#### macOS

Das DMG ist weder signiert noch von Apple geprüft ("notarisiert"). macOS warnt deshalb beim ersten Start. Das ist erwartet. Die Anleitung dazu steht auch im DMG selbst als `LIES-MICH-ZUERST.txt`.

1. Öffne das DMG per Doppelklick und ziehe **LINEFM Radio** in **Programme**. Der Hintergrund des DMG-Fensters zeigt diese Schritte als Bild ([Quelle](../packaging/macos/dmg-background.svg)).
2. Starte die App aus dem Ordner Programme. Es erscheint eine Warnung. Schließe sie mit **Fertig**.
3. Öffne **Systemeinstellungen > Datenschutz & Sicherheit**.
4. Scrolle zu **Sicherheit**. Dort steht, dass "LINEFM Radio" blockiert wurde. Klicke auf **Dennoch öffnen** und bestätige mit Passwort oder Touch ID.
5. Ab jetzt startet die App normal.

Bis macOS 14 reichte Rechtsklick auf die App und **Öffnen**. Ab macOS 15 geht es nur über die Systemeinstellungen. Quelle: [packaging/macos/LIES-MICH-ZUERST.txt](../packaging/macos/LIES-MICH-ZUERST.txt). Auf einem echten Mac wurde das in diesem Projekt noch nicht nachgespielt.

**Bildnachweise aus der CI.** Der Workflow **Widget evidence** (`.github/workflows/widget-evidence.yml`, Job *macOS Gatekeeper, title bar and icon*) baut die App unsigniert, packt sie in ein DMG mit Quarantäne-Markierung wie nach einem Browser-Download, kopiert sie nach Programme und versucht sie zu öffnen. Bevor ein Bild entsteht, schließt der Job die Systemmeldung zur Netzwerk-Erweiterung von Harden-Runner und setzt die Quarantäne-Markierung auf die kopierte App, falls sie beim Kopieren verloren ging. DMG-Fenster, Startversuch, Systemeinstellungen und Titelleisten werden auf die Fenstergrenzen zugeschnitten (über System Events), sonst als ganzer Bildschirm. Das Artefakt `desktop-evidence-macos` enthält Bildschirmfotos von DMG-Fenster, Startversuch, **Datenschutz & Sicherheit**, Titelleiste hell und dunkel sowie Symbol in Dock und Finder. Dazu kommt `gatekeeper.txt` mit `spctl --status` und `spctl --assess`. Ob Gatekeeper auf den GitHub-Runnern eingeschaltet ist, dokumentiert GitHub nicht. Zeigt das Bild keinen Warndialog, steht der Grund in `gatekeeper.txt`. Für Linux liefert der Job *Linux title bar light and dark* das Artefakt `desktop-evidence-linux` (Xvfb mit Openbox).

Die Bilder liegen nicht im Repository, weil sie aus einem echten CI-Lauf stammen müssen. Übernehmen geht so:

```bash
gh workflow run widget-evidence.yml --ref main
gh run download <Lauf-ID> -n desktop-evidence-macos -D docs/bilder/macos
gh run download <Lauf-ID> -n desktop-evidence-linux -D docs/bilder/linux
```

Danach die Bilder ansehen und nur einchecken, was den Ablauf wirklich zeigt.

#### iOS

Es gibt keine installierbare iOS-Datei. Der iOS-Teil im Build ist nur eine Kompilierprüfung ohne Signatur und lädt nichts hoch. Eine installierbare iOS-App braucht ein Apple-Entwicklerkonto. Das ist bewusst zurückgestellt, siehe Abschnitt 15 in [EINRICHTUNG.md](EINRICHTUNG.md).

## Teil B: Lokal selbst bauen

Dieser Teil ist für alle, die auf dem eigenen Rechner bauen wollen. Es hilft, wenn du schon mal ein Terminal geöffnet hast, mehr Vorwissen brauchst du nicht. Plane für die Einrichtung eine bis zwei Stunden ein, hauptsächlich Downloads.

### B1 Voraussetzungen

Wähle dein Betriebssystem. Du brauchst nicht alles, nur das für dein Ziel.

Für alle:

| Was | Version | Woher |
|---|---|---|
| Git | aktuell | <https://git-scm.com/downloads> |
| Flutter | **3.50.0** (stable), mit Dart 3.14 | <https://docs.flutter.dev/install/archive> |

Die Version 3.50.0 steht in `.github/actions/setup-flutter/action.yml` (dort baut die CI damit) und in `pubspec.yaml` (`flutter: ">=3.50.0"`). Entpacke Flutter in einen Ordner ohne Leerzeichen, zum Beispiel `C:\dev\flutter`, und füge den Unterordner `flutter\bin` zum PATH hinzu (Windows: Suche **Umgebungsvariablen bearbeiten**, Variable **Path**, **Neu**).

Zusätzlich je Ziel:

| Ziel | Du brauchst | Woher |
|---|---|---|
| Windows | **Visual Studio 2022** oder die "Build Tools" mit dem Workload **Desktopentwicklung mit C++** | <https://visualstudio.microsoft.com/de/downloads/> |
| Windows | **Rust** über rustup (ohne Rust scheitert der Bau) | <https://rustup.rs> |
| Android | **JDK 17** und das **Android SDK** (Android Studio bringt beides mit) | <https://developer.android.com/studio> |
| Linux | clang, cmake, ninja, pkg-config, GTK 3 und weitere Entwicklungspakete (B8) | Paketverwaltung |
| macOS und iOS | **Xcode** und CocoaPods | App Store, `brew install cocoapods` |
| Web | Chrome zum Ansehen, Python 3 für den lokalen Server | <https://www.python.org/downloads/> |

Für Android bestätigst du einmalig die Lizenzen:

```bash
flutter doctor --android-licenses
```

**Erfolgskontrolle:** Öffne ein neues Terminal und führe aus:

```bash
flutter doctor
```

Für dein Ziel muss in der Liste ein grüner Haken stehen (zum Beispiel "Visual Studio" für Windows, "Android toolchain" für Android). Fehlt etwas, zeigt `flutter doctor` in der Zeile, was zu tun ist. Ein fehlender Haken bei einem Ziel, das du nicht baust, ist egal.

### B2 Das Projekt holen

Entweder mit Git:

```bash
git clone https://github.com/VectoDE/linefm-radio-app.git C:\linefm
cd C:\linefm
```

Oder ohne Git: Auf der Repository-Seite auf **Code**, dann **Download ZIP**, entpacken. Das Repository ist öffentlich, du brauchst dafür keine Anmeldung.

Wähle einen **kurzen Ordnerpfad** wie `C:\linefm`. Windows bricht bei Pfaden über 260 Zeichen ab, und ein tief verschachtelter Ordner führt zu Fehlern beim Bauen.

Dann einmal die Pakete holen:

```bash
flutter pub get
```

Du erkennst den Erfolg an der letzten Zeile `Got dependencies!` (oder `Changed N dependencies!`).

### B3 Konfiguration (optional)

Die App baut auch ohne Konfigurationsdatei mit Standardwerten. Das wurde am 21.11.2026 so geprüft (Windows-Bau ohne `config/app.json`). Statistik und Absturzberichte bleiben dann aus.

Wenn du eigene Werte brauchst, zum Beispiel eine andere Web-Adresse, kopiere die Vorlage:

```powershell
copy config\app.example.yaml config\app.yaml
```

```bash
cp config/app.example.yaml config/app.yaml
```

Trage dann in `config/app.yaml` die Werte ein. Über jedem Schlüssel steht als Kommentar, was er bedeutet, welche Werte erlaubt sind und ein Beispiel; mehr in [Konfiguration](KONFIGURATION.md). Die Datei bleibt auf deinem Rechner und wird nicht ins Repository hochgeladen. Das Skript aus Teil C prüft sie und erzeugt daraus selbst die Bauwerte `config/app.json`. Baust du ohne Skript, erzeuge sie mit `dart run tool/check_config.dart --defines config/app.json` und hänge an jeden Bau-Befehl unten ` --dart-define-from-file=config/app.json` an.

### B4 Ziele im Überblick

| Ziel | Befehl | Ergebnis | Geprüft |
|---|---|---|---|
| Windows | `flutter build windows --release` | `build\windows\x64\runner\Release\linefm_radio.exe` | lokal am 21.11.2026 |
| Web | siehe B6 | Ordner `build\web` | lokal am 21.11.2026 |
| Android APK | `flutter build apk --release` | `build\app\outputs\flutter-apk\app-release.apk` | nur CI ([Lauf](https://github.com/VectoDE/linefm-radio-app/actions/runs/44909292173)) |
| Android Bundle | `flutter build appbundle --release` | `build\app\outputs\bundle\release\app-release.aab` | nur CI |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/linefm_radio` | nur CI |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/LINEFM Radio.app` | nur CI |
| iOS | `flutter build ios --release --no-codesign` | kein Installationspaket | nur CI, aktuell rot |

"Lokal am 21.11.2026" heißt: auf dem Rechner des Entwicklers unter Windows 11 mit Flutter 3.50.0 gebaut und gestartet. "Nur CI" heißt: die Befehle stammen aus `build.yml` und liefen dort grün (iOS rot), wurden aber lokal nicht nachgespielt. Die Ausgabepfade der CI-Ziele sind aus `build.yml` abgelesen.

### B5 Windows bauen und starten

Voraussetzungen: Visual Studio mit C++ und Rust (B1), kurzer Projektpfad (B2).

```powershell
cd C:\linefm
flutter pub get
flutter build windows --release
```

Dauer: 282 Sekunden (rund 5 Minuten) am 21.11.2026, ohne `config/app.json`, Windows 11, Flutter 3.50.0. Der erste Bau auf einem neuen Rechner kann länger dauern.

Ergebnis: `build\windows\x64\runner\Release\linefm_radio.exe`. Starte sie per Doppelklick im Explorer oder so:

```powershell
.\build\windows\x64\runner\Release\linefm_radio.exe
```

Der **ganze Ordner `Release`** gehört zusammen. Die EXE läuft nur mit den Dateien und Ordnern daneben. Willst du die App woanders hin kopieren, kopiere den ganzen Ordner.

Typische Fehler:

| Meldung oder Symptom | Ursache und Lösung |
|---|---|
| `cargo` oder `rustc` nicht gefunden, Bau bricht bei `smtc_windows` ab | Rust fehlt. Installiere es mit <https://rustup.rs>, öffne ein neues Terminal. |
| "Unable to find suitable Visual Studio toolchain" | C++-Workload fehlt. Im Visual Studio Installer **Ändern**, **Desktopentwicklung mit C++** anhaken. |
| Fehler mit sehr langen Pfaden, Datei nicht gefunden | Pfad zu lang (MAX_PATH). Projekt in einen kurzen Ordner wie `C:\linefm` legen. |

Den Installer (`setup.exe`) baust du danach mit einem Befehl. Er braucht dieselben Werkzeuge (Visual Studio mit C++, darin ist CMake enthalten) und kompiliert die Setup-Engine sowie das Setup-Fenster:

```powershell
pwsh installer\windows\build.ps1 -Version 1.0.0 -Out dist\linefm-radio-setup.exe
```

Aufbau und Sicherheitsmaßnahmen des Installers stehen in [installer/windows/README.md](../installer/windows/README.md).

### B6 Web bauen und ansehen

Auf diesem Weg wurde am 21.11.2026 gebaut und im Browser geöffnet (Windows 11, Flutter 3.50.0). Die Befehle in PowerShell:

```powershell
flutter build web --release --wasm --no-web-resources-cdn
dart run tool/fetch_font_fallback.dart build/web
dart run tool/web_postbuild.dart build/web --targets none --base-url http://localhost:8090
python -m http.server 8090 --directory build/web
```

Was die Schritte tun:

1. Der erste Befehl baut die Web-App. Der Schalter `--wasm` nutzt das schnellere Format, `--no-web-resources-cdn` legt alle Schriften und Bausteine in den Ordner statt sie bei Google zu laden.
2. Der zweite holt Ersatzschriften für seltene Zeichen und legt sie in den Ordner. Er braucht Internet und prüft jede Datei gegen eine Prüfsumme.
3. Der dritte räumt die Dateien auf (Namen mit Hash, Entfernen von Ballast). `--targets none` lässt die Server-Dateien für Hosting weg, `--base-url` setzt die lokale Adresse.
4. Der vierte startet den Server. Das Terminal bleibt offen, solange der Server läuft.

Öffne danach <http://localhost:8090> im Browser. Du erkennst den Erfolg an der Senderliste der App. Beende den Server mit Strg+C.

**Ein Doppelklick auf `build\web\index.html` funktioniert nicht.** Der Browser lädt die Programmdateien nur über einen Server. Immer über `http://localhost:...` öffnen.

**Bekannte Falle in Git Bash unter Windows:** Gibst du `--base-href /` an, schreibt Git Bash das `/` zu `C:/Program Files/Git/` um, und der Bau bricht ab. Lass `--base-href` einfach weg (der Standard ist `/`), nutze PowerShell oder setze vorher `MSYS_NO_PATHCONV=1`:

```bash
MSYS_NO_PATHCONV=1 flutter build web --release --wasm --no-web-resources-cdn --base-href /
```

Unter Linux und macOS lauten die Schritte genauso. Starte den Server dort mit `python3 -m http.server 8090 --directory build/web`. Startet `dart run tool/...` unter Linux nicht sauber (es baut zusätzlich native Hilfscode und braucht GTK), kopiere die beiden Dateien vorher aus `tool/` in einen Ordner außerhalb des Projekts und starte sie von dort, so macht es die CI. Das Skript in Teil C macht das automatisch.

### B7 Android bauen und installieren

Voraussetzung: JDK 17, Android SDK, bestätigte Lizenzen (B1).

```bash
flutter build apk --release
```

Ergebnis: `build\app\outputs\flutter-apk\app-release.apk`. Kopiere sie aufs Handy und installiere sie wie in A5 beschrieben. Alternativ mit einem per USB verbundenen Handy (Entwickleroptionen und USB-Debugging aktiv):

```bash
flutter devices
flutter install
```

Ohne `android/key.properties` wird die APK nicht mit einem eigenen Schlüssel signiert, sie lässt sich aber installieren. Für den Play Store braucht es das Bundle (`flutter build appbundle --release`) und den Upload-Schlüssel, siehe [packaging/android/SIGNING.md](../packaging/android/SIGNING.md). Das ist ein Betreiber-Thema und steht in [EINRICHTUNG.md](EINRICHTUNG.md).

Beim ersten Android-Bau lädt Gradle viel nach (Gradle selbst, NDK, CMake). Plane dafür Zeit und Internet ein. Die CI räumte dafür extra Platz auf dem Runner frei, du brauchst auf der Platte mehrere GB frei.

### B8 Linux, macOS und iOS bauen

Das wurde in diesem Projekt bisher nur in der CI gebaut, nicht auf einem eigenen Linux-Rechner oder Mac.

**Linux.** Auf Debian und Ubuntu installierst du die Pakete, die auch die CI nutzt (`.github/actions/linux-deps/action.yml`):

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libx11-dev libxi-dev \
  libmpv-dev libayatana-appindicator3-dev libkeybinder-3.0-dev libcurl4-openssl-dev
flutter build linux --release
./build/linux/x64/release/bundle/linefm_radio
```

**macOS.** Xcode aus dem App Store installieren und einmal starten (Lizenz bestätigen), dann `brew install cocoapods`:

```bash
flutter build macos --release
open "build/macos/Build/Products/Release/LINEFM Radio.app"
```

Die App ist unsigniert. Beim Start gelten die Hinweise aus A5 (macOS).

**iOS.** Nur auf einem Mac mit Xcode. Ohne Apple-Entwicklerkonto entsteht nur eine Kompilierprüfung:

```bash
flutter build ios --release --no-codesign
```

Eine installierbare App braucht ein Apple-Konto, siehe Abschnitt 15 in [EINRICHTUNG.md](EINRICHTUNG.md).

### B9 App starten zum Ausprobieren und Entwickeln

Mit `flutter run` startet die App direkt, ohne dass du sie erst fertig baust. Das ist der schnellste Weg beim Entwickeln.

```bash
flutter devices
flutter run -d windows
flutter run -d chrome
flutter run -d <gerät-aus-der-liste>
```

`flutter devices` zeigt, welche Ziele bereitstehen. In der laufenden Sitzung lädt `r` den Code neu, `R` startet die App neu, `q` beendet. Für Android schließt du ein Handy per USB an oder startest einen Emulator aus Android Studio.

Mit eigener Konfiguration: `flutter run -d windows --dart-define-from-file=config/app.json`.

Vor einem Änderungsvorschlag laufen diese drei Prüfungen (Entwickler, siehe [ENTWICKLUNG.md](ENTWICKLUNG.md)):

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test
```

### B10 Weitere Windows-Fallen

- Eine Meldung, dass Dateien in `lib/l10n/gen/` geändert sind, ist harmlos. `flutter build` schreibt sie mit anderen Zeilenenden neu. Nicht committen.
- Schwere Bauten (APK, Windows, Web) nicht gleichzeitig mit `flutter test` starten. Beides braucht viel Arbeitsspeicher.
- Der Windows-Bau mit Rust zieht die Version `2.11.1` von `flutter_rust_bridge` fest. Das ist Absicht, siehe [ENTWICKLUNG.md](ENTWICKLUNG.md).

## Teil C: Start-Skripte

Statt der Befehle aus Teil B kannst du ein Skript starten. Es prüft die Voraussetzungen, holt die Pakete, baut, zeigt dir den Ausgabepfad und öffnet das Ergebnis auf Wunsch. Es installiert nichts und braucht keine Administratorrechte.

| Skript | Für | Ziele |
|---|---|---|
| `tool\bauen.ps1` | Windows (PowerShell 5.1 oder neuer, ohne Zusatzmodule) | `windows`, `web`, `apk`, `aab` |
| `tool/bauen.sh` | Linux und macOS (bash) | `linux`, `macos`, `web`, `apk`, `aab` |

Was geprüft wurde: Die Skripte starten in der CI im Workflow `Build scripts` (`build-scripts.yml`) und bauen dort die Web-Version auf Windows (mit Windows PowerShell 5.1) und auf Ubuntu. Die anderen Ziele (windows, apk, aab, linux, macos) wurden mit den Skripten nicht gebaut, nur ihre Eingabeprüfung wurde getestet. Die dahinterliegenden Befehle sind dieselben wie in Teil B.

### Windows

Öffne PowerShell im Projektordner (im Explorer in den Ordner gehen, in die Adresszeile `powershell` tippen, Eingabetaste). Dann:

```powershell
powershell -File tool\bauen.ps1 -Ziel windows
```

Nur bauen ist die Standardeinstellung. Mit `-Oeffnen` startet das Skript das Ergebnis danach:

```powershell
powershell -File tool\bauen.ps1 -Ziel windows -Oeffnen
powershell -File tool\bauen.ps1 -Ziel web -Oeffnen
powershell -File tool\bauen.ps1 -Ziel apk -Oeffnen
powershell -File tool\bauen.ps1 -Hilfe
```

Was `-Oeffnen` tut: bei `windows` startet es die App, bei `web` startet es einen lokalen Server auf einem freien Port (ab 8090) und öffnet den Browser, bei `apk` und `aab` öffnet es den Ordner mit der Datei. Der Web-Server läuft im selben Fenster, beende ihn mit Strg+C.

Du erkennst den Erfolg an der grünen Zeile `DONE after ... seconds.` mit dem Pfad zum Ergebnis. Bei einem Fehler steht rot `bauen: ERROR:` mit einer Erklärung, und das Skript endet mit Exit-Code 1 (falsche Eingabe: 2).

**Wenn Windows das Skript blockiert** ("Die Ausführung von Skripts ist auf diesem System deaktiviert" oder "nicht digital signiert"): Das passiert vor allem bei einem ZIP-Download von GitHub, weil Windows die Dateien als "aus dem Internet" markiert. Zwei offizielle Wege:

```powershell
# Weg 1: nur diese Dateien freigeben, einmalig
Get-ChildItem -Recurse tool\bauen.ps1 | Unblock-File
powershell -File tool\bauen.ps1 -Ziel windows

# Weg 2: die Richtlinie nur für diesen einen Aufruf lockern
powershell -ExecutionPolicy Bypass -File tool\bauen.ps1 -Ziel windows
```

Weg 2 gilt nur für diesen einen Aufruf und ändert nichts an deinem System. Mit `git clone` (B2) tritt das Problem normalerweise nicht auf. Hintergrund: [Microsoft zu Ausführungsrichtlinien](https://learn.microsoft.com/de-de/powershell/module/microsoft.powershell.core/about/about_execution_policies).

### Linux und macOS

```bash
tool/bauen.sh linux
tool/bauen.sh web --oeffnen
tool/bauen.sh macos --oeffnen
tool/bauen.sh --hilfe
```

Ist das Skript nicht ausführbar (nach einem ZIP-Download), starte es mit `bash tool/bauen.sh web` oder setze das Recht mit `chmod +x tool/bauen.sh`.

Das Verhalten ist wie unter Windows. `--oeffnen` startet bei `linux` die App, bei `macos` die `.app`, bei `web` den Server samt Browser und bei `apk` und `aab` den Dateimanager im Ordner. Mit `--port 9000` wählst du eine andere Start-Portnummer für Web.

### Was die Skripte voraussetzen und prüfen

- `flutter` ist im PATH. Sonst bricht das Skript mit einem Hinweis ab, wo du Flutter 3.50.0 bekommst.
- Windows-Ziel: Rust (`cargo`) und Visual Studio mit C++. Fehlt Rust, bricht es ab. Das Visual Studio findet es über `vswhere`. Fehlt es, warnt es und lässt `flutter` entscheiden.
- Linux-Ziel: die Entwicklungspakete aus B8. macOS-Ziel: Xcode und CocoaPods.
- Android-Ziele: nur ein Hinweis, wenn kein Java gefunden wird.
- Web mit Öffnen: Python.
- Gibt es `config/app.json`, hängt das Skript `--dart-define-from-file=config/app.json` an. Ohne die Datei baut es mit Standardwerten.

## Wenn etwas schiefgeht

| Symptom | Was tun |
|---|---|
| `flutter` wird nicht gefunden | `flutter\bin` in den PATH aufnehmen, ein **neues** Terminal öffnen, `flutter --version` prüfen (soll 3.50.0 zeigen). |
| `flutter doctor` zeigt ein rotes Kreuz | Die Zeile darunter nennt die Lösung. Meist fehlt Visual Studio mit C++, Rust oder die Android-Lizenz (B1). |
| Windows-Bau bricht ab, Pfad zu lang | Projekt in einen kurzen Ordner wie `C:\linefm` legen. |
| `--base-href` wird zu `C:/Program Files/Git/` | Git-Bash-Falle, siehe B6. Argument weglassen oder PowerShell nutzen. |
| Web-Seite bleibt weiß, wenn du `index.html` doppelklickst | Über `http://localhost:...` mit dem Server öffnen (B6). |
| Port 8090 ist belegt | Anderen Port wählen, beim Skript `-Port 9000` bzw. `--port 9000`. |
| Windows-Warnung SmartScreen | **Weitere Informationen**, **Trotzdem ausführen**. |
| macOS lässt die App nicht öffnen | **Datenschutz & Sicherheit**, **Dennoch öffnen** (A5). |
| Android: "App nicht installiert" | Eine ältere Version mit anderer Signatur deinstallieren, erneut versuchen. |
| Der Lauf auf GitHub ist rot | Lauf öffnen, den roten Job anklicken, die Zeile mit dem Fehler kopieren und dem Entwickler schicken. |
| Die Artefakte sind weg | Sie sind nach 14 Tagen gelöscht. Neuen Bau starten (A1). |

Was hier nicht steht: In den [Discussions](https://github.com/VectoDE/linefm-radio-app/discussions) oder über [SUPPORT.md](../SUPPORT.md) bekommst du Hilfe.
