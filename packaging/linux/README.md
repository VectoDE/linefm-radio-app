# Linux packages

The app itself ships as `.deb`, `.rpm` and AppImage, next to the plain `tar.gz` and the graphical setup (`...-linux-x64-setup.AppImage`, see [installer/ui/README.md](../../installer/ui/README.md)). All files are part of every GitHub release with `SHA256SUMS.txt`, a cosign signature (`*.sigstore.json`) and build provenance. How to check them: [docs/RELEASE-VERIFIZIEREN.md](../../docs/RELEASE-VERIFIZIEREN.md) (German). The German user guide for all formats is in [docs/BAUEN-UND-STARTEN.md](../../docs/BAUEN-UND-STARTEN.md).

The `.deb` and `.rpm` install the same layout: the app in `/usr/lib/linefm-radio`, the command `linefm-radio`, a menu entry, icons and the handler for `linefm://` links. Use either a package or the setup, not both: the setup's "all users" mode writes the same menu entry.

## .deb (Debian, Ubuntu, Linux Mint)

```bash
sudo apt install ./linefm-radio-X.Y.Z-linux-x64.deb
linefm-radio
```

`apt` pulls in the libraries (GTK 3, libmpv, AppIndicator, Keybinder, libcurl). The package is built on Ubuntu 24.04 and needs its glibc, so it runs on Ubuntu 24.04, Debian 13, Linux Mint 22 and newer. Older systems reject it with a message about `libc6`.

- Update: install the newer `.deb` the same way.
- Downgrade: `apt` refuses an older version unless you pass `--allow-downgrades`.
- Uninstall: `sudo apt remove linefm-radio`.

## .rpm (Fedora, openSUSE, RHEL and rebuilds)

```bash
sudo dnf install ./linefm-radio-X.Y.Z-linux-x64.rpm      # Fedora, RHEL
sudo zypper install ./linefm-radio-X.Y.Z-linux-x64.rpm   # openSUSE
```

The package names its libraries by file name (for example `libmpv.so.2`), so every distribution resolves the matching package itself. On RHEL and rebuilds, libmpv and a few other libraries are not in the base repositories; enable EPEL and RPM Fusion first (not tried on RHEL).

- Update: install the newer `.rpm` the same way.
- Downgrade: `dnf install` of an older file keeps the installed newer version; `dnf downgrade` is needed on purpose.
- Uninstall: `sudo dnf remove linefm-radio` or `sudo zypper remove linefm-radio`.

## AppImage (any distribution, no installation)

```bash
chmod +x linefm-radio-X.Y.Z-linux-x64.AppImage
./linefm-radio-X.Y.Z-linux-x64.AppImage
```

Without FUSE, prefix `APPIMAGE_EXTRACT_AND_RUN=1`. The AppImage contains the app but not libmpv, GTK and the other system libraries; they must be installed (Debian, Ubuntu: `sudo apt install libmpv2 libayatana-appindicator3-1 libkeybinder-3.0-0`). It does not add a menu entry by itself; use a tool such as Gear Lever or AppImageLauncher, or the setup. Update: replace the file. Remove: delete the file.

## Build and CI tests

- Build: [build-packages.sh](build-packages.sh) (dpkg-deb, rpmbuild, the SHA-256-pinned appimagetool from `installer/linux/fetch-appimagetool.sh`).
- Tests: [test-packages.sh](test-packages.sh) and [test-in-container.sh](test-in-container.sh), run by the Linux job in `.github/workflows/build.yml`. The `.deb` is tested in a clean Ubuntu 24.04 container, the `.rpm` in a clean Fedora 42 container (images pinned by digest): install with dependencies, files, menu entry (`desktop-file-validate`, errors and warnings fail), registered `linefm://` handler, all shared libraries resolve, the app starts and keeps running for 10 seconds, update to a package with a higher version built from the same bundle, no silent downgrade, nothing left after uninstall. The AppImage is checked on the runner: contents, menu entry, icons and start.
- Not tested separately: openSUSE, RHEL, Debian and Mint. The packages carry no GPG signature and there is no own apt or dnf repository.
