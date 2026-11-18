import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/favorites/favorites_logic.dart';
import 'package:linefm_radio/domain/history_entry.dart';
import 'package:linefm_radio/features/favorites/favorite_actions.dart';
import 'package:linefm_radio/features/history/history_format.dart';
import 'package:linefm_radio/features/history/icon_action.dart';
import 'package:linefm_radio/features/history/list_screen.dart';
import 'package:linefm_radio/features/history/stagger_in.dart';
import 'package:linefm_radio/features/history/track_row.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Screen "Zuletzt gespielt": LIVE-Eintrag oben, darunter die letzten Titel
/// des aktiven Senders mit Uhrzeit (HH:mm). Je Eintrag ein Herz zum Merken.
/// Pull-to-refresh laedt den Verlauf nach. Meldet `screen_history`.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(telemetryProvider).screen('history'));
  }

  Future<void> _refresh() async {
    await ref.read(nowPlayingRepositoryProvider).refresh();
    ref.invalidate(historyProvider);
    try {
      await ref.read(historyProvider.future);
    } on Object {
      // Fehler zeigt der Zustand des Providers.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(historyProvider);
    final favorites = ref.watch(favoritesProvider);
    final station = ref.watch(activeStationProvider);
    final marquee = ref.watch(settingsProvider.select((s) => s.marquee));
    final entries = history.value ?? const <HistoryEntry>[];

    Widget? stateHint;
    if (entries.isEmpty) {
      if (history.hasError) {
        stateHint = _Message(
          text: l10n.historyEmpty,
          actionLabel: l10n.playerRetry,
          onAction: _refresh,
        );
      } else if (history.isLoading) {
        stateHint = const _Loading();
      } else {
        stateHint = _Message(text: l10n.historyEmpty);
      }
    }

    return ListScreen(
      title: l10n.historyTitle,
      itemCount: entries.length,
      emptyState: stateHint,
      onRefresh: _refresh,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final track = entry.track;
        final favorite = favoriteForTrack(ref, station, track);
        final isFavorite = FavoritesLogic.contains(favorites, favorite.key);
        final time = entry.isLive || track.startedAt == null
            ? null
            : formatClock(track.startedAt!);
        final when = entry.isLive ? l10n.playerLive : time;
        return StaggerIn(
          key: ValueKey<String>('${track.artist}|${track.title}|$index'),
          index: index,
          child: TrackRow(
            station: station,
            title: track.title,
            artist: track.artist,
            coverUrl: track.artworkUrl,
            marquee: marquee,
            semanticLabel: <String>[
              track.title,
              track.artist,
              ?when,
            ].join(', '),
            meta: entry.isLive
                ? _LiveBadge(label: l10n.playerLive)
                : (time == null ? null : _Time(time)),
            trailing: IconAction(
              icon: isFavorite
                  ? FontAwesomeIcons.solidHeart
                  : FontAwesomeIcons.heart,
              label: isFavorite
                  ? l10n.playerFavoriteRemove
                  : l10n.playerFavoriteAdd,
              toggled: isFavorite,
              color: isFavorite ? context.linefm.heart : null,
              hoverColor: context.linefm.heart,
              onPressed: () => toggleFavoriteWithTelemetry(ref, favorite),
            ),
          ),
        );
      },
    );
  }
}

class _Time extends StatelessWidget {
  const _Time(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.end,
      style: LinefmText.time.copyWith(
        color: context.linefm.muted,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

/// "LIVE"-Marke: Punkt in Herzfarbe plus Text auf erhabener Flaeche.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
        border: Border.all(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(color: c.heart, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: LinefmText.time.copyWith(
                color: c.text,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.linefm.muted,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            text,
            style: LinefmText.listTitle.copyWith(color: c.muted, fontSize: 14),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => unawaited(onAction!()),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
