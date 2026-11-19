import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/player/player_strings.dart';
import 'package:linefm_radio/features/player/player_view.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

/// Rendert den Player in mehreren Groessen nach `build/p13_screens/*.png`
/// (zur Sichtpruefung gegen die Web-App, kein Pixelvergleich: Schriftglaettung
/// unterscheidet sich je Plattform). Der Test sichert, dass kein Layoutfehler
/// (Overflow) auftritt.
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        File('assets/fonts/$f')
            .readAsBytes()
            .then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }

  await load('Poppins', <String>[
    'Poppins-Regular.ttf',
    'Poppins-SemiBold.ttf',
  ]);
  await load('Syncopate', <String>['Syncopate-Bold.ttf']);
  final fa = <String, String>{
    'FontAwesomeSolid': 'Font-Awesome-7-Free-Solid-900.otf',
    'FontAwesomeRegular': 'Font-Awesome-7-Free-Regular-400.otf',
    'FontAwesomeBrands': 'Font-Awesome-7-Brands-Regular-400.otf',
  };
  for (final entry in fa.entries) {
    final file = File(_faPath(entry.value));
    if (!file.existsSync()) continue;
    final loader = FontLoader('packages/font_awesome_flutter/${entry.key}')
      ..addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
  }
}

String _faPath(String name) {
  final config = File('.dart_tool/package_config.json').readAsStringSync();
  final match = RegExp(
    r'"name": "font_awesome_flutter",\s*"rootUri": "([^"]+)"',
  ).firstMatch(config)!;
  var root = match.group(1)!;
  if (root.startsWith('file:///')) root = Uri.parse(root).toFilePath();
  return '$root/lib/fonts/$name';
}

class _Case {
  const _Case(
    this.name,
    this.size,
    this.data, {
    this.brightness = Brightness.dark,
    this.embedded = false,
    this.topInset = 0,
    this.bottomInset = 0,
  });

  final String name;
  final Size size;
  final PlayerViewData data;
  final Brightness brightness;
  final bool embedded;
  final double topInset;
  final double bottomInset;
}

const _hype = Track(artist: 'James Hype', title: "I Was Lovin' You");
const _long = Track(
  artist: 'Michael Calfan, Nobody Else & Friends',
  title: 'Ein sehr langer Songtitel, der garantiert nicht in die Zeile passt',
);

void main() {
  setUpAll(_loadFonts);

  final main = stationsCatalog[0];
  final rap = stationsCatalog[1];
  final fob = stationsCatalog[5];
  final cases = <_Case>[
    _Case(
      'phone_dark_playing',
      const Size(390, 844),
      PlayerViewData(
        station: main,
        track: _hype,
        status: PlayerStatus.playing,
        listeners: 187,
        isFavorite: true,
      ),
      topInset: 100,
      bottomInset: 110,
    ),
    _Case(
      'phone_dark_idle_rap',
      const Size(390, 844),
      PlayerViewData(station: rap, track: _hype),
      topInset: 100,
      bottomInset: 110,
    ),
    _Case(
      'phone_dark_connecting_long',
      const Size(360, 640),
      PlayerViewData(
        station: stationsCatalog[2],
        track: _long,
        status: PlayerStatus.connecting,
        listeners: 1,
      ),
      topInset: 80,
      bottomInset: 90,
    ),
    _Case(
      'phone_dark_error_no_track',
      const Size(390, 844),
      PlayerViewData(station: main, status: PlayerStatus.error),
      topInset: 100,
      bottomInset: 110,
    ),
    _Case(
      'phone_light_fobfm',
      const Size(390, 844),
      PlayerViewData(
        station: fob,
        track: _hype,
        status: PlayerStatus.playing,
        listeners: 12,
      ),
      brightness: Brightness.light,
      topInset: 100,
      bottomInset: 110,
    ),
    _Case(
      'tablet_dark',
      const Size(800, 1180),
      PlayerViewData(
        station: stationsCatalog[3],
        track: _hype,
        status: PlayerStatus.playing,
        listeners: 54,
      ),
      topInset: 100,
      bottomInset: 110,
    ),
    _Case(
      'column_dark',
      const Size(420, 900),
      PlayerViewData(
        station: stationsCatalog[4],
        track: _hype,
        status: PlayerStatus.playing,
        listeners: 2310,
      ),
      embedded: true,
      topInset: 24,
      bottomInset: 24,
    ),
  ];

  for (final c in cases) {
    testWidgets('rendert ${c.name} ohne Layoutfehler', (tester) async {
      // Flutter-Tests zeichnen Schatten sonst als harte Flaechen.
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      tester.view.physicalSize = c.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLinefmTheme(c.brightness),
          locale: const Locale('de'),
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(
            key: key,
            child: Builder(
              builder: (context) => PlayerView(
                data: c.data,
                strings: PlayerStrings.of(AppLocalizations.of(context)),
                embedded: c.embedded,
                topInset: c.topInset,
                bottomInset: c.bottomInset,
                onTogglePlayback: () {},
                onShuffle: () {},
                onToggleFavorite: () {},
                onShare: () {},
                onOpenMusicLinks: () {},
                onNextStation: () {},
                onPreviousStation: () {},
                onClose: c.embedded ? null : () {},
                onRetry: () {},
              ),
            ),
          ),
        ),
      );
      // Senderlogo vorladen, sonst bleibt nur das Kuerzel sichtbar.
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage(c.data.station.logoAsset),
          tester.element(find.byType(PlayerView)),
        );
      });
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);

      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/p13_screens')..createSync(recursive: true);
        File('${dir.path}/${c.name}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
