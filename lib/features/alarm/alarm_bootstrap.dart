import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/alarm/alarm_coordinator.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:material_ui/material_ui.dart';

/// Startet den Wecker mit der App und haelt ihn aktuell:
///
/// * liest den Koordinator beim Start einmal (plant alle Termine neu und
///   haengt den Klingel-Listener ein, auch wenn der Wecker-Screen nie
///   geoeffnet wird),
/// * prueft die Systemfreigaben beim Start und bei jeder Rueckkehr in die App
///   (nach den Systemeinstellungen, nach Zeitzonen-/Uhrzeitwechsel) und plant
///   dann alle Termine neu,
/// * zeigt beim Klingeln das Banner mit Schlummern und Aus.
class AlarmBootstrap extends ConsumerStatefulWidget {
  const AlarmBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AlarmBootstrap> createState() => _AlarmBootstrapState();
}

class _AlarmBootstrapState extends ConsumerState<AlarmBootstrap>
    with WidgetsBindingObserver {
  late final AlarmCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _coordinator = ref.read(alarmCoordinatorProvider);
    unawaited(_refresh(reschedule: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh(reschedule: true));
    }
  }

  Future<void> _refresh({required bool reschedule}) async {
    await ref.read(alarmPermissionStatusProvider.notifier).refresh();
    // Zeitzonen-/Uhrzeitwechsel im Hintergrund: der native Empfaenger hat nur
    // ein Merkzeichen gesetzt, hier wird neu geplant.
    final timeChanged = await ref.read(alarmRescheduleFlagProvider)();
    if (!mounted || !(reschedule || timeChanged)) return;
    await _coordinator.rescheduleAll(ref.read(alarmProvider));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Positioned.fill(child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _RingingBanner(coordinator: _coordinator),
        ),
      ],
    );
  }
}

class _RingingBanner extends StatelessWidget {
  const _RingingBanner({required this.coordinator});

  final AlarmCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AlarmRinging?>(
      valueListenable: coordinator.ringing,
      builder: (context, ringing, _) {
        if (ringing == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        final c = context.linefm;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: c.surfaceRaised,
              elevation: 6,
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.alarmRingingBody(ringing.station.displayName),
                        style: LinefmText.listTitle.copyWith(color: c.text),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: <Widget>[
                          FilledButton(
                            onPressed: () => coordinator.snooze(ringing.ruleId),
                            child: Text(l10n.alarmSnooze),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                coordinator.dismiss(ringing.ruleId),
                            child: Text(l10n.alarmDismiss),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
