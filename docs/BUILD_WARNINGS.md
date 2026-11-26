# Zero-warning builds

Every CI job log must be free of warnings and errors, including output from
third-party plugins and native libraries. A warning is treated as a defect and
fixed where it comes from.

## How it is enforced

`build.yml` and `ci.yml` end with a **Build log gate** job. It downloads the log
of every finished job in the run and runs `tool/check_build_logs.py` on it. The
job fails on any line that matches one of these rule groups:

| Rule | Examples |
| --- | --- |
| `cmake` | `CMake Warning (dev)`, `CMake Deprecation Warning`, `CMake Error` |
| `msvc` | `warning C4267:`, `error LNK2019:` |
| `compiler` | `file.c:12:3: warning:` (GCC, Clang, Swift) |
| `tool` | `warning:` / `ld: warning:` at line start (Xcode, linker) |
| `flutter/gradle` | `Warning: ...`, `WARNING: ...`, `FAILURE:` |
| `kotlin` | `w: file:///...`, `e: file:///...` |
| `gradle-deprecation` | `Deprecated Gradle features were used` |
| `powershell` | `+ CategoryInfo :`, `FullyQualifiedErrorId` |
| `annotation` | `##[warning]`, `##[error]` |
| `dart-analyzer` | `info - ...`, `warning - ...` |
| `pub-outdated` | `  cross_file 0.3.5+5 (0.4.0 available)`, `! pkg 1.0.0 (overridden)` |
| `pub-summary` | `N packages have newer versions incompatible ...` |
| `npm` | `npm WARN` |

Lines the runner echoes for a script (`run:` source, shown in cyan) are ignored,
so a script may contain `echo "::warning::..."` without tripping the gate. The
output of that echo still counts.

Check a saved log locally:

```sh
python3 tool/check_build_logs.py build.log
# or a whole run (needs a token with actions:read)
GH_TOKEN=... bash tool/fetch_job_logs.sh OWNER/NAME RUN_ID 1 logs && python3 tool/check_build_logs.py logs/*.log
```

## Third-party patches

`cmake/third_party_patches.cmake` applies pinned text replacements during the
CMake configure step of the Windows and Linux builds. Each replacement checks
its original text first and stops the build if upstream changed the file, so a
patch never silently stops applying. Drop an entry as soon as the upstream
release with the fix is in `pubspec.lock`.

| Dependency | Warning | Fix |
| --- | --- | --- |
| media_kit_libs_windows_audio 1.0.9 | CMake CMP0175: `add_custom_command(TARGET)` without build stage | explicit `POST_BUILD` (the previous implicit behaviour) |
| media_kit_libs_windows_audio 1.0.9, media_kit_libs_linux 1.2.1 | deprecated `make_directory()` | `file(MAKE_DIRECTORY)` |
| smtc_windows 1.1.0 (cargokit) | PowerShell `Get-Item` error on the hidden `AppData` folder | `Get-Item -Force -LiteralPath` |
| sentry-native 0.17.6 on Linux | Clang `-Wc11-extensions` (`_Generic`) | `CMAKE_C_STANDARD 11` in `linux/CMakeLists.txt` |

Fixes in the app itself:

- macOS: the Flutter Assemble script phase is marked `alwaysOutOfDate`, which is
  what Xcode asks for when a phase has no declared outputs.
- Web: unfilled legal placeholders in `web/*/index.html` are passed through as
  `--web-define=NAME={{NAME}}` (`tool/web_define_passthrough.sh`), so builds
  without operator data keep the pages unchanged and Flutter has nothing to
  warn about.

## Allow-list

`tool/build_log_allowlist.json` lists the lines that cannot be fixed on our side
today. Every entry has a reason and an expiry date; an expired entry fails the
gate until someone re-checks it. Current entries:

- Packages pinned by the Flutter SDK (`material_color_utilities`, `test_api`).
- Packages held back by the latest release of a direct dependency
  (`cross_file`, `dbus`, `equatable`, `cli_util`).
- `flutter_rust_bridge` 2.11.1, required by the bindings shipped in
  `smtc_windows` 1.1.0.
- The Flutter notice about plugins that still apply the Kotlin Gradle Plugin
  (`alarm`, `home_widget`).
- The notice that `flutter build ios --no-codesign` prints for the unsigned
  iOS compile check.

Keep the list short. A new entry needs a reason that names the upstream owner
and an expiry date at most three months out, except for notices that are part
of a deliberate build setup.
