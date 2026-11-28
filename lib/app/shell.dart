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

part 'shell/autoplay_start_button.dart';
part 'shell/bottom_nav.dart';
part 'shell/compact_layout.dart';
part 'shell/expanded_layout.dart';
part 'shell/header.dart';
part 'shell/landmarks.dart';
part 'shell/mini_player_slot.dart';
part 'shell/notices.dart';

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
