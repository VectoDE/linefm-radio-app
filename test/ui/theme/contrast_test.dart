import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/stations_config.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Senderfarben aus der echten Senderliste (config/stations.yaml, einzige
/// Quelle der Farben): Jeder dort eingetragene Sender muss die
/// Kontrastregeln erfuellen.
List<Station> _configStations() {
  final result = parseStationsConfig(
    File('config/stations.yaml').readAsStringSync(),
  );
  expect(result.ok, isTrue, reason: result.errors.join('; '));
  return result.active.map(stationFromConfig).toList();
}

void main() {
  group('Contrast', () {
    test('Grenzwerte Schwarz/Weiss', () {
      expect(
        Contrast.ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.001),
      );
      expect(Contrast.ratio(Contrast.paper, Contrast.paper), 1);
    });

    test('Spec-Werte (4.4) stimmen', () {
      double r(int a, int b) => Contrast.ratio(Color(a), Color(b));
      expect(r(0xFF898DA1, 0xFF0F1221), closeTo(5.66, 0.01));
      expect(r(0xFF898DA1, 0xFF181B2B), closeTo(5.19, 0.01));
      expect(r(0xFF73778A, 0xFF0F1221), closeTo(4.19, 0.01));
      expect(r(0xFF565A6E, 0xFFF4F5FA), closeTo(6.26, 0.01));
      expect(r(0xFFD6264A, 0xFFFFFFFF), closeTo(4.96, 0.01));
      expect(r(0xFFFFFFFF, 0xFFFF0084), closeTo(3.76, 0.01));
    });
  });

  group('Token-Kontraste', () {
    for (final entry in <String, LinefmColors>{
      'dunkel': LinefmColors.dark,
      'hell': LinefmColors.light,
    }.entries) {
      final c = entry.value;
      test('Text auf allen Grundflaechen >= 4,5:1 (${entry.key})', () {
        for (final bg in <Color>[c.background, c.surface, c.surfaceRaised]) {
          expect(Contrast.ratio(c.text, bg), greaterThanOrEqualTo(4.5));
          expect(Contrast.ratio(c.muted, bg), greaterThanOrEqualTo(4.5));
        }
        for (final bg in <Color>[c.background, c.surface]) {
          expect(Contrast.ratio(c.tickerText, bg), greaterThanOrEqualTo(4.5));
        }
      });
      test('Herz als Icon >= 3:1 auf allen Flaechen (${entry.key})', () {
        for (final bg in <Color>[c.background, c.surface, c.surfaceRaised]) {
          expect(Contrast.ratio(c.heart, bg), greaterThanOrEqualTo(3));
        }
      });
      test('Schalter-Rahmen (muted) >= 3:1 (${entry.key})', () {
        expect(Contrast.ratio(c.muted, c.background), greaterThanOrEqualTo(3));
        expect(Contrast.ratio(c.muted, c.surface), greaterThanOrEqualTo(3));
      });
      test('Schalter an: Knopf Weiss auf Spur >= 3:1 (${entry.key})', () {
        final track = Color.alphaBlend(c.switchTrackOn, c.background);
        expect(
          Contrast.ratio(const Color(0xFFFFFFFF), track),
          greaterThanOrEqualTo(3),
        );
        expect(Contrast.ratio(track, c.background), greaterThanOrEqualTo(3));
      });
    }
  });

  // Ziel je Paar (R4-A): `text` und `tickerText` erreichen AAA (7:1), `muted`
  // ist bewusst nur AA (4,5:1, Sekundaertext wie in der Web-App; Tabelle in
  // lib/ui/theme/tokens.dart und docs/BARRIEREFREIHEIT.md).
  group('Token-Kontraste nach Ziel (AAA wo vorgesehen)', () {
    for (final entry in <String, LinefmColors>{
      'dunkel': LinefmColors.dark,
      'hell': LinefmColors.light,
    }.entries) {
      final c = entry.value;
      final surfaces = <String, Color>{
        'background': c.background,
        'surface': c.surface,
        'surfaceRaised': c.surfaceRaised,
        'miniPlayerBg': Color.alphaBlend(c.miniPlayerBg, c.background),
        'navBg': Color.alphaBlend(c.navBg, c.background),
        'popoverBg': Color.alphaBlend(c.popoverBg, c.background),
      };
      test('text auf allen Flaechen >= 7:1 (${entry.key})', () {
        for (final s in surfaces.entries) {
          expect(
            Contrast.ratio(c.text, s.value),
            greaterThanOrEqualTo(Contrast.aaaText),
            reason: 'text auf ${s.key}',
          );
        }
      });
      test('tickerText auf Grund und Karte >= 7:1 (${entry.key})', () {
        for (final bg in <Color>[c.background, c.surface]) {
          expect(
            Contrast.ratio(c.tickerText, bg),
            greaterThanOrEqualTo(Contrast.aaaText),
          );
        }
      });
      test('muted auf allen Flaechen >= 4,5:1, Ziel AA (${entry.key})', () {
        for (final s in surfaces.entries) {
          expect(
            Contrast.ratio(c.muted, s.value),
            greaterThanOrEqualTo(Contrast.aaText),
            reason: 'muted auf ${s.key}',
          );
        }
      });
      test('onAccent auf accent >= 7:1 (${entry.key})', () {
        expect(
          Contrast.ratio(c.onAccent, c.accent),
          greaterThanOrEqualTo(Contrast.aaaText),
        );
      });
    }
  });

  // Static start page (web/index.html): it is the branded loading screen and,
  // like AppLoader and the native splash, always dark. Same colours as the
  // tokens, body text and `.muted` at 7:1.
  group('Statische Web-Shell', () {
    final html = File('web/index.html').readAsStringSync();
    final style = html.substring(
      html.indexOf('<style>'),
      html.indexOf('</style>'),
    );

    Color css(String pattern) {
      final m = RegExp(pattern).firstMatch(style);
      expect(m, isNotNull, reason: pattern);
      return Color(int.parse('FF${m!.group(1)}', radix: 16));
    }

    const bg = r'html, body \{[^}]*background: #([0-9a-fA-F]{6})';
    const fg = r'html, body \{[^}]*[^-]color: #([0-9a-fA-F]{6})';
    const muted = r'\.muted \{ color: #([0-9a-fA-F]{6})';
    const tokens = LinefmColors.dark;

    test('always dark, no light scheme (matches AppLoader)', () {
      expect(style, isNot(contains('prefers-color-scheme: light')));
      expect(css(bg), loaderBackground);
    });
    test('Farben = Tokens (dunkel)', () {
      expect(css(bg), tokens.background);
      expect(css(fg), tokens.text);
      expect(css(muted), tokens.tickerText);
    });
    test('.muted und Text >= 7:1', () {
      final b = css(bg);
      expect(
        Contrast.ratio(css(muted), b),
        greaterThanOrEqualTo(Contrast.aaaText),
      );
      expect(
        Contrast.ratio(css(fg), b),
        greaterThanOrEqualTo(Contrast.aaaText),
      );
    });
    test('description and station list are visually hidden, not removed', () {
      final shell = html.substring(html.indexOf('<main id="static-shell">'));
      final hidden = RegExp(
        r'<div class="visually-hidden">([\s\S]*?)</div>',
      ).firstMatch(shell);
      expect(hidden, isNotNull);
      expect(hidden!.group(1), contains('<h1>'));
      expect(hidden.group(1), contains('<li>LineFM +MAIN</li>'));
      expect(style, contains('.visually-hidden { position: absolute'));
      expect(style, isNot(contains('.visually-hidden { display: none')));
    });
  });

  group('Text auf Senderfarben', () {
    Color color(String slug) => stationBySlug(slug)!.color;

    test('FobFM und +GAMING bekommen dunklen Text', () {
      expect(Contrast.onColor(color('fobfm')), Contrast.ink);
      expect(Contrast.onColor(color('linefmgaming')), Contrast.ink);
      expect(Contrast.onColor(color('fobfm'), large: true), Contrast.ink);
      expect(
        Contrast.onColor(color('linefmgaming'), large: true),
        Contrast.ink,
      );
    });

    test('MAIN, LOFI, Radio3FM behalten weissen Text', () {
      for (final slug in <String>['linefm', 'linefmlofi', 'radio3fm']) {
        expect(Contrast.onColor(color(slug)), Contrast.paper, reason: slug);
      }
    });

    test('RAP: gross weiss (3,76:1), klein dunkel (4,95:1)', () {
      expect(Contrast.onColor(color('linefmrap'), large: true), Contrast.paper);
      expect(Contrast.onColor(color('linefmrap')), Contrast.ink);
    });

    test('gewaehlter Vordergrund erreicht AA je Groesse', () {
      for (final s in _configStations()) {
        final small = Contrast.onColor(s.color);
        final large = Contrast.onColor(s.color, large: true);
        expect(
          Contrast.ratio(small, s.color),
          greaterThanOrEqualTo(Contrast.aaText),
          reason: s.slug,
        );
        expect(
          Contrast.ratio(large, s.color),
          greaterThanOrEqualTo(Contrast.aaLarge),
          reason: s.slug,
        );
      }
    });
  });

  group('Player-Verlauf', () {
    for (final brightness in Brightness.values) {
      final c = brightness == Brightness.dark
          ? LinefmColors.dark
          : LinefmColors.light;
      test('Vordergrund in Header und Mitte lesbar ($brightness)', () {
        for (final s in _configStations()) {
          final g = StationStyle.playerGradient(s.color, c, brightness);
          final top = StationStyle.onPlayerTop(s.color, c, brightness);
          final mid = StationStyle.onPlayerBody(s.color, c, brightness);
          expect(
            Contrast.ratio(top, g.colors[0]),
            greaterThanOrEqualTo(Contrast.aaText),
            reason: '${s.slug} oben',
          );
          expect(
            Contrast.ratio(mid, g.colors[1]),
            greaterThanOrEqualTo(Contrast.aaText),
            reason: '${s.slug} Mitte',
          );
          // Unterer Verlauf endet im Grund; Text dort ist `text`.
          expect(
            Contrast.ratio(c.text, g.colors[2]),
            greaterThanOrEqualTo(Contrast.aaText),
          );
        }
      });
    }

    test('Kartenrahmen erreicht 3:1 zum Grund (hell und dunkel)', () {
      for (final c in <LinefmColors>[LinefmColors.dark, LinefmColors.light]) {
        for (final s in _configStations()) {
          expect(
            Contrast.ratio(StationStyle.border(s.color, c), c.background),
            greaterThanOrEqualTo(Contrast.aaLarge),
            reason: s.slug,
          );
        }
      }
    });
  });
}
