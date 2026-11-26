part of 'settings_screen.dart';

/// Auswahlzeile mit Segmenten (Darstellung, Sprache): Titel als Ueberschrift,
/// optional eine Erklaerung, darunter die Segmente. Der Screenreader meldet
/// je Segment Schaltflaeche und gewaehlten Zustand.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.body,
  });

  final String title;
  final String? body;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              headingLevel: 2,
              container: true,
              child: Text(
                title,
                style: LinefmText.settingTitle.copyWith(color: c.text),
              ),
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: LinefmSpace.xs),
              Text(
                body!,
                style: LinefmText.settingCopy.copyWith(color: c.muted),
              ),
            ],
            const SizedBox(height: LinefmSpace.md),
            LayoutBuilder(
              // Zu schmal fuer drei Segmente nebeneinander (320 dp, grosse
              // Schrift): untereinander statt Buchstabe fuer Buchstabe.
              builder: (context, box) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<T>(
                  direction:
                      box.maxWidth <
                          330 * MediaQuery.textScalerOf(context).scale(1)
                      ? Axis.vertical
                      : Axis.horizontal,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    foregroundColor: c.text,
                    backgroundColor: Colors.transparent,
                    selectedForegroundColor: c.onAccent,
                    selectedBackgroundColor: c.accent,
                    side: BorderSide(color: c.muted),
                    textStyle: LinefmText.listMeta,
                    minimumSize: const Size(0, LinefmMetrics.minTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        LinefmMetrics.radiusLogo,
                      ),
                    ),
                  ),
                  // Der Zustand "ausgewaehlt" steht im Label-Teil, damit er mit
                  // in den Schaltflaechen-Knoten des Screenreaders faellt.
                  segments: <ButtonSegment<T>>[
                    for (final s in segments)
                      ButtonSegment<T>(
                        value: s.value,
                        icon: s.icon,
                        enabled: s.enabled,
                        label: Semantics(
                          selected: s.value == selected,
                          inMutuallyExclusiveGroup: true,
                          child: s.label,
                        ),
                      ),
                  ],
                  selected: <T>{selected},
                  onSelectionChanged: (s) => onChanged(s.first),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zeile "Wecker" mit naechster Weckzeit; oeffnet den Wecker-Screen.
class _AlarmRow extends ConsumerWidget {
  const _AlarmRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rules = ref.watch(alarmProvider);
    final now = ref.watch(clockProvider).now();
    final next = AlarmSchedule.nextOf(rules, now);
    return _NavRow(
      title: l10n.settingAlarmTitle,
      subtitle: next == null
          ? l10n.settingAlarmBodyOff
          : l10n.alarmNext(formatAlarmTime(context, l10n, next, now)),
      onTap: () => openAlarm(context),
    );
  }
}

/// Zeile mit Titel, optionaler Beschreibung und Pfeil.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.title, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: title,
        hint: subtitle,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: LinefmMetrics.minTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: LinefmText.settingTitle.copyWith(
                            color: c.text,
                          ),
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: LinefmSpace.xs),
                          Text(
                            subtitle!,
                            style: LinefmText.settingCopy.copyWith(
                              color: c.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: LinefmSpace.xl),
                  Icon(Icons.chevron_right, color: c.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
