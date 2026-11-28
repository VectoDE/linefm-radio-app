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
import 'package:linefm_radio/features/storage_notice/storage_notice_dialog.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/page_insets.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Height of the mini player including the gap above it (web: 90 + 12).
const double _miniReserve = 102;

/// App frame like the web app (spec 4.1, 4.3):
///
/// - Compact/medium (< 840 dp): header with word mark, favorites heart and
///   gear (without background on the player), content, storage notice at the
///   bottom, mini player and navigation STATIONS/PLAYER/HISTORY.
/// - Wide (from 840 dp): navigation rail on the left (stations, history,
///   favorites; settings via the gear in the header), content, fixed player
///   column on the right (380-460 dp). No mini player, no player tab.
///
/// Also: lifecycle hooks into the live-data engine, startup (volume, link,
/// autoplay), `screen_*` events for stations, player and settings (history
/// and favorites report themselves), notices on reconnect and stream
/// errors, offline bar, keyboard shortcuts (spec 4.6), Back returns to the
/// stations.
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
    // Subscribe permanently: a provider that is only read is paused in
    // Riverpod 3, so title updates to the notification/widget would stop.
    final controller = ref
        .listenManual(playerControllerProvider, (_, _) {})
        .read();
    ref
      ..listenManual(nowPlayingRepositoryProvider, (_, _) {})
      // Subscribe to the cast service permanently: keeps the local/cast handover
      // active even without an open player. The SDK itself only starts on the
      // first tap on the cast button (initCast).
      ..listenManual(castServiceProvider, (_, _) {})
      // Favorite stations for the car menu, also after "Clear storage".
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
    // Native apps on first start: playback waits for "Got it" in the storage
    // notice instead of starting behind the open popup. Later starts (notice
    // already confirmed) play at once.
    final noticeConfirmed = Completer<void>();
    void checkNotice(bool confirmed) {
      final pending = shouldShowStorageNoticeDialog(
        platform: ref.read(platformInfoProvider),
        confirmed: confirmed,
      );
      if (!pending && !noticeConfirmed.isCompleted) noticeConfirmed.complete();
    }

    checkNotice(ref.read(storageConsentProvider));
    if (!noticeConfirmed.isCompleted) {
      ref.listenManual<bool>(
        storageConsentProvider,
        (_, confirmed) => checkNotice(confirmed),
      );
    }
    unawaited(
      controller.startup(
        launchUri: kIsWeb ? Uri.base : null,
        web: kIsWeb,
        untilForeground: Future.wait<void>(<Future<void>>[
          _foreground.future,
          noticeConfirmed.future,
        ]),
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
        // Alarm, About, Legal: own route, the shell stays on the last
        // area.
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
    // History and favorites send `screen_*` themselves.
    if (screen == AppScreen.history || screen == AppScreen.favorites) return;
    unawaited(ref.read(telemetryProvider).screen(screen.telemetryName));
  }

  Future<void> _openRoute(AppScreen screen) => switch (screen) {
    AppScreen.alarm => openAlarm(context),
    AppScreen.about => openAbout(context),
    AppScreen.legal => openLegal(context, LegalKind.privacy),
    _ => Future<void>.value(),
  };

  /// SnackBar on reconnect and error while the player is not
  /// visible (the player shows the state itself).
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

  // ---------------------------------------------------------- Keyboard

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
      // Space and arrows only if no control has focus
      // (otherwise they activate or move the focus as usual).
      if (key == LogicalKeyboardKey.space && ownFocus) {
        unawaited(actions.togglePlayback());
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.escape) {
        return ref.read(navigationProvider.notifier).back()
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      }
      // Single-character shortcuts (F, S, 1-6) can be switched off in the
      // settings (WCAG 2.1.4).
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

  // -------------------------------------------------------------- Layout

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

/// One area of the shell with a fixed tab and screen reader position.
///
/// Each area is its own [FocusTraversalGroup]: Tab runs through the whole
/// area first, then to the next one. Without this order Flutter sorts by
/// position on screen; in the compact layout cards sit behind the mini
/// player and navigation, and the focus used to jump back and forth
/// between them.
///
/// [role] and [label] turn the area into a landmark (main, navigation,
/// complementary, region) so screen readers can jump straight to it and
/// all content lies inside a landmark (axe `region`).
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

/// Area for notices (offline, storage, autoplay). A landmark only while a
/// notice is actually shown; otherwise there would be an empty region.
class _NoticesRegion extends ConsumerWidget {
  const _NoticesRegion({required this.compact, required this.child});

  /// Compact layout: the autoplay bar takes the mini player's space and lets
  /// the storage notice wait (see [_StorageNoticeSlot]).
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

/// Content of a shell area (without the player).
Widget _content(AppScreen screen, {required EdgeInsets stationsPadding}) =>
    switch (screen) {
      AppScreen.history => const HistoryScreen(),
      AppScreen.favorites => const FavoritesScreen(),
      AppScreen.settings => const SettingsScreen(),
      _ => StationsScreen(padding: stationsPadding),
    };

// ------------------------------------------------------------ Compact

class _CompactLayout extends StatefulWidget {
  const _CompactLayout({required this.screen});

  final AppScreen screen;

  @override
  State<_CompactLayout> createState() => _CompactLayoutState();
}

class _CompactLayoutState extends State<_CompactLayout> {
  /// Measured height of the bottom stack (notices, mini player,
  /// navigation). The content keeps that much space free so that, for
  /// example, the storage notice does not cover player buttons.
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
        stationsPadding: EdgeInsets.fromLTRB(
          PageInsets.compact,
          LinefmSpace.gutter,
          PageInsets.compact,
          bottom,
        ),
      );
      content = Padding(
        padding: EdgeInsets.only(top: top),
        // Settings have no placeholder of their own at the bottom.
        child: screen == AppScreen.settings
            ? Padding(
                padding: EdgeInsets.only(bottom: bottom - 24),
                child: inner,
              )
            : inner,
      );
    }

    // Order for Tab and screen readers: header, content, notices,
    // mini player, navigation. No wrap-around: after the navigation Tab
    // leaves the app as usual.
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
                          // Phone: only one notice at a time. While the start bar
                          // is shown, the storage notice waits so that content stays
                          // visible at 320 x 640.
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

/// Reports the size of the child after each layout when it changes.
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

// --------------------------------------------------------------- Wide

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

    // Tab and screen reader order like the visuals: navigation, header,
    // content, notices, player. Without a fixed order the header came
    // only after the cards.
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
                  // The first destination sits on the center line of the header, the
                  // word mark stays in the header.
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
                          PageInsets.expanded,
                          LinefmSpace.gutter,
                          PageInsets.expanded,
                          LinefmSpace.xxl,
                        ),
                      ),
                    ),
                  ),
                  // In the flow below the content instead of an overlay: covers
                  // nothing and does not lie over the whole app.
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
    // Fixed width: long words (e.g. "EINSTELLUNGEN") are shrunk
    // instead of widening the bar or being cut off. The screen reader
    // always reads the full text.
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

/// Header of the web app: word mark "LINEFM" (Syncopate 2rem) on the left,
/// on the right favorites heart with counter and gear. On the player without
/// background and with a text color chosen by contrast to the station gradient.
class _Header extends ConsumerWidget {
  const _Header({required this.transparent, this.inset = true});

  final bool transparent;

  /// Take the status bar into account (compact layout, header above content).
  final bool inset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final top = inset ? MediaQuery.paddingOf(context).top : 0.0;
    final gutter = PageInsets.gutter(context);
    final gearEnd = math.max(
      0.0,
      gutter - (LinefmMetrics.minTarget - LinefmMetrics.navIcon) / 2,
    );
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
      // Same left edge as the page content; the gear glyph ends on the
      // content's right edge (its 48 dp target overhangs into the margin).
      padding: EdgeInsets.fromLTRB(gutter, top, gearEnd, 0),
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

/// Bottom navigation: STATIONS (play) · PLAYER (headphones) · HISTORY
/// (clock-rotate-left) · FAVORITES (heart). Same destinations and order as
/// the side rail, plus the player, which is always visible when wide. The
/// settings sit in the header at every width.
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
    // Landmark and name are set by the shell (_ordered).
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
          // Narrow margin: four destinations fit from 360 dp without a shrunken
          // label.
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

/// Bottom navigation entry: pill indicator behind the icon like in the
/// side rail, hover surface and visible focus ring (2 dp, accent).
/// Fixed height: the label is shrunk, never wrapped, so the
/// bar stays the same height in every language.
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

  /// Name for the screen reader (with the count for favorites).
  final String label;

  /// Visible label.
  final String text;

  /// Counter on the icon, 0 hides it.
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
        // excludeSemantics also discards the InkResponse's tap action; without
        // its own onTap the bar could not be operated with a screen reader
        // (web: click on the button had no effect, found with tool/a11y).
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
            // Focus is shown by the ring, not by a surface.
            focusColor: Colors.transparent,
            // Full cell width: tap target, hover and ring do not depend
            // on the length of the label.
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
                  // Shrink instead of hiding if a language is longer
                  // than the fixed space.
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

// ------------------------------------------------------- Notice bars

/// Storage notice banner (web only) at the bottom above mini player and
/// navigation (16 dp margin, max. 760 dp wide).
class _StorageNoticeSlot extends ConsumerWidget {
  const _StorageNoticeSlot({this.yieldToAutoplay = false});

  /// Hide while the autoplay bar is shown (compact layout).
  final bool yieldToAutoplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmed = ref.watch(storageConsentProvider);
    // Banner only in the browser; app and desktop show a popup (gate).
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

/// Compact layout: in the mini player's place the start bar is shown when
/// autoplay is blocked. That way it covers no card and the content
/// stays visible even at 320 x 640.
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

/// Web autoplay block (spec 2.2): a start without a prior user action
/// (autoplay, alarm, link) would have stayed silent. The bar explains this
/// and starts the chosen station with the click as the user action.
///
/// Only the hint text is a live region; the button is its own regular
/// button without an enclosing semantics node.
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

/// "No connection. LINEFM keeps trying." (spec 4.2 no. 14).
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

/// Navigation icon with an optional counter (favorites), from 100 "99+".
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
