import 'dart:math' as math;

import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
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
          padding: EdgeInsets.fromLTRB(side, 8, side, 48),
          children: <Widget>[
            SectionHeading(
              l10n.alarmTitle,
              style: TextStyle(fontSize: width < 600 ? 18 : 25),
            ),
            Text(
              next == null
                  ? l10n.alarmNone
                  : l10n.alarmNext(formatAlarmTime(context, l10n, next, now)),
              style: LinefmText.listTitle.copyWith(color: c.muted),
            ),
            const SizedBox(height: 16),
            _Note(text: note),
            if (!permission.exactOk) ...<Widget>[
              const SizedBox(height: 12),
              _PermissionNote(
                text: l10n.alarmExactMissingNote,
                action: l10n.alarmOpenSettings,
                onAction: () => ref.read(alarmOpenSystemSettingsProvider)(),
              ),
            ],
            if (!permission.fullScreenOk) ...<Widget>[
              const SizedBox(height: 12),
              _PermissionNote(
                text: l10n.alarmFullScreenMissingNote,
                action: l10n.alarmOpenFullScreenSettings,
                onAction: () => ref.read(alarmOpenFullScreenSettingsProvider)(),
              ),
            ],
            const SizedBox(height: 20),
            for (final rule in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
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

/// Uhrzeit-Dialog mit zugaenglichem Namen (sonst meldet axe
/// `aria-dialog-name`): derselbe Text wie die Ueberschrift im Dialog.
Widget _namedTimePicker(BuildContext context, Widget? child) => NamedDialog(
  label: MaterialLocalizations.of(context).timePickerDialHelpText,
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

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(Icons.info_outline, size: 18, color: c.muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: LinefmText.settingCopy.copyWith(color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dauerhafter Hinweis auf eine fehlende Systemfreigabe mit Knopf in die
/// passende Systemeinstellung.
class _PermissionNote extends StatelessWidget {
  const _PermissionNote({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.accent),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(text, style: LinefmText.settingCopy.copyWith(color: c.text)),
            const SizedBox(height: 10),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    super.key,
    required this.rule,
    required this.onChanged,
    required this.onDelete,
  });

  final AlarmRule rule;
  final ValueChanged<AlarmRule> onChanged;
  final VoidCallback onDelete;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: rule.hour, minute: rule.minute),
      builder: _namedTimePicker,
    );
    if (picked != null) {
      onChanged(rule.copyWith(hour: picked.hour, minute: picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: rule.hour, minute: rule.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    // Ausgeschaltet: Uhrzeit in `muted` (mind. 4,5:1) statt per Deckkraft
    // gedimmt; der Rest bleibt voll lesbar und bedienbar (A11Y-09).
    final timeColor = rule.enabled ? c.text : c.muted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: SemanticFocus(
                    builder: (_, focused, onFocus, child) => Semantics(
                      container: true,
                      button: true,
                      label: '${l10n.alarmTime}: $time',
                      excludeSemantics: true,
                      onTap: () => _pickTime(context),
                      focusable: true,
                      focused: focused,
                      onFocus: onFocus,
                      child: child,
                    ),
                    child: InkWell(
                      onTap: () => _pickTime(context),
                      borderRadius: BorderRadius.circular(
                        LinefmMetrics.radiusLogo,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: LinefmMetrics.minTarget,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            time,
                            style: LinefmText.playerTitle(600)
                                .copyWith(color: timeColor, fontSize: 30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: l10n.alarmEnabledAt(time),
                  child: Switch(
                    value: rule.enabled,
                    onChanged: (v) => onChanged(rule.copyWith(enabled: v)),
                  ),
                ),
                QuietTooltip(
                  message: l10n.alarmDeleteAt(time),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      semanticLabel: l10n.alarmDeleteAt(time),
                    ),
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alarmRepeatSummary(l10n, rule.weekdays),
                    style: LinefmText.settingCopy.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: 8),
                  _DayChips(
                    selected: rule.weekdays,
                    onChanged: (d) => onChanged(rule.copyWith(weekdays: d)),
                  ),
                  const SizedBox(height: 16),
                  _StationPicker(
                    slug: rule.stationSlug,
                    onChanged: (s) => onChanged(rule.copyWith(stationSlug: s)),
                  ),
                  const SizedBox(height: 12),
                  _LabeledRow(
                    label: l10n.alarmVolume,
                    child: VolumeSteps(
                      axis: Axis.horizontal,
                      volume: rule.volume.clamp(0.1, 1.0),
                      semanticLabel: l10n.alarmVolume,
                      valueLabel: l10n.volumePercent,
                      onChanged: (v) => onChanged(rule.copyWith(volume: v)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.alarmSnooze}: '
                    '${l10n.alarmSnoozeMinutes(AlarmSchedule.snooze.inMinutes)}',
                    style: LinefmText.settingCopy.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sieben Wochentags-Chips. Keine Auswahl = einmalig.
class _DayChips extends StatelessWidget {
  const _DayChips({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    return Semantics(
      container: true,
      label: l10n.alarmDays,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (var d = 1; d <= 7; d++)
            FilterChip(
              label: Text(weekdayShort(l10n, d)),
              selected: selected.contains(d),
              showCheckmark: false,
              labelStyle: LinefmText.listMeta.copyWith(
                color: selected.contains(d) ? c.onAccent : c.text,
              ),
              backgroundColor: Colors.transparent,
              selectedColor: c.accent,
              side: BorderSide(color: c.muted),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onSelected: (on) =>
                  onChanged(<int>{...selected.where((e) => e != d), if (on) d}),
            ),
        ],
      ),
    );
  }
}

class _StationPicker extends StatelessWidget {
  const _StationPicker({required this.slug, required this.onChanged});

  final String slug;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final value = stationBySlug(slug)?.slug ?? stationsCatalog.first.slug;
    return _LabeledRow(
      label: l10n.alarmStation,
      child: LayoutBuilder(
        builder: (context, box) => SizedBox(
          width: math.min(box.maxWidth, 200),
          child: Semantics(
            label: l10n.alarmStation,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    itemHeight: LinefmMetrics.minTarget,
                    dropdownColor: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(
                      LinefmMetrics.radiusPopover,
                    ),
                    iconEnabledColor: c.muted,
                    style: LinefmText.listMeta.copyWith(color: c.text),
                    onChanged: (s) {
                      if (s != null) onChanged(s);
                    },
                    items: <DropdownMenuItem<String>>[
                      for (final s in stationsCatalog)
                        DropdownMenuItem<String>(
                          value: s.slug,
                          child: Text(
                            s.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beschriftung links, Bedienelement rechts; bricht bei wenig Platz oder
/// grosser Schrift um, statt zu ueberlaufen.
class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: <Widget>[
        Text(label, style: LinefmText.settingTitle.copyWith(color: c.text)),
        child,
      ],
    );
  }
}
