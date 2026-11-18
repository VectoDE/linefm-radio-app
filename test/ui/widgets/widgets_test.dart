import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/settings_switch.dart';
import 'package:linefm_radio/ui/widgets/station_art.dart';
import 'package:linefm_radio/ui/widgets/volume_steps.dart';
import 'package:material_ui/material_ui.dart';

Widget host(
  Widget child, {
  double width = 300,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: buildLinefmTheme(Brightness.dark),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: app!,
    ),
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('stationInitials', () {
    test('wie Web-App: ohne LineFM und +, 3 Zeichen, gross', () {
      expect(stationInitials('LineFM +MAIN'), 'MAI');
      expect(stationInitials('LineFM +RAP'), 'RAP');
      expect(stationInitials('Radio3FM'), 'RAD');
      expect(stationInitials('FobFM'), 'FOB');
      expect(stationInitials('LineFM'), 'LIN');
    });
  });

  group('MarqueeText', () {
    const long =
        'Ein sehr langer Songtitel der garantiert nicht in die Zeile passt';

    testWidgets('kurzer Text steht still', (tester) async {
      await tester.pumpWidget(host(const MarqueeText('Kurz')));
      expect(find.text('Kurz'), findsOneWidget);
      // Kein Band: keine Animation laeuft.
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('langer Text laeuft als Band mit Duplikat', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const MarqueeText(long), width: 120));
      await tester.pump();
      expect(find.text(long), findsNWidgets(2));
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.bySemanticsLabel(long), findsOneWidget);
      handle.dispose();
    });

    testWidgets('enabled=false: statisch mit Ellipse', (tester) async {
      await tester.pumpWidget(
        host(const MarqueeText(long, enabled: false), width: 120),
      );
      expect(find.text(long), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('disableAnimations: statisch', (tester) async {
      await tester.pumpWidget(
        host(const MarqueeText(long), width: 120, disableAnimations: true),
      );
      expect(find.text(long), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('VolumeSteps', () {
    testWidgets('10 Stufen, Slider-Semantik und Wert', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          VolumeSteps(
            volume: 0.7,
            onChanged: (_) {},
            semanticLabel: 'Lautstaerke',
            valueLabel: (p) => 'Lautstaerke $p Prozent',
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(VolumeSteps));
      expect(node.label, 'Lautstaerke');
      expect(node.value, 'Lautstaerke 70 Prozent');
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('Tippen oben = 100 %, unten = 10 %', (tester) async {
      double? last;
      await tester.pumpWidget(
        host(VolumeSteps(volume: 0.5, onChanged: (v) => last = v)),
      );
      final box = tester.getRect(find.byType(VolumeSteps));
      await tester.tapAt(box.topCenter + const Offset(0, 2));
      expect(last, 1.0);
      await tester.tapAt(box.bottomCenter - const Offset(0, 2));
      expect(last, 0.1);
    });

    testWidgets('Pfeiltasten aendern in 10er-Schritten', (tester) async {
      double? last;
      await tester.pumpWidget(
        host(VolumeSteps(volume: 0.5, onChanged: (v) => last = v)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(last, closeTo(0.6, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(last, closeTo(0.1, 1e-9));
    });

    test('Stufe wird auf 1 bis 10 begrenzt', () {
      expect(VolumeSteps.volumeForLevel(0), 0.1);
      expect(VolumeSteps.volumeForLevel(11), 1.0);
      expect(VolumeSteps(volume: 0.04, onChanged: (_) {}).level, 1);
      expect(VolumeSteps(volume: 1, onChanged: (_) {}).level, 10);
    });
  });

  group('SettingsSwitch', () {
    testWidgets('Tippen schaltet, Semantik toggled', (tester) async {
      final handle = tester.ensureSemantics();
      var value = false;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => SettingsSwitch(
              title: 'Lauftext',
              subtitle: 'Beschreibung',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      final before = tester.getSemantics(find.byType(SettingsSwitch));
      expect(before.label, contains('Lauftext'));
      expect(
        before.getSemanticsData().flagsCollection.isToggled,
        Tristate.isFalse,
      );
      await tester.tap(find.text('Lauftext'));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      final after = tester.getSemantics(find.byType(SettingsSwitch));
      expect(
        after.getSemanticsData().flagsCollection.isToggled,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('onChanged null: nicht schaltbar', (tester) async {
      await tester.pumpWidget(
        host(
          const SettingsSwitch(
            title: 'Aus',
            subtitle: 'x',
            value: false,
            onChanged: null,
          ),
        ),
      );
      await tester.tap(find.text('Aus'));
      await tester.pump();
      expect(find.byType(SettingsSwitch), findsOneWidget);
    });
  });

  group('PlayButton', () {
    testWidgets('idle ruft onPressed, Label Play', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        host(
          PlayButton(
            status: PlayerStatus.idle,
            onPressed: () => taps++,
            labelPlay: 'Stream starten',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PlayButton)).label,
        'Stream starten',
      );
      await tester.tap(find.byType(PlayButton));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('connecting: Spinner, kein Tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          PlayButton(status: PlayerStatus.connecting, onPressed: () => taps++),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(PlayButton));
      expect(taps, 0);
    });

    testWidgets('playing zeigt Stop-Label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          PlayButton(
            status: PlayerStatus.playing,
            onPressed: () {},
            labelStop: 'Stream stoppen',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PlayButton)).label,
        'Stream stoppen',
      );
      handle.dispose();
    });
  });

  testWidgets('SectionHeading: Grossbuchstaben und Ueberschrift', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const SectionHeading('Alle Stationen')));
    expect(find.text('ALLE STATIONEN'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('ALLE STATIONEN'))
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('StationArt zeigt Kuerzel ohne Logo-Asset', (tester) async {
    await tester.pumpWidget(
      host(StationArt(station: stationsCatalog.first, size: 48)),
    );
    await tester.pump();
    expect(find.text('MAI'), findsOneWidget);
  });
}
