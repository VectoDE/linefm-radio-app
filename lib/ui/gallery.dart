import 'package:flutter/foundation.dart';
import 'package:linefm_radio/domain/player_ui_state.dart';
import 'package:linefm_radio/domain/station.dart';
import 'package:linefm_radio/domain/stations_catalog.dart';
import 'package:linefm_radio/ui/theme/breakpoints.dart';
import 'package:linefm_radio/ui/theme/contrast.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/theme.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/cover_image.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/marquee_text.dart';
import 'package:linefm_radio/ui/widgets/play_button.dart';
import 'package:linefm_radio/ui/widgets/section_heading.dart';
import 'package:linefm_radio/ui/widgets/settings_switch.dart';
import 'package:linefm_radio/ui/widgets/station_art.dart';
import 'package:linefm_radio/ui/widgets/volume_steps.dart';
import 'package:material_ui/material_ui.dart';

/// Ob die Galerie erreichbar ist (nur Debug-Builds).
bool get galleryAvailable => kDebugMode;

/// Oeffnet die Galerie, sofern [galleryAvailable]. Im Release ein No-Op.
Future<void> openGallery(BuildContext context) async {
  if (!galleryAvailable) return;
  await Navigator.of(context)
      .push<void>(MaterialPageRoute<void>(builder: (_) => const GalleryPage()));
}

/// Zeigt alle gemeinsamen UI-Bausteine im Hell- und Dunkelmodus nebeneinander
/// (Spalten ab 840 dp) bzw. untereinander. Nur zur Abnahme im Debug-Build.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = WindowClass.of(context) == WindowClass.expanded;
    final panels = <Widget>[
      _Panel(brightness: Brightness.dark),
      _Panel(brightness: Brightness.light),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('LINEFM Design-System')),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final p in panels)
                  Expanded(child: SingleChildScrollView(child: p)),
              ],
            )
          : SingleChildScrollView(child: Column(children: panels)),
    );
  }
}

class _Panel extends StatelessWidget {
  _Panel({required this.brightness});

  final Brightness brightness;
  final ValueNotifier<double> _volume = ValueNotifier<double>(0.7);

  @override
  Widget build(BuildContext context) {
    final theme = buildLinefmTheme(brightness);
    final c = brightness == Brightness.dark
        ? LinefmColors.dark
        : LinefmColors.light;
    final content = Theme(
      data: theme,
      child: Builder(
        builder: (context) => ColoredBox(
          color: c.background,
          child: Material(
            type: MaterialType.transparency,
            child: DefaultTextStyle(
              style: LinefmText.listTitle.copyWith(color: c.text),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeading(
                      brightness == Brightness.dark ? 'Dunkel' : 'Hell',
                    ),
                    _Swatches(colors: c),
                    const SizedBox(height: 24),
                    const SectionHeading('Alle Stationen'),
                    for (final s in stationsCatalog) ...<Widget>[
                      _StationCardPreview(station: s, colors: c),
                      const SizedBox(height: 9),
                    ],
                    const SizedBox(height: 24),
                    _Players(colors: c, brightness: brightness),
                    const SizedBox(height: 24),
                    _Controls(colors: c, volume: _volume),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return content;
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.colors});

  final LinefmColors colors;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color, Color)>[
      ('text', colors.text, colors.background),
      ('muted', colors.muted, colors.background),
      ('muted/surface', colors.muted, colors.surface),
      ('ticker', colors.tickerText, colors.surface),
      ('heart', colors.heart, colors.background),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (name, fg, bg) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bg == colors.surface
                  ? colors.surface
                  : colors.surfaceRaised,
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              border: Border.all(color: colors.line),
            ),
            child: Text(
              '$name ${Contrast.ratio(fg, bg).toStringAsFixed(2)}:1',
              style: LinefmText.listMeta.copyWith(color: fg),
            ),
          ),
      ],
    );
  }
}

class _StationCardPreview extends StatelessWidget {
  const _StationCardPreview({required this.station, required this.colors});

  final Station station;
  final LinefmColors colors;

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
          child: Container(
            constraints: const BoxConstraints(minHeight: 78),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              gradient: StationStyle.cardGradient(station.color, colors),
              border: Border.all(
                color: StationStyle.border(station.color, colors),
                width: 2,
              ),
            ),
            child: Row(
              children: <Widget>[
                StationArt(station: station, size: 48),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        station.displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LinefmText.stationName().copyWith(
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 7),
                      MarqueeText(
                        'Beispielkuenstler - Ein sehr langer Songtitel zum Testen des Lauftexts',
                        style: LinefmText.ticker.copyWith(
                          color: colors.tickerText,
                        ),
                      ),
                    ],
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

class _Players extends StatelessWidget {
  const _Players({required this.colors, required this.brightness});

  final LinefmColors colors;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (final s in stationsCatalog)
          Container(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LinefmMetrics.radiusCard),
              gradient: StationStyle.playerGradient(
                s.color,
                colors,
                brightness,
              ),
            ),
            child: Column(
              children: <Widget>[
                CoverImage(
                  station: s,
                  size: 110,
                  borderRadius: LinefmMetrics.radiusCoverCompact,
                  shadow: true,
                ),
                const SizedBox(height: 10),
                Text(
                  s.displayName,
                  textAlign: TextAlign.center,
                  style: LinefmText.stationName(grid: true).copyWith(
                    color: StationStyle.onPlayerBody(
                      s.color,
                      colors,
                      brightness,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.colors, required this.volume});

  final LinefmColors colors;
  final ValueNotifier<double> volume;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: <Widget>[
            PlayButton(status: PlayerStatus.idle, onPressed: () {}),
            const PlayButton(status: PlayerStatus.connecting, onPressed: null),
            PlayButton(status: PlayerStatus.playing, onPressed: () {}),
            PlayButton(status: PlayerStatus.idle, size: 56, onPressed: () {}),
          ],
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<double>(
          valueListenable: volume,
          builder: (context, v, _) => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 24,
            children: <Widget>[
              VolumeSteps(volume: v, onChanged: (n) => volume.value = n),
              VolumeSteps(
                volume: v,
                axis: Axis.horizontal,
                onChanged: (n) => volume.value = n,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SwitchDemo(),
        const SizedBox(height: 12),
        const SettingsSwitch(
          title: 'Deaktiviert',
          subtitle: 'Zeile ohne Callback.',
          value: true,
          onChanged: null,
          showDivider: false,
        ),
      ],
    );
  }
}

class _SwitchDemo extends StatefulWidget {
  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _a = true;
  bool _b = false;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      SettingsSwitch(
        title: 'Lauftext fuer lange Titel',
        subtitle: 'Lange Songtitel als Band anzeigen.',
        value: _a,
        onChanged: (v) => setState(() => _a = v),
      ),
      SettingsSwitch(
        title: 'Lautstaerke merken',
        subtitle: 'Die gewaehlte Lautstaerke auf diesem Geraet behalten.',
        value: _b,
        onChanged: (v) => setState(() => _b = v),
      ),
    ],
  );
}
