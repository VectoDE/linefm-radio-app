// Rendert jede Seite der Setup-Oberfläche in Dunkel/Hell und Deutsch/Englisch
// mit den echten Schriften nach build/screenshots/*.png. Die CI lädt die
// Bilder als Artefakt "installer-screenshots" hoch (Sichtprüfung, kein
// Pixelvergleich).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_setup/src/app.dart';
import 'package:linefm_setup/src/context.dart';
import 'package:linefm_setup/src/controller.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

Future<void> _loadFonts() async {
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final poppins = FontLoader('Poppins')
    ..addFont(read('assets/fonts/Poppins-Regular.ttf'))
    ..addFont(read('assets/fonts/Poppins-SemiBold.ttf'));
  final syncopate = FontLoader('Syncopate')
    ..addFont(read('assets/fonts/Syncopate-Bold.ttf'));
  await poppins.load();
  await syncopate.load();
  // Material-Symbole aus dem Flutter-SDK (in der echten Oberfläche gebündelt).
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (root != null && icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(read(icons.path))).load();
  }
}

void main() {
  setUpAll(_loadFonts);

  final out = Directory('build/screenshots');

  Future<void> shoot(
    WidgetTester tester,
    String name,
    SetupController Function(FakePlatform p) build, {
    required Locale locale,
    required ThemeMode mode,
    Future<void> Function(SetupController c, FakePlatform p)? after,
  }) async {
    tester.view.physicalSize = const Size(844 * 1.25, 620 * 1.25);
    tester.view.devicePixelRatio = 1.25;
    addTearDown(tester.view.reset);
    final platform = FakePlatform();
    final c = build(platform);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: SetupApp(controller: c, locale: locale, themeMode: mode),
      ),
    );
    await tester.runAsync(() async {
      final ctx = key.currentContext!;
      await precacheImage(const AssetImage('assets/images/logo.png'), ctx);
    });
    await tester.pump(const Duration(milliseconds: 400));
    if (after != null) {
      await after(c, platform);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.25);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    out.createSync(recursive: true);
    final suffix = '${locale.languageCode}-${mode.name}';
    File('${out.path}/$name-$suffix.png').writeAsBytesSync(bytes!);
  }

  SetupController install(FakePlatform p, {Installed? user}) => SetupController(
    context: installContext(user: user),
    platform: p,
    exit: (_) {},
    licenseText: licenseSample,
  );

  const old = Installed(
    version: '1.1.0',
    scope: Scope.user,
    dir: r'C:\Users\a\AppData\Local\Programs\LINEFM Radio',
    desktop: true,
    startMenu: true,
    autostart: false,
  );

  final cases =
      <
        String,
        (
          SetupController Function(FakePlatform),
          Future<void> Function(SetupController, FakePlatform)?,
        )
      >{
        '01-willkommen': (install, null),
        '02-lizenz': (
          install,
          (c, p) async {
            await c.next();
            c.setLicenseAccepted(true);
          },
        ),
        '03-optionen': (
          install,
          (c, p) async {
            c.goTo(SetupStep.options);
            c.setScope(Scope.user);
          },
        ),
        '04-fortschritt': (
          install,
          (c, p) async {
            c.goTo(SetupStep.options);
            await c.next();
            p.emit('hello 1');
            p.emit('phase copying');
            p.emit('progress 42 100');
          },
        ),
        '05-app-laeuft': (
          install,
          (c, p) async {
            c.goTo(SetupStep.options);
            await c.next();
            p.emit('phase closing');
            p.emit('running\tLINEFM Radio');
          },
        ),
        '06-fertig': (
          install,
          (c, p) async {
            c.goTo(SetupStep.options);
            await c.next();
            p.emit(r'result 0 C:\Users\a\AppData\Local\Programs\LINEFM Radio');
            p.exitsCtrl.add(0);
          },
        ),
        '07-fehler': (
          install,
          (c, p) async {
            c.goTo(SetupStep.options);
            await c.next();
            p.emit('log Ziel: C:\\Users\\a\\AppData\\Local\\Programs');
            p.emit('result 11 Nicht genug Speicherplatz auf dem Laufwerk.');
            p.exitsCtrl.add(11);
          },
        ),
        '08-update': ((p) => install(p, user: old), null),
        '09-deinstallieren': (
          (p) => SetupController(
            context: uninstallContext(),
            platform: p,
            exit: (_) {},
          ),
          null,
        ),
      };

  for (final entry in cases.entries) {
    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final mode in const [ThemeMode.dark, ThemeMode.light]) {
        testWidgets('${entry.key} ${locale.languageCode} ${mode.name}', (
          tester,
        ) async {
          await shoot(
            tester,
            entry.key,
            entry.value.$1,
            locale: locale,
            mode: mode,
            after: entry.value.$2,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
