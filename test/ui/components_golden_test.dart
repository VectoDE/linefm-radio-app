@Tags(<String>['golden'])
library;

// Bildvergleich der Kernkomponenten in Dark und Hell (Issue #2). Referenzbilder
// entstehen auf dem CI-Runner, siehe test/golden_support.dart und
// docs/ENTWICKLUNG.md ("Goldens aktualisieren").
import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/data/storage/prefs_store.dart';
import 'package:linefm_radio/domain/app_settings.dart';
import 'package:linefm_radio/domain/favorite.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/features/consent/consent_dialog.dart';
import 'package:linefm_radio/features/favorites/favorites_header_button.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/features/player/music_links_sheet.dart';
import 'package:linefm_radio/features/player/player_strings.dart';
import 'package:linefm_radio/features/player/player_view.dart';
import 'package:linefm_radio/features/stations/station_card.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/settings_switch.dart';
import 'package:material_ui/material_ui.dart';

import '../features/stations/stations_test_host.dart';
import '../golden_support.dart';

const Size _phone = Size(390, 844);

/// Sender ohne ladbares Logo: das Kuerzel bleibt sichtbar, das Bild
/// (asynchron dekodiert) kann das Ergebnis nicht beeinflussen.
Station _plain(Station s) => Station(
  id: s.id,
  slug: s.slug,
  displayName: s.displayName,
  color: s.color,
  logoAsset: 'assets/images/golden-ohne-logo.png',
  logoUrl: s.logoUrl,
  fallbackStreamUrl: s.fallbackStreamUrl,
);

Future<void> _matches(String name, Brightness brightness) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/${name}_${variant(brightness)}.png'),
);

/// Feste Einstellungen (Lauftext aus: statisch) und Favoriten in den Fake-Speicher
/// des [Harness] schreiben, bevor das erste Widget liest.
Future<void> _seed(Harness h, {int favorites = 0}) async {
  final prefs = h.container.read(prefsProvider) as InMemoryPrefsStore;
  await prefs.writeSettings(const AppSettings(marquee: false));
  await prefs.writeFavorites(<Favorite>[
    for (var i = 0; i < favorites; i++)
      Favorite(
        key: 'linefm:artist $i:titel $i',
        stationSlug: 'linefm',
        title: 'Titel $i',
        artist: 'Artist $i',
        savedAt: DateTime(2026, 11, 18, 20, i),
      ),
  ]);
}

void main() {
  setUpAll(prepareGoldens);

  for (final brightness in Brightness.values) {
    final mode = variant(brightness);

    group('Golden $mode', () {
      testWidgets('Stationskarte: Zeile, aktiv mit Favorit, Kachel', (
        tester,
      ) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 520));
        final main = _plain(stationsCatalog[0]);
        final rap = _plain(stationsCatalog[1]);
        final fob = _plain(stationsCatalog[5]);
        await tester.pumpWidget(
          goldenApp(
            brightness: brightness,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StationCard(
                    station: main,
                    semanticLabel: 'Sender',
                    ticker: "James Hype - I Was Lovin' You",
                    marquee: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  StationCard(
                    station: rap,
                    semanticLabel: 'Sender',
                    ticker:
                        'Ein Kuenstler mit sehr langem Namen - Ein ebenso '
                        'langer Songtitel',
                    active: true,
                    playing: true,
                    favorite: true,
                    marquee: false,
                    onTap: () {},
                    onToggleFavorite: () {},
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: StationCard(
                      station: fob,
                      semanticLabel: 'Sender',
                      ticker: 'Ava Max - My Head & My Heart',
                      grid: true,
                      marquee: false,
                      onTap: () {},
                      onToggleFavorite: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await _matches('station_card', brightness);
      });

      testWidgets('Play-Knopf: Start, Verbinden, Stop', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(300, 110));
        await tester.pumpWidget(
          goldenApp(
            brightness: brightness,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: <Widget>[
                  for (final status in <PlayerStatus>[
                    PlayerStatus.idle,
                    PlayerStatus.connecting,
                    PlayerStatus.playing,
                  ])
                    PlayButton(status: status, onPressed: () {}),
                ],
              ),
            ),
          ),
        );
        await _matches('play_button', brightness);
      });

      testWidgets('Mini-Player', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 130));
        final h = Harness(brightness: brightness);
        addTearDown(h.container.dispose);
        await _seed(h);
        await tester.pumpWidget(
          h.app(
            const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
          ),
        );
        await settle(tester);
        await settleImages(tester);
        await _matches('mini_player', brightness);
      });

      testWidgets('Player-Ansicht', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, _phone);
        await tester.pumpWidget(
          goldenApp(
            brightness: brightness,
            child: Builder(
              builder: (context) => PlayerView(
                data: PlayerViewData(
                  station: _plain(stationsCatalog[0]),
                  track: const Track(
                    artist: 'James Hype',
                    title: "I Was Lovin' You",
                  ),
                  status: PlayerStatus.playing,
                  listeners: 187,
                  isFavorite: true,
                  marquee: false,
                ),
                strings: PlayerStrings.of(AppLocalizations.of(context)),
                topInset: 100,
                bottomInset: 110,
                onTogglePlayback: () {},
                onShuffle: () {},
                onToggleFavorite: () {},
                onShare: () {},
                onOpenMusicLinks: () {},
                onNextStation: () {},
                onPreviousStation: () {},
                onClose: () {},
                onSleepTimer: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await _matches('player_view', brightness);
      });

      testWidgets('Favoriten-Herz mit Zaehler-Badge', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(220, 80));
        final h = Harness(brightness: brightness);
        addTearDown(h.container.dispose);
        await _seed(h, favorites: 12);
        await tester.pumpWidget(
          h.app(const Center(child: FavoritesHeaderButton())),
        );
        await settle(tester);
        await _matches('favorites_header_button', brightness);
      });

      testWidgets('Einstellungs-Schalter: an, aus, deaktiviert', (
        tester,
      ) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 340));
        await tester.pumpWidget(
          goldenApp(
            brightness: brightness,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  SettingsSwitch(
                    title: 'Lauftext',
                    subtitle: 'Lange Titel laufen durch.',
                    value: true,
                    onChanged: (_) {},
                  ),
                  SettingsSwitch(
                    title: 'Cover laden',
                    subtitle: 'Cover ueber die iTunes-Suche.',
                    value: false,
                    onChanged: (_) {},
                  ),
                  const SettingsSwitch(
                    title: 'Tastenkuerzel',
                    subtitle: 'Nur am Desktop.',
                    value: true,
                    onChanged: null,
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await _matches('settings_switch', brightness);
      });

      testWidgets('Knoepfe: gefuellt, Umriss, Text, deaktiviert', (
        tester,
      ) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 240));
        await tester.pumpWidget(
          goldenApp(
            brightness: brightness,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: <Widget>[
                  Row(
                    spacing: 12,
                    children: <Widget>[
                      FilledButton(onPressed: () {}, child: const Text('Los')),
                      const FilledButton(onPressed: null, child: Text('Aus')),
                    ],
                  ),
                  Row(
                    spacing: 12,
                    children: <Widget>[
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Erlauben'),
                      ),
                      const OutlinedButton(onPressed: null, child: Text('Aus')),
                    ],
                  ),
                  Row(
                    spacing: 12,
                    children: <Widget>[
                      TextButton(onPressed: () {}, child: const Text('Mehr')),
                      const TextButton(onPressed: null, child: Text('Aus')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await _matches('buttons', brightness);
      });

      testWidgets('Abschnittsueberschrift mit Aktion', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, const Size(390, 150));
        await tester.pumpWidget(
          goldenApp(
            brightness: brightness,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SectionHeading(
                'Favoriten',
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Exportieren'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await _matches('section_heading', brightness);
      });

      testWidgets('Dialog: Einwilligung', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, _phone);
        final h = Harness(brightness: brightness);
        addTearDown(h.container.dispose);
        await tester.pumpWidget(h.app(const SizedBox.expand()));
        await tester.pump();
        unawaited(
          showTelemetryConsentDialog(tester.element(find.byType(Scaffold))),
        );
        await settle(tester);
        await _matches('consent_dialog', brightness);
      });

      testWidgets('Sheet: Song oeffnen in', (tester) async {
        ignoreDelegateWarning();
        useGoldenSize(tester, _phone);
        final h = Harness(brightness: brightness);
        addTearDown(h.container.dispose);
        await tester.pumpWidget(h.app(const SizedBox.expand()));
        await tester.pump();
        unawaited(
          showMusicLinksSheet(
            tester.element(find.byType(Scaffold)),
            title: 'Song oeffnen in',
            items: <MusicLinkItem>[
              MusicLinkItem(
                key: 'apple',
                label: 'Apple Music',
                icon: FontAwesomeIcons.apple,
                onOpen: () async {},
              ),
              MusicLinkItem(
                key: 'spotify',
                label: 'Spotify',
                icon: FontAwesomeIcons.spotify,
                onOpen: () async {},
              ),
              MusicLinkItem(
                key: 'youtube',
                label: 'YouTube',
                icon: FontAwesomeIcons.youtube,
                onOpen: () async {},
              ),
            ],
          ),
        );
        await settle(tester);
        await _matches('music_links_sheet', brightness);
      });
    });
  }
}
