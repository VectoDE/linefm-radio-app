import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/semantics.dart'
    show OrdinalSortKey, SemanticsRole, SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/navigation.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/about/about_screen.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/features/favorites/favorites_screen.dart';
import 'package:linefm_radio/features/history/history_screen.dart';
import 'package:linefm_radio/features/legal/legal_document.dart';
import 'package:linefm_radio/features/legal/legal_screen.dart';
import 'package:linefm_radio/features/mini_player/mini_player.dart';
import 'package:linefm_radio/features/player/player_actions.dart';
import 'package:linefm_radio/features/player/player_screen.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/features/settings/settings_screen.dart';
import 'package:linefm_radio/features/stations/favorite_stations.dart';
import 'package:linefm_radio/features/stations/stations_screen.dart';
import 'package:linefm_radio/features/storage_notice/storage_notice.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Hoehe des Mini-Players samt Abstand darueber (Web: 90 + 12).
const double _miniReserve = 102;

/// App-Rahmen wie die Web-App (Spec 4.1, 4.3):
///
/// - Kompakt/Mittel (< 840 dp): Header mit Wortmarke, Favoriten-Herz und
///   Zahnrad (im Player ohne Hintergrund), Inhalt, unten Speicher-Hinweis,
///   Mini-Player und Navigation STATIONEN/PLAYER/VERLAUF.
/// - Breit (ab 840 dp): Navigation-Rail links (Stationen, Verlauf,
///   Favoriten, Einstellungen), Inhalt, rechts feste Player-Spalte
///   (380-460 dp). Kein Mini-Player, kein Player-Tab.
///
/// Ausserdem: Lebenszyklus an den Live-Daten-Motor, Start (Lautstaerke,
/// Link, Autoplay), `screen_*`-Ereignisse fuer Stationen, Player und
/// Einstellungen (Verlauf und Favoriten melden sich selbst), Hinweise bei
/// Neuverbindung und Stream-Fehler, Offline-Leiste, Tastenkuerzel
/// (Spec 4.6), Zurueck fuehrt zu den Stationen.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;

  /// Completes when the UI first reaches the foreground (autoplay gate).
  final Completer<void> _foreground = Completer<void>();
  final FocusNode _focus = FocusNode(debugLabel: 'shell');
  AppScreen _lastShellScreen = AppScreen.stations;

  @override
  void initState() {
    super.initState();
    // Dauerhaft abonnieren: ein nur gelesener Provider wird in Riverpod 3
    // pausiert, dann liefen Titel-Updates an Benachrichtigung/Widget nicht.
    final controller = ref
        .listenManual(playerControllerProvider, (_, _) {})
        .read();
    ref
      ..listenManual(nowPlayingRepositoryProvider, (_, _) {})
      // Cast-Dienst dauerhaft abonnieren: haelt die Uebergabe lokal/Cast
      // aktiv, auch ohne geoeffneten Player. Das SDK selbst startet erst
      // beim ersten Tippen auf den Cast-Knopf (initCast).
      ..listenManual(castServiceProvider, (_, _) {})
      // Favoriten-Sender fuer das Auto-Menue, auch nach "Speicher loeschen".
      ..listenManual(favoriteStationsProvider, (_, _) {});
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final resumed = state == AppLifecycleState.resumed;
        if (resumed && !_foreground.isCompleted) _foreground.complete();
        ref.read(nowPlayingRepositoryProvider).setForeground(value: resumed);
      },
    );
    // Only Android gates: a headless start by Android Auto never reaches
    // "resumed", so autoplay waits until the user opens the app.
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!android ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _foreground.complete();
    }
    unawaited(
      controller.startup(
        launchUri: kIsWeb ? Uri.base : null,
        web: kIsWeb,
        untilForeground: _foreground.future,
      ),
    );
    _screenEvent(ref.read(navigationProvider));

    ref
      ..listenManual<AppScreen>(navigationProvider, (previous, next) {
        if (next.isShellScreen) {
          _lastShellScreen = next;
          if (previous != next) {
            _screenEvent(next);
            _announceScreen(next);
          }
          return;
        }
        // Wecker, Ueber, Recht: eigene Route, Shell bleibt beim letzten
        // Bereich.
        ref.read(navigationProvider.notifier).go(_lastShellScreen);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_openRoute(next));
        });
      })
      ..listenManual<AsyncValue<PlayerUiState>>(
        playerStateProvider,
        (previous, next) => _onPlayerState(previous?.value, next.value),
      );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Screen readers hear the name of the new area: switching areas keeps the
  /// same route, so nothing else would tell them the page changed.
  void _announceScreen(AppScreen screen) {
    final l10n = AppLocalizations.of(context);
    final name = switch (screen) {
      AppScreen.stations => l10n.navStations,
      AppScreen.player => l10n.navPlayer,
      AppScreen.history => l10n.navHistory,
      AppScreen.favorites => l10n.navFavorites,
      _ => l10n.navSettings,
    };
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        name,
        Directionality.of(context),
      ),
    );
  }

  void _screenEvent(AppScreen screen) {
    // Verlauf und Favoriten senden `screen_*` selbst.
    if (screen == AppScreen.history || screen == AppScreen.favorites) return;
    unawaited(ref.read(telemetryProvider).screen(screen.telemetryName));
  }

  Future<void> _openRoute(AppScreen screen) => switch (screen) {
    AppScreen.alarm => openAlarm(context),
    AppScreen.about => openAbout(context),
    AppScreen.legal => openLegal(context, LegalKind.privacy),
    _ => Future<void>.value(),
  };

  /// SnackBar bei Neuverbindung und Fehler, solange der Player nicht zu
  /// sehen ist (der Player zeigt den Zustand selbst).
  void _onPlayerState(PlayerUiState? previous, PlayerUiState? next) {
    if (next == null || !mounted) return;
    final status = next.status;
    if (status == previous?.status) return;
    final playerVisible =
        ref.read(navigationProvider) == AppScreen.player ||
        WindowClass.of(context) == WindowClass.expanded;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    if (status == PlayerStatus.playing &&
        previous?.status == PlayerStatus.reconnecting) {
      messenger.hideCurrentSnackBar();
      return;
    }
    if (playerVisible) return;
    final bottom =
        MediaQuery.paddingOf(context).bottom +
        LinefmMetrics.navHeight +
        _miniReserve;
    if (status == PlayerStatus.reconnecting) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            content: Text(l10n.playerReconnecting),
          ),
        );
    } else if (status == PlayerStatus.error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            content: Text(l10n.playerStreamError),
            action: SnackBarAction(
              label: l10n.playerRetry,
              onPressed: () => unawaited(
                ref
                    .read(playerControllerProvider)
                    .startStation(ref.read(activeStationProvider)),
              ),
            ),
          ),
        );
    }
  }

  // ---------------------------------------------------------- Tastatur

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    ref.read(playerControllerProvider).onUserInteraction();
    final key = event.logicalKey;
    final keys = HardwareKeyboard.instance;
    final ownFocus = _focus.hasPrimaryFocus;
    final actions = ref.read(playerActionsProvider);
    final controller = ref.read(playerControllerProvider);

    if ((keys.isControlPressed || keys.isMetaPressed) &&
        key == LogicalKeyboardKey.comma) {
      ref.read(navigationProvider.notifier).go(AppScreen.settings);
      return KeyEventResult.handled;
    }
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      // Leertaste und Pfeile nur, wenn kein Bedienelement den Fokus hat
      // (sonst aktivieren bzw. bewegen sie den Fokus wie gewohnt).
      if (key == LogicalKeyboardKey.space && ownFocus) {
        unawaited(actions.togglePlayback());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        return ref.read(navigationProvider.notifier).back()
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      }
      // Ein-Zeichen-Kuerzel (F, S, 1-6) lassen sich in den Einstellungen
      // abschalten (WCAG 2.1.4).
      if (!ref.read(settingsProvider).keyboardShortcuts) {
        return KeyEventResult.ignored;
      }
      if (key == LogicalKeyboardKey.keyF) {
        final track = ref.read(currentTrackProvider).value;
        if (track == null) return KeyEventResult.ignored;
        actions.toggleFavorite(ref.read(activeStationProvider), track);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyS) {
        unawaited(actions.shuffle());
        return KeyEventResult.handled;
      }
      final digit = _digits.indexOf(key);
      if (digit >= 0 && digit < stationsCatalog.length) {
        unawaited(controller.startStation(stationsCatalog[digit]));
        return KeyEventResult.handled;
      }
    }
    if (!ownFocus) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowRight) {
      unawaited(actions.stepStation(1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      unawaited(actions.stepStation(-1));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      final current = ref.read(playbackServiceProvider).state.volume;
      final step = key == LogicalKeyboardKey.arrowUp ? 0.1 : -0.1;
      final next = ((current + step) * 10).round().clamp(1, 10) / 10;
      unawaited(controller.setVolume(next));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static const List<LogicalKeyboardKey> _digits = <LogicalKeyboardKey>[
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];

  // -------------------------------------------------------------- Aufbau

  @override
  Widget build(BuildContext context) {
    final screen = ref.watch(navigationProvider);
    final windowClass = WindowClass.of(context);
    final expanded = windowClass == WindowClass.expanded;

    final body = expanded
        ? _ExpandedLayout(screen: screen)
        : _CompactLayout(screen: screen);

    return PopScope(
      canPop: screen == AppScreen.stations,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(navigationProvider.notifier).back();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) =>
            ref.read(playerControllerProvider).onUserInteraction(),
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Scaffold(
            backgroundColor: context.linefm.background,
            body: body,
          ),
        ),
      ),
    );
  }
}

/// Ein Bereich der Shell mit fester Tab- und Screenreader-Position.
///
/// Jeder Bereich ist eine eigene [FocusTraversalGroup]: Tab laeuft erst
/// durch den ganzen Bereich, dann zum naechsten. Ohne diese Ordnung sortiert
/// Flutter nach Lage auf dem Schirm; im Kompakt-Layout liegen Karten hinter
/// Mini-Player und Navigation, und der Fokus sprang zwischen beiden hin
/// und her.
///
/// [role] und [label] machen den Bereich zur Landmarke (main, navigation,
/// complementary, region), damit Screenreader direkt hinspringen koennen
/// und alle Inhalte in einer Landmarke liegen (axe `region`).
Widget _ordered(
  int order,
  Widget child, {
  SemanticsRole role = SemanticsRole.none,
  String? label,
}) => FocusTraversalOrder(
  order: NumericFocusOrder(order.toDouble()),
  child: FocusTraversalGroup(
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      sortKey: OrdinalSortKey(order.toDouble()),
      role: role,
      label: label,
      child: child,
    ),
  ),
);

/// Bereich fuer Hinweise (Offline, Speicher, Autoplay). Landmarke nur,
/// solange wirklich ein Hinweis steht; sonst gaebe es eine leere Region.
class _NoticesRegion extends ConsumerWidget {
  const _NoticesRegion({required this.compact, required this.child});

  /// Kompakt-Layout: Autoplay-Leiste steht im Mini-Player-Platz und laesst
  /// den Speicher-Hinweis warten (siehe [_StorageNoticeSlot]).
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = !(ref.watch(onlineProvider).value ?? true);
    final blocked = ref.watch(autoplayBlockedProvider);
    final player = ref.watch(navigationProvider) == AppScreen.player;
    final storage =
        ref.watch(platformInfoProvider).isWeb &&
        !ref.watch(storageConsentProvider) &&
        !(compact && blocked && !player);
    final visible = offline || storage || (!compact && blocked);
    if (!visible) return child;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.region,
      label: AppLocalizations.of(context).regionNotices,
      child: child,
    );
  }
}

/// Inhalt eines Bereichs der Shell (ohne Player).
Widget _content(AppScreen screen, {required EdgeInsets stationsPadding}) =>
    switch (screen) {
      AppScreen.history => const HistoryScreen(),
      AppScreen.favorites => const FavoritesScreen(),
      AppScreen.settings => const SettingsScreen(),
      _ => StationsScreen(padding: stationsPadding),
    };

// ------------------------------------------------------------ Kompakt

class _CompactLayout extends StatefulWidget {
  const _CompactLayout({required this.screen});

  final AppScreen screen;

  @override
  State<_CompactLayout> createState() => _CompactLayoutState();
}

class _CompactLayoutState extends State<_CompactLayout> {
  /// Gemessene Hoehe des unteren Stapels (Hinweise, Mini-Player,
  /// Navigation). Der Inhalt haelt so viel Platz frei, damit z. B. der
  /// Speicher-Hinweis keine Player-Knoepfe verdeckt.
  double _bottomStack = 0;

  void _onBottomStack(Size size) {
    if (!mounted || (size.height - _bottomStack).abs() < 0.5) return;
    setState(() => _bottomStack = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final screen = widget.screen;
    final padding = MediaQuery.paddingOf(context);
    final player = screen == AppScreen.player;
    final top = padding.top + LinefmMetrics.headerHeight;
    final bottom = math.max(
      padding.bottom + LinefmMetrics.navHeight + _miniReserve,
      _bottomStack + 12,
    );
    final reduce = MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context);

    final Widget content;
    if (player) {
      content = PlayerScreen(
        embedded: false,
        bottomInset:
            math.max(padding.bottom + LinefmMetrics.navHeight, _bottomStack) +
            24,
      );
    } else {
      final inner = _content(
        screen,
        stationsPadding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
      );
      content = Padding(
        padding: EdgeInsets.only(top: top),
        // Einstellungen haben keinen eigenen Platzhalter unten.
        child: screen == AppScreen.settings
            ? Padding(
                padding: EdgeInsets.only(bottom: bottom - 24),
                child: inner,
              )
            : inner,
      );
    }

    // Reihenfolge fuer Tab und Screenreader: Header, Inhalt, Hinweise,
    // Mini-Player, Navigation. Kein umlaufender Bereich: nach der
    // Navigation verlaesst Tab die App wie gewohnt.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _ordered(
              2,
              role: SemanticsRole.main,
              AnimatedSwitcher(
                duration: reduce ? Duration.zero : LinefmMetrics.fast,
                child: KeyedSubtree(
                  key: ValueKey<AppScreen>(screen),
                  child: content,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ordered(
              1,
              role: SemanticsRole.region,
              label: l10n.regionHeader,
              _Header(transparent: player),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SizeReporter(
              onSize: _onBottomStack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ordered(
                    3,
                    const _NoticesRegion(
                      compact: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _OfflineBanner(),
                          // Handy: nur ein Hinweis zur Zeit. Steht die
                          // Start-Leiste, wartet der Speicher-Hinweis, damit
                          // bei 320 x 640 Inhalt sichtbar bleibt.
                          _StorageNoticeSlot(yieldToAutoplay: true),
                        ],
                      ),
                    ),
                  ),
                  _ordered(
                    4,
                    role: player
                        ? SemanticsRole.none
                        : SemanticsRole.complementary,
                    label: player ? null : l10n.navPlayer,
                    const _MiniPlayerOrStart(),
                  ),
                  SizedBox(height: player ? 0 : 12),
                  _ordered(
                    5,
                    role: SemanticsRole.navigation,
                    label: l10n.navMain,
                    _BottomNav(screen: screen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meldet die Groesse des Kindes nach jedem Layout, wenn sie sich aendert.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}

// --------------------------------------------------------------- Breit

class _ExpandedLayout extends ConsumerWidget {
  const _ExpandedLayout({required this.screen});

  final AppScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final width = MediaQuery.sizeOf(context).width;
    final playerWidth = (width * 0.34).clamp(380.0, 460.0);
    final shown = screen == AppScreen.player ? AppScreen.stations : screen;
    const railScreens = <AppScreen>[
      AppScreen.stations,
      AppScreen.history,
      AppScreen.favorites,
    ];
    final index = railScreens.indexOf(shown);
    final favorites = ref.watch(favoritesProvider.select((f) => f.length));

    // Tab- und Screenreader-Reihenfolge wie die Optik: Navigation, Header,
    // Inhalt, Hinweise, Player. Ohne feste Ordnung kam der Header
    // erst nach den Karten.
    return SafeArea(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ordered(
              1,
              role: SemanticsRole.navigation,
              label: l10n.navMain,
              Semantics(
                container: true,
                explicitChildNodes: true,
                child: SizedBox(
                  key: const ValueKey<String>('shell-rail'),
                  width: LinefmMetrics.railWidth,
                  // Das erste Ziel sitzt auf der Mittellinie des Headers, die
                  // Wortmarke bleibt im Header.
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: LinefmMetrics.railTopInset,
                    ),
                    child: NavigationRail(
                      minWidth: LinefmMetrics.railWidth,
                      selectedIndex: index < 0 ? null : index,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -1,
                      onDestinationSelected: (i) => ref
                          .read(navigationProvider.notifier)
                          .go(railScreens[i]),
                      destinations: <NavigationRailDestination>[
                        _railItem(FontAwesomeIcons.play, l10n.navStations),
                        _railItem(
                          FontAwesomeIcons.clockRotateLeft,
                          l10n.navHistory,
                        ),
                        _railItem(
                          FontAwesomeIcons.heart,
                          l10n.navFavorites,
                          badge: favorites,
                          semanticLabel: favorites > 0
                              ? l10n.favoritesButtonCount(favorites)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: c.line),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ordered(
                    2,
                    role: SemanticsRole.region,
                    label: l10n.regionHeader,
                    const _Header(transparent: false, inset: false),
                  ),
                  Expanded(
                    child: _ordered(
                      3,
                      role: SemanticsRole.main,
                      _content(
                        shown,
                        stationsPadding: const EdgeInsets.fromLTRB(
                          24,
                          20,
                          24,
                          32,
                        ),
                      ),
                    ),
                  ),
                  // Im Fluss unter dem Inhalt statt als Overlay: verdeckt
                  // nichts und liegt nicht ueber der ganzen App.
                  _ordered(
                    4,
                    const _NoticesRegion(
                      compact: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AutoplayStartButton(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          ),
                          _OfflineBanner(),
                          _StorageNoticeSlot(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: playerWidth,
              child: _ordered(
                5,
                role: SemanticsRole.complementary,
                label: l10n.navPlayer,
                const PlayerScreen(embedded: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static NavigationRailDestination _railItem(
    FaIconData icon,
    String label, {
    int badge = 0,
    String? semanticLabel,
  }) => NavigationRailDestination(
    // The counter is part of the spoken name (semanticLabel), not a separate
    // "1" read before the destination.
    icon: ExcludeSemantics(
      child: _NavIcon(icon: icon, badge: badge),
    ),
    // Feste Breite: Lange Woerter (z. B. "EINSTELLUNGEN") werden
    // verkleinert statt die Leiste zu verbreitern oder abgeschnitten zu
    // werden. Der Screenreader liest immer den vollen Text.
    label: Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: SizedBox(
        width: LinefmMetrics.railWidth - 16,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

// -------------------------------------------------------------- Header

/// Header der Web-App: Wortmarke "LINEFM" (Syncopate 2rem) links, rechts
/// Favoriten-Herz mit Zaehler und Zahnrad. Im Player ohne Hintergrund und
/// mit Schriftfarbe nach Kontrast zum Senderverlauf.
class _Header extends ConsumerWidget {
  const _Header({required this.transparent, this.inset = true});

  final bool transparent;

  /// Statusleiste beruecksichtigen (Kompakt-Layout, Header ueber Inhalt).
  final bool inset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final top = inset ? MediaQuery.paddingOf(context).top : 0.0;
    final station = ref.watch(activeStationProvider);
    final onSettings = ref.watch(navigationProvider) == AppScreen.settings;
    final tint = transparent
        ? StationStyle.onPlayerTop(
            station.color,
            c,
            Theme.of(context).brightness,
          )
        : c.text;

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : LinefmMetrics.fast,
      height: top + LinefmMetrics.headerHeight,
      padding: EdgeInsets.fromLTRB(20, top, 12, 0),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : c.background,
        boxShadow: transparent
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: c.headerShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: <Widget>[
          // Takes the space left of the buttons and scales the brand name
          // down instead of overflowing at large text scales.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                header: true,
                headingLevel: 2,
                container: true,
                label: l10n.brandName,
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.brandName,
                      style: LinefmText.brandHeader.copyWith(color: tint),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Favorites live in the navigation; the header keeps only the
          // gear so no destination appears twice.
          QuietTooltip(
            message: l10n.settingsButton,
            child: IconButton(
              onPressed: () {
                final nav = ref.read(navigationProvider.notifier);
                if (ref.read(navigationProvider) == AppScreen.settings) {
                  nav.back();
                } else {
                  nav.go(AppScreen.settings);
                }
              },
              isSelected: onSettings,
              icon: FaIcon(
                FontAwesomeIcons.gear,
                size: LinefmMetrics.navIcon,
                color: onSettings && !transparent ? c.accent : tint,
                semanticLabel: l10n.settingsButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- Navigation

/// Untere Navigation: SENDER (play) · PLAYER (headphones) · VERLAUF
/// (clock-rotate-left) · FAVORITEN (heart). Gleiche Ziele und Reihenfolge wie
/// die Seitenleiste, dazu der Player, der breit immer sichtbar ist. Die
/// Einstellungen liegen auf jeder Breite im Header.
class _BottomNav extends ConsumerWidget {
  const _BottomNav({required this.screen});

  final AppScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final items = <(AppScreen, FaIconData, String)>[
      (AppScreen.stations, FontAwesomeIcons.play, l10n.navStations),
      (AppScreen.player, FontAwesomeIcons.headphones, l10n.navPlayer),
      (AppScreen.history, FontAwesomeIcons.clockRotateLeft, l10n.navHistory),
      (AppScreen.favorites, FontAwesomeIcons.heart, l10n.navFavorites),
    ];
    final favorites = ref.watch(favoritesProvider.select((f) => f.length));
    // Landmarke und Name setzt die Shell (_ordered).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        key: const ValueKey<String>('shell-bottom-nav'),
        decoration: BoxDecoration(
          color: c.navBg,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Padding(
          // Schmaler Rand: Vier Ziele passen ab 360 dp ohne verkleinerte
          // Beschriftung.
          padding: EdgeInsets.fromLTRB(
            LinefmSpace.sm,
            0,
            LinefmSpace.sm,
            bottom,
          ),
          child: SizedBox(
            height: LinefmMetrics.navHeight,
            child: Row(
              children: <Widget>[
                for (final (target, icon, label) in items)
                  Expanded(
                    child: _NavItem(
                      icon: icon,
                      label: target == AppScreen.favorites && favorites > 0
                          ? l10n.favoritesButtonCount(favorites)
                          : label,
                      text: label,
                      badge: target == AppScreen.favorites ? favorites : 0,
                      selected: screen == target,
                      onTap: () =>
                          ref.read(navigationProvider.notifier).go(target),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Eintrag der Bottom-Navigation: Pill-Indikator hinter dem Icon wie in der
/// Seitenleiste, Hover-Flaeche und sichtbarer Fokusring (2 dp, accent).
/// Feste Hoehe: Die Beschriftung wird verkleinert, nie umbrochen, damit die
/// Leiste in jeder Sprache gleich hoch bleibt.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final FaIconData icon;

  /// Name fuer den Screenreader (bei Favoriten mit Anzahl).
  final String label;

  /// Sichtbare Beschriftung.
  final String text;

  /// Zaehler am Icon, 0 blendet ihn aus.
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    final color = selected ? c.accent : c.muted;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        // excludeSemantics verwirft auch die Tap-Aktion des InkResponse; ohne
        // eigenes onTap liess sich die Leiste per Screenreader nicht bedienen
        // (Web: Klick auf den Knopf ohne Wirkung, gefunden mit tool/a11y).
        onTap: onTap,
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LinefmSpace.xs,
          vertical: LinefmSpace.sm,
        ),
        child: FocusRing(
          offset: 0,
          child: InkResponse(
            onTap: onTap,
            containedInkWell: true,
            highlightShape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
            hoverColor: c.accent.withValues(alpha: 0.08),
            // Der Fokus zeigt sich ueber den Ring, nicht ueber eine Flaeche.
            focusColor: Colors.transparent,
            // Volle Zellenbreite: Tippflaeche, Hover und Ring haengen nicht
            // von der Laenge der Beschriftung ab.
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedContainer(
                    key: selected
                        ? const ValueKey<String>('nav-indicator')
                        : null,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : LinefmMetrics.fast,
                    width: LinefmMetrics.navIndicatorWidth,
                    height: LinefmMetrics.navIndicatorHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? c.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        LinefmMetrics.radiusPill,
                      ),
                    ),
                    child: _NavIcon(icon: icon, badge: badge, color: color),
                  ),
                  const SizedBox(height: LinefmSpace.xs),
                  // Verkleinern statt Ausblenden, falls eine Sprache laenger ist
                  // als der feste Platz.
                  // Flexible bounds the height too: at large text scale the
                  // label shrinks instead of overflowing the fixed bar.
                  // The side inset keeps a visible gap between neighbouring
                  // labels even when large system text shrinks them to the
                  // full cell width.
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LinefmSpace.xs,
                      ),
                      child: FittedBox(
                        key: const ValueKey<String>('nav-label'),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text.toUpperCase(),
                          maxLines: 1,
                          softWrap: false,
                          style: LinefmText.nav.copyWith(color: color),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- Hinweisleisten

/// Speicher-Hinweis-Banner (nur Web) unten ueber Mini-Player und Navigation
/// (16 dp Rand, max. 760 dp breit).
class _StorageNoticeSlot extends ConsumerWidget {
  const _StorageNoticeSlot({this.yieldToAutoplay = false});

  /// Ausblenden, solange die Autoplay-Leiste steht (Kompakt-Layout).
  final bool yieldToAutoplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmed = ref.watch(storageConsentProvider);
    // Banner nur im Browser; App und Desktop zeigen ein Popup (Gate).
    if (confirmed || !ref.watch(platformInfoProvider).isWeb) {
      return const SizedBox.shrink();
    }
    if (yieldToAutoplay &&
        ref.watch(autoplayBlockedProvider) &&
        ref.watch(navigationProvider) != AppScreen.player) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: StorageNotice(),
    );
  }
}

/// Kompakt-Layout: Im Platz des Mini-Players steht bei Autoplay-Sperre die
/// Start-Leiste. So ueberdeckt sie keine Karte und der Inhalt
/// bleibt auch bei 320 x 640 sichtbar.
class _MiniPlayerOrStart extends ConsumerWidget {
  const _MiniPlayerOrStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(autoplayBlockedProvider);
    final player = ref.watch(navigationProvider) == AppScreen.player;
    if (blocked && !player) {
      return const AutoplayStartButton(
        padding: EdgeInsets.symmetric(horizontal: 12),
      );
    }
    return const MiniPlayerSlot();
  }
}

/// Web-Autoplay-Sperre (Spec 2.2): Ein Start ohne vorherige Nutzeraktion
/// (Autoplay, Wecker, Link) waere stumm geblieben. Die Leiste erklaert das
/// und startet den gewaehlten Sender mit dem Klick als Nutzeraktion.
///
/// Nur der Hinweistext ist Live-Region; der Knopf ist ein eigener, normaler
/// Knopf ohne umschliessenden Semantik-Knoten.
class AutoplayStartButton extends ConsumerWidget {
  const AutoplayStartButton({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(autoplayBlockedProvider)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final station = ref.watch(activeStationProvider);
    final button = FilledButton.icon(
      key: const ValueKey<String>('autoplay-start'),
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(0, LinefmMetrics.minTarget),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const StadiumBorder(),
        textStyle: LinefmText.listTitle.copyWith(fontWeight: FontWeight.w600),
      ),
      onPressed: () => unawaited(
        ref
            .read(playerControllerProvider)
            .startStation(ref.read(activeStationProvider)),
      ),
      icon: const FaIcon(FontAwesomeIcons.play, size: 16),
      label: Text(l10n.autoplayBlockedStart),
    );
    final hint = Semantics(
      container: true,
      liveRegion: true,
      child: Text(
        l10n.autoplayBlockedHint(station.displayName),
        style: LinefmText.notice.copyWith(color: c.text),
      ),
    );
    // Below 360 dp the button moves under the text, so the hint keeps the
    // full width instead of wrapping into four lines beside the button.
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
            ),
            child: narrow
                ? Padding(
                    padding: const EdgeInsets.all(LinefmSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            LinefmSpace.xs,
                            0,
                            LinefmSpace.xs,
                            LinefmSpace.sm,
                          ),
                          child: hint,
                        ),
                        button,
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: hint),
                        const SizedBox(width: 10),
                        button,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// "Keine Verbindung. LINEFM versucht es weiter." (Spec 4.2 Nr. 14).
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(760, width)),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    FaIcon(FontAwesomeIcons.wifi, size: 13, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.offlineBanner,
                        style: LinefmText.notice.copyWith(color: c.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigations-Icon mit optionalem Zaehler (Favoriten), ab 100 "99+".
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.badge = 0, this.color});

  final FaIconData icon;
  final int badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return Badge(
      isLabelVisible: badge > 0,
      backgroundColor: c.accent,
      textColor: c.onAccent,
      label: Text(badge > 99 ? '99+' : '$badge'),
      child: FaIcon(icon, size: LinefmMetrics.navIcon, color: color),
    );
  }
}
