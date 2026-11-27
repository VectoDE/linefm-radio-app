import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/domain/sleep_timer/sleep_timer_logic.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/sleep_timer/sleep_timer_service.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Status-Text des Sleeptimers (Web-Wortlaut) fuer den Zustand [state] zum
/// Zeitpunkt [now].
String sleepTimerStatusText(
  AppLocalizations l10n,
  SleepTimerState state,
  DateTime now,
) {
  if (!state.isActive) return l10n.sleepTimerStatusNone;
  if (SleepTimerLogic.isExpired(state, now)) return l10n.sleepTimerExpired;
  final left = SleepTimerLogic.remaining(state, now);
  if (left == null || state.mode is SleepTimerEndOfSong) {
    return l10n.sleepTimerStatusEndOfSong;
  }
  final minutes = ((left.inSeconds + 59) ~/ 60).clamp(1, 24 * 60);
  return l10n.sleepTimerStatusRunning(minutes);
}

/// Zeile "Sleeptimer": Beschreibung mit Live-Status und Auswahl Aus / 15 / 30 /
/// 45 / 60 Min. / Ende des Songs.
class SleepTimerRow extends ConsumerStatefulWidget {
  const SleepTimerRow({super.key, this.showDivider = true});

  final bool showDivider;

  @override
  ConsumerState<SleepTimerRow> createState() => _SleepTimerRowState();
}

class _SleepTimerRowState extends ConsumerState<SleepTimerRow> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(sleepTimerProvider).isActive) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _choose(SleepTimerMode mode) async {
    final notifier = ref.read(sleepTimerProvider.notifier);
    if (mode is SleepTimerOff) {
      await notifier.cancel();
    } else {
      await notifier.start(
        mode,
        currentTrack: ref.read(currentTrackProvider).value,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final state = ref.watch(sleepTimerProvider);
    final now = ref.watch(clockProvider).now();
    final expired = SleepTimerLogic.isExpired(state, now);
    final track = ref.watch(currentTrackProvider).value;
    // Live-Sendung: laut.fm kennt das Songende nicht, "Ende des Songs" geht
    // dann nicht.
    final endOfSongOk = sleepTimerEndOfSongAvailable(track, now);
    final status = sleepTimerStatusText(l10n, state, now);

    final presets = <SleepTimerMode>[
      const SleepTimerOff(),
      for (final m in SleepTimerLogic.presetMinutes) SleepTimerMinutes(m),
      const SleepTimerEndOfSong(),
    ];
    final current = expired || !presets.contains(state.mode)
        ? const SleepTimerOff()
        : state.mode;

    String label(SleepTimerMode m) => switch (m) {
      SleepTimerOff() => l10n.sleepTimerOff,
      SleepTimerMinutes(:final minutes) => l10n.sleepTimerMinutes(minutes),
      SleepTimerEndOfSong() => l10n.sleepTimerEndOfSong,
    };

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.sleepTimerTitle,
          style: LinefmText.settingTitle.copyWith(color: c.text),
        ),
        const SizedBox(height: LinefmSpace.xs),
        Semantics(
          liveRegion: true,
          child: Text(
            status,
            style: LinefmText.settingCopy.copyWith(color: c.muted),
          ),
        ),
        if (!endOfSongOk && track != null) ...<Widget>[
          const SizedBox(height: LinefmSpace.xs),
          Text(
            l10n.sleepTimerEndOfSongUnavailable,
            style: LinefmText.settingCopy.copyWith(color: c.muted),
          ),
        ],
      ],
    );

    Widget picker({required bool expand}) => Semantics(
      label: l10n.sleepTimerTitle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SleepTimerMode>(
              value: current,
              isExpanded: expand,
              dropdownColor: c.surfaceRaised,
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusPopover),
              iconEnabledColor: c.muted,
              style: LinefmText.listMeta.copyWith(color: c.text),
              onChanged: (m) {
                if (m != null) unawaited(_choose(m));
              },
              items: <DropdownMenuItem<SleepTimerMode>>[
                for (final m in presets)
                  DropdownMenuItem<SleepTimerMode>(
                    value: m,
                    enabled: m is! SleepTimerEndOfSong || endOfSongOk,
                    child: Text(label(m)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: widget.showDivider
            ? Border(bottom: BorderSide(color: c.line))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
        child: LayoutBuilder(
          builder: (context, box) {
            // Schmal oder grosse Schrift: Auswahl unter den Text.
            final stacked =
                box.maxWidth < 420 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  copy,
                  const SizedBox(height: LinefmSpace.md),
                  picker(expand: true),
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: copy),
                const SizedBox(width: LinefmSpace.xl),
                picker(expand: false),
              ],
            );
          },
        ),
      ),
    );
  }
}
