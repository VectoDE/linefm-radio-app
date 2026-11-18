import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// App-Rahmen. Platzhalter mit Navigation und Senderliste, ausgebaut in P11.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final screen = ref.watch(navigationProvider);
    final index = switch (screen) {
      AppScreen.player => 1,
      AppScreen.history => 2,
      _ => 0,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(
            fontFamily: LinefmFonts.brand,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        children: <Widget>[
          for (final station in stationsCatalog)
            ListTile(
              leading: Image.asset(
                station.logoAsset,
                width: 48,
                height: 48,
                excludeFromSemantics: true,
              ),
              title: Text(station.displayName),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref
            .read(navigationProvider.notifier)
            .go(
              const <AppScreen>[
                AppScreen.stations,
                AppScreen.player,
                AppScreen.history,
              ][i],
            ),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.play_arrow),
            label: l10n.navStations,
          ),
          NavigationDestination(
            icon: const Icon(Icons.headphones),
            label: l10n.navPlayer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l10n.navHistory,
          ),
        ],
      ),
    );
  }
}
