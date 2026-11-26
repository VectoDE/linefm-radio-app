part of 'alarm_screen.dart';

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
      initialEntryMode: timeEntryMode,
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
        padding: const EdgeInsets.fromLTRB(
          LinefmSpace.lg,
          LinefmSpace.md,
          LinefmSpace.sm,
          LinefmSpace.md,
        ),
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
                            style: LinefmText.playerTitle(600).copyWith(
                              color: timeColor,
                              fontSize: LinefmType.display,
                            ),
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
              padding: const EdgeInsets.only(right: LinefmSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alarmRepeatSummary(l10n, rule.weekdays),
                    style: LinefmText.settingCopy.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: LinefmSpace.sm),
                  _DayChips(
                    selected: rule.weekdays,
                    onChanged: (d) => onChanged(rule.copyWith(weekdays: d)),
                  ),
                  const SizedBox(height: LinefmSpace.lg),
                  _StationPicker(
                    slug: rule.stationSlug,
                    onChanged: (s) => onChanged(rule.copyWith(stationSlug: s)),
                  ),
                  const SizedBox(height: LinefmSpace.md),
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
                  const SizedBox(height: LinefmSpace.sm),
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
        spacing: LinefmSpace.sm,
        runSpacing: LinefmSpace.sm,
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

class _StationPicker extends ConsumerWidget {
  const _StationPicker({required this.slug, required this.onChanged});

  final String slug;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final stations = ref.watch(stationsCatalogProvider);
    // Sender entfernt oder ausgeblendet: Auswahl zeigt den
    // Ersatz, den der Wecker spielt, und ein Hinweis sagt es offen.
    final fallback = alarmStationFor(slug);
    final unavailable = fallback.slug != slug;
    final picker = _LabeledRow(
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
                padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.md),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: fallback.slug,
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
                      for (final s in stations)
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
    if (!unavailable) return picker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        picker,
        const SizedBox(height: 6),
        Text(
          l10n.alarmStationUnavailable(fallback.displayName),
          style: LinefmText.listMeta.copyWith(color: c.muted),
        ),
      ],
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
      spacing: LinefmSpace.lg,
      runSpacing: LinefmSpace.sm,
      children: <Widget>[
        Text(label, style: LinefmText.settingTitle.copyWith(color: c.text)),
        child,
      ],
    );
  }
}
