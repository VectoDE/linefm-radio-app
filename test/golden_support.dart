// Gemeinsame Hilfen fuer die Golden-Tests.
//
// Referenzbilder haengen von der Rasterung der Plattform ab. Sie entstehen
// deshalb nur auf dem CI-Runner (siehe docs/ENTWICKLUNG.md, "Goldens
// aktualisieren"). Ausserhalb der CI laufen die Tests durch (Layout, keine
// Ausnahmen), vergleichen aber keine Pixel, damit ein lokaler Lauf nicht
// faelschlich rot wird. `GOLDENS=1` erzwingt den Vergleich auch lokal.
import 'dart:convert' show json;
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Ob Referenzbilder verglichen werden (CI oder `GOLDENS=1`).
bool get goldensActive =>
    Platform.environment['GITHUB_ACTIONS'] == 'true' ||
    Platform.environment['GOLDENS'] == '1';

/// Ersetzt den Vergleicher durch einen, der immer besteht, solange
/// [goldensActive] false ist. Mit `--update-goldens` bleibt der echte
/// Vergleicher erhalten, damit Bilder auch lokal geschrieben werden koennen.
void configureGoldenComparator() {
  if (goldensActive || autoUpdateGoldenFiles) return;
  goldenFileComparator = _SkippingComparator();
  debugPrint(
    'Golden-Vergleich uebersprungen: Referenzbilder gelten nur auf dem '
    'CI-Runner (GITHUB_ACTIONS=true oder GOLDENS=1).',
  );
}

class _SkippingComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

/// Laedt alle gebuendelten Schriften aus dem Font-Manifest (nicht die
/// Testschrift Ahem), damit Goldens echten Text und echte Icons zeigen:
/// Poppins, Syncopate, Font Awesome und die Material-Icons.
Future<void> loadAppFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Aufruf in `setUpAll`: Schriften laden, Vergleicher festlegen.
Future<void> prepareGoldens() async {
  await loadAppFonts();
  configureGoldenComparator();
}

/// Wartet echte Zeit ab, damit asynchron dekodierte Bilder (Senderlogos) vor dem
/// Vergleich sicher geladen und eingeblendet sind. Feste Rundenzahl statt
/// Schleife bis "fertig": das Ergebnis haengt nicht vom Zufall ab.
Future<void> settleImages(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Feste Fenstergroesse bei Pixelverhaeltnis 1.
void useGoldenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Unterdrueckt die reine Debug-Warnung zu den Lokalisierungs-Delegates
/// (material_ui und Cupertino kollidieren, siehe P01-Bericht 2).
void ignoreDelegateWarning() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('localization delegates')) return;
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

/// App-Rahmen fuer reine Widget-Goldens: Theme, Deutsch, feste Lokalisierung.
Widget goldenApp({required Brightness brightness, required Widget child}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLinefmTheme(brightness),
      locale: const Locale('de'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// Name der Variante im Dateinamen: `dark` oder `light`.
String variant(Brightness brightness) =>
    brightness == Brightness.dark ? 'dark' : 'light';
