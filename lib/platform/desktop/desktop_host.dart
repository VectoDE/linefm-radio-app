import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/domain/track.dart';
import 'package:linefm_radio/platform/desktop/desktop_controller.dart';
import 'package:linefm_radio/platform/desktop/mini_window.dart';
import 'package:linefm_radio/platform/desktop/title_bar.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';

/// [DesktopActions] auf Basis der Riverpod-Provider.
class ProviderDesktopActions implements DesktopActions {
  ProviderDesktopActions(this._ref);

  final WidgetRef _ref;

  @override
  bool get isPlaying {
    final state = _ref.read(playbackServiceProvider).state;
    return state.isPlaying || state.isBusy;
  }

  @override
  Station get activeStation => _ref.read(activeStationProvider);

  @override
  Track? get currentTrack => _ref.read(currentTrackProvider).value;

  @override
  double get volume => _ref.read(playbackServiceProvider).state.volume;

  @override
  Future<void> togglePlayback() =>
      _ref.read(playerControllerProvider).togglePlayback();

  @override
  Future<void> startStation(Station station) =>
      _ref.read(playerControllerProvider).startStation(station);

  @override
  Future<void> stepStation(int delta) async {
    final current = activeStation;
    final index = stationsCatalog.indexOf(current);
    final count = stationsCatalog.length;
    final next = stationsCatalog[((index < 0 ? 0 : index) + delta) % count];
    final controller = _ref.read(playerControllerProvider);
    if (isPlaying) {
      await controller.startStation(next);
    } else {
      await controller.selectStation(next);
    }
  }

  @override
  Future<void> changeVolume(double delta) {
    final next = (volume + delta).clamp(0.1, 1.0);
    return _ref.read(playerControllerProvider).setVolume(next);
  }
}

/// Bindet die Desktop-Extras an die App: Wiedergabe-Aktionen fuer Tray und
/// Tastenkuerzel, "Beim Schliessen im Tray weiterlaufen" aus den
/// Einstellungen, Tray-Menue-Aktualisierung und das Mini-Fenster.
///
/// Einbau (P28): `MaterialApp(builder: (context, child) => DesktopHost(child:
/// child ?? const SizedBox.shrink()))`. Auf Web und Mobil reicht der Host
/// das Kind unveraendert durch.
class DesktopHost extends ConsumerStatefulWidget {
  const DesktopHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopHost> createState() => _DesktopHostState();
}

class _DesktopHostState extends ConsumerState<DesktopHost> {
  final DesktopController _desktop = DesktopController.instance;
  Size _normalSize = Size.zero;

  @override
  void initState() {
    super.initState();
    if (!_desktop.active) return;
    _desktop.bindActions(ProviderDesktopActions(ref));
    ref
      ..listenManual<bool>(
        settingsProvider.select((s) => s.closeToTray),
        (_, value) => unawaited(_desktop.window.setCloseToTray(value: value)),
        fireImmediately: true,
      )
      ..listenManual(
        settingsProvider.select((s) => s.language),
        (_, _) => unawaited(_desktop.tray.refresh()),
      )
      ..listenManual(
        playerStateProvider,
        (_, _) => unawaited(_desktop.tray.refresh()),
      )
      ..listenManual(
        activeStationProvider,
        (_, _) => unawaited(_desktop.tray.refresh()),
      )
      ..listenManual(
        currentTrackProvider,
        (_, _) => unawaited(_desktop.tray.refresh()),
      );
  }

  @override
  void dispose() {
    if (_desktop.active) _desktop.bindActions(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_desktop.active) return widget.child;
    return ValueListenableBuilder<bool>(
      valueListenable: _desktop.miniMode,
      builder: (context, mini, _) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Die App bleibt im Mini-Modus erhalten (Navigation, Zustand),
            // wird aber nicht gezeichnet und bekommt ihre letzte normale
            // Groesse, damit das kleine Fenster kein Layout erzwingt.
            Offstage(
              offstage: mini,
              child: TickerMode(
                enabled: !mini,
                child: _framed(
                  mini: mini,
                  app: LayoutBuilder(
                    builder: (context, constraints) {
                      if (!mini) _normalSize = constraints.biggest;
                      final fixed = mini && !_normalSize.isEmpty;
                      return OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: fixed ? _normalSize.width : null,
                        maxWidth: fixed ? _normalSize.width : null,
                        minHeight: fixed ? _normalSize.height : null,
                        maxHeight: fixed ? _normalSize.height : null,
                        child: widget.child,
                      );
                    },
                  ),
                ),
              ),
            ),
            if (mini) const MiniPlayerWindow(),
          ],
        );
      },
    );
  }

  /// Eigene Titelleiste ueber der App (Issue #87). Der Baum um [app] bleibt
  /// in jedem Zustand gleich (Leiste nur ein-/ausgeblendet, Griffe nur
  /// abgeschaltet), damit Navigator und App-Zustand nie neu entstehen.
  ///
  /// Tastatur: Tab bleibt wie bei nativen Titelleisten im Inhalt (der
  /// Navigator haelt den Fokus in seinem Bereich), die Leiste steht also nie
  /// vor dem Hauptinhalt. Fenster-Aktionen per Tastatur laufen wie bisher
  /// ueber das System: Alt+Leertaste (Windows, auch Linux-Fenstermanager),
  /// Win+Pfeil, Alt+F4. Screenreader erreichen die Schaltflaechen ueber ihre
  /// Semantik.
  Widget _framed({required bool mini, required Widget app}) {
    final caption = _desktop.caption;
    if (caption.style == CaptionStyle.none) return app;
    return ValueListenableBuilder<WindowFrameState>(
      valueListenable: caption.frameState,
      builder: (context, state, _) {
        final normal = !state.maximized && !state.fullScreen && !mini;
        return caption.resizeArea(
          enabled: normal,
          // Eigenes Overlay fuer die Hinweisblasen der Leiste (sie liegt
          // ueber dem Navigator der App).
          Overlay.wrap(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DesktopTitleBar(controls: caption, state: state),
                Expanded(child: app),
              ],
            ),
          ),
        );
      },
    );
  }
}
