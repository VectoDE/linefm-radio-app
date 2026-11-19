import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/platform/web_history.dart';
import 'package:material_ui/material_ui.dart';

/// Benannte Web-Routen: jeder Bereich hat eine feste Adresse, die man
/// teilen und neu laden kann (`/history`, `/favorites`, ...). Die Stationsliste
/// liegt auf `/`. Das Hosting liefert fuer alle Pfade ohne Dateiendung die
/// `index.html` (nginx `try_files`, Cloudflare `_redirects`).
class WebRoutes {
  const WebRoutes._();

  static const Map<AppScreen, String> paths = <AppScreen, String>{
    AppScreen.stations: '/',
    AppScreen.player: '/player',
    AppScreen.history: '/history',
    AppScreen.favorites: '/favorites',
    AppScreen.settings: '/settings',
    AppScreen.alarm: '/alarm',
    AppScreen.about: '/about',
    AppScreen.legal: '/legal',
  };

  /// Pfad eines Bereichs (`/` fuer die Stationsliste).
  static String pathFor(AppScreen screen) => paths[screen]!;

  /// Bereich zu einem Pfad, `null` bei unbekanntem Pfad. Gross-/Kleinschreibung
  /// und ein Schraegstrich am Ende zaehlen nicht.
  static AppScreen? screenFor(String path) {
    var p = path.toLowerCase();
    if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
    if (p.isEmpty) p = '/';
    for (final entry in paths.entries) {
      if (entry.value == p) return entry.key;
    }
    return null;
  }
}

/// Haelt Adressleiste und Navigation im Web im Gleichlauf: beim Start
/// oeffnet sie den Bereich der Adresse, danach folgt die Adressleiste der
/// Navigation. Ausserhalb des Browsers reicht sie das Kind nur durch.
///
/// Wecker, Ueber und Recht oeffnet die Shell als eigene Seite und springt
/// sofort zum vorherigen Bereich zurueck; die Adresse zeigt dann den
/// Bereich dahinter. Bereichswechsel legen per `pushState` Verlaufseintraege
/// an, die Zurueck-Taste des Browsers wechselt entsprechend zurueck.
class WebRouteSync extends ConsumerStatefulWidget {
  const WebRouteSync({
    super.key,
    required this.child,
    this.initialUri,
    this.enabled = kIsWeb,
  });

  final Widget child;

  /// Start-Adresse; Standard ist die Adresse des Tabs.
  final Uri? initialUri;

  /// Nur im Web aktiv (Tests duerfen es einschalten).
  final bool enabled;

  @override
  ConsumerState<WebRouteSync> createState() => _WebRouteSyncState();
}

class _WebRouteSyncState extends ConsumerState<WebRouteSync> {
  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    final uri = widget.initialUri ?? currentBrowserUri();
    final target = uri == null ? null : WebRoutes.screenFor(uri.path);
    if (target != null && target != AppScreen.stations) {
      // Nach dem ersten Frame, damit die Shell ihre Navigation schon
      // beobachtet (Wecker/Ueber/Recht oeffnet sie dort als Seite).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(navigationProvider.notifier).go(target);
      });
    }
    ref.listenManual<AppScreen>(navigationProvider, (previous, next) {
      if (!next.isShellScreen) return;
      final path = WebRoutes.pathFor(next);
      // Bereichswechsel = neuer Verlaufseintrag (Zurueck-Taste); der erste
      // Eintrag nach dem Start und Rueckspruenge ersetzen nur.
      final push = !_fromPop && previous != null && previous != next;
      _fromPop = false;
      setBrowserPath(path, query: currentBrowserUri()?.query, push: push);
    });
    _unlisten = listenBrowserPop((path) {
      final screen = WebRoutes.screenFor(path);
      if (screen == null || !mounted) return;
      if (ref.read(navigationProvider) == screen) return;
      _fromPop = true;
      ref.read(navigationProvider.notifier).go(screen);
    });
  }

  bool _fromPop = false;
  void Function()? _unlisten;

  @override
  void dispose() {
    _unlisten?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
