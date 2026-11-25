// Messpunkte fuer die Performance-Messung in der CI.
//
// Standardmaessig AUS: `kPerfMarks` ist eine Compile-Zeit-Konstante, ohne
// `--dart-define=LINEFM_PERF_MARKS=true` entfernt der Compiler jeden Aufruf
// samt Rumpf (Tree Shaking). Release-Builds fuer Nutzer enthalten also
// keinen Messcode und schreiben nichts.
//
// Mit Schalter:
// - Web: `performance.mark('linefm:<name>')`, auslesbar per
//   `performance.getEntriesByType('mark')` (Playwright, Lighthouse
//   "User Timing").
// - Windows, Linux, macOS, Android, iOS: eine Zeile `<name>\t<Mikrosekunden
//   seit 1970, UTC>` an die Datei aus der Umgebungsvariablen
//   `LINEFM_PERF_FILE`. Ohne Variable passiert nichts.
//
// Ausgewertet von tool/perf/ (Workflow .github/workflows/performance.yml).
import 'package:linefm_radio/core/perf/perf_marks_stub.dart'
    if (dart.library.js_interop) 'package:linefm_radio/core/perf/perf_marks_web.dart'
    if (dart.library.io) 'package:linefm_radio/core/perf/perf_marks_io.dart'
    as impl;

/// Messpunkte eingeschaltet (nur Mess-Builds der CI).
const bool kPerfMarks = bool.fromEnvironment('LINEFM_PERF_MARKS');

/// Setzt den Messpunkt [name] (z. B. `first-frame`). Ohne Schalter ohne
/// Wirkung und vom Compiler entfernt.
void perfMark(String name) {
  if (!kPerfMarks) return;
  impl.writeMark(name);
}
