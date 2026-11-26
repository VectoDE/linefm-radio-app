import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/app/stations_provider.dart';
import 'package:linefm_radio/domain/alarm/alarm_rule.dart';
import 'package:linefm_radio/domain/alarm/alarm_schedule.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/features/settings/platform_info.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:linefm_radio/ui/widgets/volume_steps.dart';
import 'package:material_ui/material_ui.dart';

part 'alarm_card.dart';
part 'alarm_notes.dart';

/// Oeffnet den Wecker-Screen (aus den Einstellungen).
Future<void> openAlarm(BuildContext context) => Navigator.of(context)
    .push<void>(MaterialPageRoute<void>(builder: (_) => const AlarmScreen()));

/// Kurzer Wochentag, 1 = Montag.
String weekdayShort(AppLocalizations l10n, int isoWeekday) =>
    switch (isoWeekday) {
      1 => l10n.weekdayShort1,
      2 => l10n.weekdayShort2,
      3 => l10n.weekdayShort3,
      4 => l10n.weekdayShort4,
      5 => l10n.weekdayShort5,
      6 => l10n.weekdayShort6,
      _ => l10n.weekdayShort7,
    };

/// "07:30" fuer heute, sonst "Mo, 07:30" (Uhrzeit nach Geraeteeinstellung).
String formatAlarmTime(
  BuildContext context,
  AppLocalizations l10n,
  DateTime when,
  DateTime now,
) {
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(when),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final sameDay =
      when.year == now.year && when.month == now.month && when.day == now.day;
  return sameDay ? time : '${weekdayShort(l10n, when.weekday)}, $time';
}

/// Zusammenfassung der Wiederholung: Einmalig, Jeden Tag oder "Mo, Mi, Fr".
String alarmRepeatSummary(AppLocalizations l10n, Set<int> weekdays) {
  if (weekdays.isEmpty) return l10n.alarmOnce;
  if (weekdays.length == 7) return l10n.alarmEveryDay;
  final days = weekdays.toList()..sort();
  return days.map((d) => weekdayShort(l10n, d)).join(', ');
}

/// Radiowecker: mehrere Weckzeiten mit Uhrzeit, Wochentagen, Sender,
/// Lautstaerke und festem Schlummern (9 Minuten). Aenderungen gelten sofort
/// und werden an den Wecker-Dienst weitergegeben.
class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  /// Neuer Wecker: zuerst die Uhrzeit waehlen (U2). Abbrechen legt nichts
  /// an; erst danach entsteht der Wecker fuer den aktuellen Sender.
  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      initialEntryMode: timeEntryMode,
      builder: _namedTimePicker,
    );
    if (picked == null || !context.mounted) return;
    final station = ref.read(activeStationProvider);
    final now = ref.read(clockProvider).now();
    final rule = AlarmRule(
      id: '${now.microsecondsSinceEpoch}',
      hour: picked.hour,
      minute: picked.minute,
      stationSlug: station.slug,
      volume: 0.7,
    );
    final rules = ref.read(alarmProvider);
    await ref.read(alarmProvider.notifier).setRules(<AlarmRule>[
      ...rules,
      rule,
    ]);
    if (context.mounted) await _ensurePermission(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final rules = ref.watch(alarmProvider);
    final permission = ref.watch(alarmPermissionStatusProvider);
    final platform = ref.watch(platformInfoProvider);
    final now = ref.watch(clockProvider).now();
    final next = AlarmSchedule.nextOf(rules, now);
    final width = MediaQuery.sizeOf(context).width;
    final side = width > 760 ? (width - 720) / 2 : 20.0;

    final note = platform.isWeb
        ? l10n.alarmNoteWeb
        : platform.isIOS
        ? l10n.alarmNoteIos
        : platform.isDesktop
        ? l10n.alarmNoteDesktop
        : l10n.alarmNoteAndroid;

    // Eigene Seite: als Hauptinhalt kennzeichnen (NEU-2, Landmarke).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.main,
      child: Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: EdgeInsets.fromLTRB(side, LinefmSpace.sm, side, 48),
          children: <Widget>[
            SectionHeading(
              l10n.alarmTitle,
              style: TextStyle(
                fontSize: width < 600 ? LinefmType.title : LinefmType.heading,
              ),
            ),
            Text(
              next == null
                  ? l10n.alarmNone
                  : l10n.alarmNext(formatAlarmTime(context, l10n, next, now)),
              style: LinefmText.listTitle.copyWith(color: c.muted),
            ),
            const SizedBox(height: LinefmSpace.lg),
            _Note(text: note),
            if (!permission.exactOk) ...<Widget>[
              const SizedBox(height: LinefmSpace.md),
              _PermissionNote(
                text: l10n.alarmExactMissingNote,
                action: l10n.alarmOpenSettings,
                onAction: () => ref.read(alarmOpenSystemSettingsProvider)(),
              ),
            ],
            if (!permission.fullScreenOk) ...<Widget>[
              const SizedBox(height: LinefmSpace.md),
              _PermissionNote(
                text: l10n.alarmFullScreenMissingNote,
                action: l10n.alarmOpenFullScreenSettings,
                onAction: () => ref.read(alarmOpenFullScreenSettingsProvider)(),
              ),
            ],
            const SizedBox(height: LinefmSpace.gutter),
            for (final rule in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: LinefmSpace.lg),
                child: _AlarmCard(
                  key: ValueKey<String>(rule.id),
                  rule: rule,
                  onChanged: (changed) async {
                    final list = <AlarmRule>[
                      for (final r in ref.read(alarmProvider))
                        r.id == rule.id ? changed : r,
                    ];
                    await ref.read(alarmProvider.notifier).setRules(list);
                    if (changed.enabled && !rule.enabled && context.mounted) {
                      await _ensurePermission(context, ref);
                    }
                  },
                  onDelete: () =>
                      ref.read(alarmProvider.notifier).setRules(<AlarmRule>[
                        for (final r in ref.read(alarmProvider))
                          if (r.id != rule.id) r,
                      ]),
                ),
              ),
            FilledButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.alarmAdd),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eingabeart des Uhrzeit-Dialogs. Im Web nur Texteingabe: Die Ziffernblatt-
/// Ansicht von Flutter legt Stunde und Minute als Schieberegler ohne Namen an
/// (`<input type="range">` nur mit `aria-valuetext`, axe `label`, kritisch);
/// das laesst sich von aussen nicht beschriften. Die Felder der Texteingabe
/// tragen Namen und sind per Tastatur ohnehin schneller. Auf Geraeten bleibt
/// das Ziffernblatt (Bedienung per Touch).
const TimePickerEntryMode timeEntryMode = kIsWeb
    ? TimePickerEntryMode.inputOnly
    : TimePickerEntryMode.dial;

/// Uhrzeit-Dialog mit zugaenglichem Namen (sonst meldet axe
/// `aria-dialog-name`): derselbe Text wie die Ueberschrift im Dialog.
Widget _namedTimePicker(BuildContext context, Widget? child) => NamedDialog(
  // Gleicher Text wie die sichtbare Ueberschrift der jeweiligen Eingabeart.
  label: timeEntryMode == TimePickerEntryMode.dial
      ? MaterialLocalizations.of(context).timePickerDialHelpText
      : MaterialLocalizations.of(context).timePickerInputHelpText,
  child: child!,
);

/// Fragt die Plattform nach der Wecker-Freigabe; fehlt sie, erklaert ein Dialog
/// den Grund und fuehrt in die Systemeinstellungen.
Future<void> _ensurePermission(BuildContext context, WidgetRef ref) async {
  final granted = await ref.read(alarmPermissionCheckProvider)();
  if (granted || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => NamedDialog(
      label: l10n.alarmPermissionTitle,
      child: AlertDialog(
        semanticLabel: l10n.alarmPermissionTitle,
        title: Text(l10n.alarmPermissionTitle),
        content: Text(l10n.alarmPermissionBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.alarmOpenSettings),
          ),
        ],
      ),
    ),
  );
  if (open ?? false) await ref.read(alarmOpenSystemSettingsProvider)();
}
