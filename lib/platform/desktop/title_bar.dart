import 'dart:async';

import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/platform/desktop/window_caption.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/theme/typography.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:material_ui/material_ui.dart';

/// Masse der eigenen Titelleiste.
abstract final class TitleBarMetrics {
  /// Windows und Linux: 40 dp. Liegt im 8-dp-Raster (5 x 8), ist genau die
  /// Haelfte des App-Headers (80) und so hoch wie die Leisten von Windows-11-
  /// Apps mit eigener Leiste (Terminal, Edge: 40 bei 100 %). Die
  /// Systemleiste mit 32 wuerde Logo und Wortmarke zu eng setzen.
  static const double height = 40;

  /// macOS: 28 pt, die Hoehe der Systemleiste. Nur so stehen die nativen
  /// Ampeln (vom System platziert) senkrecht mittig in der Leiste.
  static const double heightMacos = 28;

  /// Breite der Schaltflaechen wie unter Windows 11 (46 x Hoehe).
  static const double buttonWidth = 46;

  /// macOS: Platz fuer die Ampeln links (3 x 12 + 2 x 8 Abstand + 20 Rand
  /// + 6 Luft), danach Logo und Name.
  static const double macosTrafficLightInset = 78;

  /// Logo: 20 dp, Radius wie die Senderlogos der App.
  static const double logoSize = 20;

  /// Windows 11: Schliessen-Hover.
  static const Color closeHover = Color(0xFFC42B1C);

  /// Windows 11: Schliessen gedrueckt (90 % Deckkraft).
  static const Color closePressed = Color(0xE6C42B1C);

  /// Vordergrund auf [closeHover] (5,66:1).
  static const Color onClose = Color(0xFFFFFFFF);

  static double heightFor(CaptionStyle style) => switch (style) {
    CaptionStyle.none => 0,
    CaptionStyle.buttons => height,
    CaptionStyle.macos => heightMacos,
  };
}

/// Marken-Asset fuer das Logo: dasselbe Motiv wie das App-Symbol in
/// Taskleiste und Dock (`tool/generate_icons.sh` erzeugt es aus derselben
/// Quelle), daher kein neues Motiv.
const String titleBarLogoAsset = 'assets/images/stations/main.png';

/// Eigene Fenster-Titelleiste der Desktop-App: Logo, Name in der
/// Markenschrift, Farben aus den Tokens (Dunkel und Hell), dieselbe Flaeche
/// wie der Header darunter (`background`, keine Linie dazwischen).
///
/// Windows und Linux: Minimieren, Maximieren/Wiederherstellen, Schliessen
/// rechts. macOS: nur Logo und Name rechts neben den nativen Ampeln.
///
/// Die ganze Leiste ausser den Schaltflaechen zieht das Fenster; Doppelklick
/// und Rechtsklick wie in der Systemleiste ([WindowCaptionControls.dragArea]).
class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({
    super.key,
    required this.controls,
    required this.state,
  });

  final WindowCaptionControls controls;
  final WindowFrameState state;

  @override
  Widget build(BuildContext context) {
    final style = controls.style;
    if (style == CaptionStyle.none || state.fullScreen) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final c = context.linefm;
    final macos = style == CaptionStyle.macos;
    // Inaktives Fenster: Name und Symbole gedaempft wie in der Systemleiste,
    // `muted` haelt dabei AA (5,66:1 dunkel, 6,26:1 hell).
    final primary = state.active ? c.text : c.muted;

    final Widget brand = ExcludeSemantics(
      // Den Fenstertitel liest der Screenreader schon vom System vor.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(LinefmMetrics.radiusLogo),
            child: Opacity(
              opacity: state.active ? 1 : 0.6,
              child: Image.asset(
                titleBarLogoAsset,
                width: TitleBarMetrics.logoSize,
                height: TitleBarMetrics.logoSize,
                // Vorab auf Zielgroesse dekodieren: scharf statt aus 600 px
                // heruntergerechnet, und klein im Speicher.
                cacheWidth:
                    (TitleBarMetrics.logoSize *
                            MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: l10n.brandName),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: l10n.windowTitleProduct.toUpperCase(),
                    style: TextStyle(color: c.muted),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: LinefmText.nav.copyWith(color: primary, height: 1),
            ),
          ),
        ],
      ),
    );

    final Widget dragArea = controls.dragArea(
      SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.only(
            left: macos ? TitleBarMetrics.macosTrafficLightInset : 16,
            right: 16,
          ),
          child: Align(alignment: Alignment.centerLeft, child: brand),
        ),
      ),
    );

    // Die Leiste liegt ueber dem Navigator, also ohne Material darueber:
    // ohne eigenes Material zeichnet Flutter Text mit gelber Warnunterlinie.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: TitleBarMetrics.heightFor(style),
        child: ColoredBox(
          color: c.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: dragArea),
              if (!macos) ...<Widget>[
                CaptionButton(
                  kind: CaptionButtonKind.minimize,
                  label: l10n.windowMinimize,
                  active: state.active,
                  onPressed: () => unawaited(controls.minimize()),
                ),
                controls.maximizeButtonArea(
                  CaptionButton(
                    kind: state.maximized
                        ? CaptionButtonKind.restore
                        : CaptionButtonKind.maximize,
                    label: state.maximized
                        ? l10n.windowRestore
                        : l10n.windowMaximize,
                    active: state.active,
                    onPressed: () => unawaited(controls.toggleMaximize()),
                  ),
                ),
                CaptionButton(
                  kind: CaptionButtonKind.close,
                  label: l10n.windowClose,
                  active: state.active,
                  onPressed: () => unawaited(controls.close()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum CaptionButtonKind { minimize, maximize, restore, close }

/// Schaltflaeche der Titelleiste (46 x 40 wie Windows 11). Zustaende:
/// Normal, Hover (Vordergrund 8 %), Gedrueckt (12 %), Tastaturfokus
/// (Fokusring innen), inaktives Fenster (Symbol `muted`). Schliessen wird
/// bei Hover und Druck rot mit weissem Symbol wie unter Windows.
class CaptionButton extends StatefulWidget {
  const CaptionButton({
    super.key,
    required this.kind,
    required this.label,
    required this.onPressed,
    this.active = true,
  });

  final CaptionButtonKind kind;

  /// Name fuer Screenreader und Hinweisblase (ARB, folgt der App-Sprache).
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  State<CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<CaptionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.linefm;
    final close = widget.kind == CaptionButtonKind.close;
    final base = widget.active ? c.text : c.muted;

    final Color background;
    final Color foreground;
    if (close && (_hovered || _pressed)) {
      background = _pressed
          ? TitleBarMetrics.closePressed
          : TitleBarMetrics.closeHover;
      foreground = TitleBarMetrics.onClose;
    } else if (_pressed) {
      background = c.text.withValues(alpha: 0.12);
      foreground = base;
    } else if (_hovered) {
      background = c.text.withValues(alpha: 0.08);
      foreground = c.text;
    } else {
      background = const Color(0x00000000);
      foreground = base;
    }

    return Semantics(
      container: true,
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: QuietTooltip(
        message: widget.label,
        child: FocusRing(
          // Innen gezeichnet: am oberen Fensterrand waere er sonst
          // abgeschnitten.
          offset: -3,
          borderRadius: 5,
          child: FocusableActionDetector(
            actions: <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed();
                  return null;
                },
              ),
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: Listener(
                onPointerDown: (event) {
                  if (event.buttons == kPrimaryButton) {
                    setState(() => _pressed = true);
                  }
                },
                onPointerUp: (_) => setState(() => _pressed = false),
                onPointerCancel: (_) => setState(() => _pressed = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onPressed,
                  excludeFromSemantics: true,
                  child: SizedBox(
                    width: TitleBarMetrics.buttonWidth,
                    child: ColoredBox(
                      color: background,
                      child: Center(
                        child: CustomPaint(
                          size: const Size.square(10),
                          painter: CaptionGlyphPainter(
                            widget.kind,
                            foreground,
                            MediaQuery.devicePixelRatioOf(context),
                          ),
                        ),
                      ),
                    ),
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

/// Zeichnet die Symbole wie Segoe Fluent (Windows 11): 10 x 10, 1 px Linie,
/// auf Geraetepixel ausgerichtet, damit sie bei 100 % und 150 % scharf
/// bleiben.
class CaptionGlyphPainter extends CustomPainter {
  CaptionGlyphPainter(this.kind, this.color, this.devicePixelRatio);

  final CaptionButtonKind kind;
  final Color color;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    // Eine Linie von ganzen Geraetepixeln, mittig auf einem Pixel.
    final px = 1 / devicePixelRatio;
    final stroke = devicePixelRatio.round().clamp(1, 4) * px;
    final half = stroke / 2;
    double snap(double v) => (v / px).round() * px + half;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    final s = size.width;
    switch (kind) {
      case CaptionButtonKind.minimize:
        final y = snap(s / 2);
        canvas.drawLine(Offset(0, y), Offset(s, y), paint);
      case CaptionButtonKind.maximize:
        canvas.drawRRect(
          RRect.fromLTRBR(
            snap(0),
            snap(0),
            snap(s) - stroke,
            snap(s) - stroke,
            const Radius.circular(1.5),
          ),
          paint,
        );
      case CaptionButtonKind.restore:
        final o = (s * 0.2 / px).round() * px;
        // Vorderes Fenster unten links.
        canvas.drawRRect(
          RRect.fromLTRBR(
            snap(0),
            snap(o),
            snap(s - o) - stroke,
            snap(s) - stroke,
            const Radius.circular(1.5),
          ),
          paint,
        );
        // Hinteres Fenster: nur obere und rechte Kante sichtbar.
        final back = Path()
          ..moveTo(snap(o), snap(o) - stroke)
          ..lineTo(snap(o), snap(1.5))
          ..quadraticBezierTo(snap(o), snap(0), snap(o + 1.5), snap(0))
          ..lineTo(snap(s - 1.5) - stroke, snap(0))
          ..quadraticBezierTo(
            snap(s) - stroke,
            snap(0),
            snap(s) - stroke,
            snap(1.5),
          )
          ..lineTo(snap(s) - stroke, snap(s - o) - stroke)
          ..lineTo(snap(s - o), snap(s - o) - stroke);
        canvas.drawPath(back, paint);
      case CaptionButtonKind.close:
        canvas
          ..drawLine(Offset.zero, Offset(s, s), paint)
          ..drawLine(Offset(s, 0), Offset(0, s), paint);
    }
  }

  @override
  bool shouldRepaint(CaptionGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.devicePixelRatio != devicePixelRatio;
}
