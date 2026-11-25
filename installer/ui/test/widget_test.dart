import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_setup/src/app.dart';
import 'package:linefm_setup/src/controller.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  late FakePlatform platform;
  late List<int> exits;

  Future<SetupController> pump(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
    ThemeMode mode = ThemeMode.dark,
    bool uninstall = false,
  }) async {
    tester.view.physicalSize = const Size(844, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    platform = FakePlatform();
    exits = [];
    final c = SetupController(
      context: uninstall ? uninstallContext() : installContext(),
      platform: platform,
      exit: exits.add,
      licenseText: licenseSample,
    );
    await tester.pumpWidget(
      SetupApp(controller: c, locale: locale, themeMode: mode),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('Installation per Tastatur bis zum Fortschritt', (tester) async {
    final c = await pump(tester);
    expect(find.text('LINEFM Radio installieren'), findsOneWidget);
    // Primärknopf hat den Fokus: Enter löst ihn aus.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(c.step, SetupStep.license);
    expect(find.text('Lizenzbedingungen'), findsOneWidget);
    await tester.tap(find.text('Ich akzeptiere die Lizenzbedingungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(c.step, SetupStep.options);
    expect(find.text('Nur für mich'), findsOneWidget);
    await tester.tap(find.text('Installieren'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.step, SetupStep.progress);
    expect(platform.starts, hasLength(1));
    platform.emit('phase copying');
    platform.emit('progress 1 2');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dateien werden kopiert …'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
  });

  testWidgets('Schrittliste ist für Screenreader beschriftet', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      find.bySemanticsLabel('Schritt 1 von 5: Willkommen'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Schritt 5 von 5: Fertig'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Escape fragt vor dem Abbrechen nach', (tester) async {
    await pump(tester, locale: const Locale('en'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Cancel setup?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(exits, isEmpty);
    platform.closeCtrl.add(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();
    expect(exits, [2]);
  });

  testWidgets('Laufende App: Dialog und Antwort', (tester) async {
    final c = await pump(tester);
    c.goTo(SetupStep.options);
    await c.next();
    await tester.pump(const Duration(milliseconds: 400));
    platform.emit('running\tLINEFM Radio');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LINEFM Radio läuft noch'), findsOneWidget);
    await tester.tap(find.text('Beenden und fortfahren'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(platform.sent, ['close']);
  });

  testWidgets('Fertig startet die App und beendet mit 0', (tester) async {
    final c = await pump(tester, mode: ThemeMode.light);
    c.goTo(SetupStep.options);
    await c.next();
    platform.emit(r'result 0 C:\Apps\LINEFM Radio');
    platform.exitsCtrl.add(0);
    await tester.pumpAndSettle();
    expect(find.text('LINEFM Radio ist installiert'), findsOneWidget);
    await tester.tap(find.text('Fertig').last);
    await tester.pumpAndSettle();
    expect(platform.launched, [r'C:\Apps\LINEFM Radio\linefm_radio.exe']);
    expect(exits, [0]);
  });

  testWidgets('Fehler zeigt Meldung und Exit-Code', (tester) async {
    final c = await pump(tester, locale: const Locale('en'));
    c.goTo(SetupStep.options);
    await c.next();
    platform.emit('log Fehler: kein Platz');
    platform.emit('result 11 Nicht genug Speicherplatz');
    platform.exitsCtrl.add(11);
    await tester.pumpAndSettle();
    expect(find.text('That did not work'), findsOneWidget);
    expect(
      find.text('There is not enough space on the drive.'),
      findsOneWidget,
    );
    expect(find.text('Exit code 11'), findsOneWidget);
  });

  testWidgets('Deinstallation mit Nachfrage zu den Daten', (tester) async {
    final c = await pump(tester, uninstall: true);
    expect(find.text('LINEFM Radio deinstallieren?'), findsOneWidget);
    await tester.tap(
      find.text('Auch meine Einstellungen, Favoriten und Wecker löschen'),
    );
    await tester.pumpAndSettle();
    expect(c.deleteUserData, isTrue);
    await tester.tap(find.text('Deinstallieren'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(platform.starts.single.args, contains('--delete-user-data'));
  });

  testWidgets('Großer Text: kein Überlauf auf den Seiten', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await pump(tester);
    for (final step in [
      SetupStep.welcome,
      SetupStep.license,
      SetupStep.options,
    ]) {
      c.goTo(step);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$step');
    }
  });
}
