import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Einstellungszeile mit Titel, Beschreibung und Schalter wie `.settings-row`
/// der Web-App (Schalter 46x26, Knopf 20, 180 ms).
///
/// Die ganze Zeile ist die Tippflaeche (mindestens 48 dp hoch), per Tastatur
/// mit Leertaste/Enter schaltbar und zeigt bei Tastaturfokus den Fokusring.
/// Screenreader erhalten ein einziges Schalter-Element (Titel + Beschreibung,
/// Zustand an/aus). [onChanged] null deaktiviert die Zeile.
///
/// Der ausgeschaltete Schalter hat einen `muted`-Rahmen, damit er den
/// Mindestkontrast fuer Bedienelemente (3:1, WCAG 1.4.11) erreicht.
class SettingsSwitch extends StatefulWidget {
  const SettingsSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Trennlinie unter der Zeile (`border-bottom` der Web-App).
  final bool showDivider;

  @override
  State<SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<SettingsSwitch> {
  bool _focusRing = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<LinefmColors>()!;
    final enabled = widget.onChanged != null;
    final ring =
        _focusRing &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        toggled: widget.value,
        enabled: enabled,
        label: widget.title,
        hint: widget.subtitle,
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        excludeSemantics: true,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: widget.showDivider
                ? Border(bottom: BorderSide(color: c.line))
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
              onFocusChange: (v) => setState(() => _focusRing = v),
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              focusColor: Colors.transparent,
              child: AnimatedContainer(
                duration: LinefmMetrics.fast,
                constraints: const BoxConstraints(
                  minHeight: LinefmMetrics.minTarget,
                ),
                padding: const EdgeInsets.symmetric(vertical: LinefmSpace.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
                  border: Border.all(
                    color: ring ? c.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.title,
                            style: LinefmText.settingTitle.copyWith(
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: LinefmSpace.xs),
                          Text(
                            widget.subtitle,
                            style: LinefmText.settingCopy.copyWith(
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: LinefmSpace.xl),
                    _Track(value: widget.value, colors: c),
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

class _Track extends StatelessWidget {
  const _Track({required this.value, required this.colors});

  final bool value;
  final LinefmColors colors;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final duration = reduce ? Duration.zero : LinefmMetrics.fast;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(1.5),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? colors.switchTrackOn : colors.switchTrackOff,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusPill),
          border: Border.all(
            color: value ? Colors.transparent : colors.muted,
            width: 1.5,
          ),
        ),
        child: const SizedBox.square(
          dimension: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LinefmPalette.paper,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: LinefmPalette.knobShadow,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
