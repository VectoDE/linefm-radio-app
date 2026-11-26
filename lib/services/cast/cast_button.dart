import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/features/consent/cast_consent.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/cast/browser_cast.dart';
import 'package:linefm_radio/services/cast/cast_backend.dart';
import 'package:linefm_radio/services/cast/cast_service.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:linefm_radio/ui/widgets/focus_ring.dart';
import 'package:linefm_radio/ui/widgets/named_dialog.dart';
import 'package:linefm_radio/ui/widgets/quiet_tooltip.dart';
import 'package:linefm_radio/ui/widgets/semantic_focus.dart';
import 'package:material_ui/material_ui.dart';

/// Cast-Knopf im Player (Slot aus P13). Erscheint nur, wenn Cast verfügbar
/// ist und Geräte gefunden wurden (oder schon gecastet wird). Auf Web und
/// Desktop liefert der Dienst nie `available`, dort bleibt der Slot leer.
///
/// Die Suche läuft, solange der Knopf im Baum steht, und endet danach (außer
/// bei laufender Übertragung); das schont den Akku.
///
/// Das Google-Cast-SDK startet erst beim ersten Tippen auf den Knopf:
/// Vorher zeigt Android/iOS einen schlichten Cast-Knopf, und es geht keine
/// Anfrage an Google. Erst danach sucht die App nach Geräten.
///
/// Web (Chromium-Browser): Vor dem ersten Laden des Google-Cast-Skripts fragt
/// ein Dialog nach der Einwilligung (web/cast.js). Ohne Zustimmung bleibt es
/// beim schlichten Knopf, und nichts wird von Google geladen. Die Geräteauswahl
/// zeigt danach der Browser selbst.
class CastButton extends ConsumerStatefulWidget {
  const CastButton({super.key});

  @override
  ConsumerState<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends ConsumerState<CastButton> {
  CastService? _service;

  bool _activating = false;

  /// Plattform mit Cast-Unterstützung, SDK aber noch nicht gestartet (und
  /// kein schon gestarteter Dienst, z. B. in Tests übergeben).
  bool get _dormant =>
      castBackend == null &&
      (castPlatformSupported() ||
          ref.read(browserCastBridgeProvider).supported) &&
      !_initialized &&
      ref.read(castServiceProvider) is NoopCastService;

  /// SDK-Start in diesem Knopf schon versucht.
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (_dormant) return;
    _service = ref.read(castServiceProvider);
    unawaited(_service!.startDiscovery());
  }

  /// Erstes Tippen: SDK starten, Dienst neu erzeugen, dann das Sheet.
  Future<void> _activate() async {
    if (_activating) return;
    if (!await _ensureWebConsent()) return;
    if (!mounted) return;
    setState(() => _activating = true);
    try {
      await initCast();
    } on Object catch (e) {
      logError('Cast start failed', e);
    }
    if (!mounted) return;
    _initialized = true;
    ref.invalidate(castServiceProvider);
    _service = ref.read(castServiceProvider);
    setState(() => _activating = false);
    if (castBackend == null) {
      // No SDK (e.g. Android without Google Play services): say why instead
      // of an empty device sheet; the button hides afterwards.
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).castUnavailable)),
      );
      return;
    }
    await _openSheet();
  }

  /// Web: asks for consent before Google's Cast script may load. `true` when
  /// allowed (now or earlier); always `true` outside the web version.
  Future<bool> _ensureWebConsent() async {
    if (!ref.read(browserCastBridgeProvider).supported) return true;
    if (ref.read(castConsentProvider) == true) return true;
    final allowed = await showCastConsentDialog(context);
    if (allowed == null || !mounted) return false;
    ref.read(castConsentProvider.notifier).set(value: allowed);
    return allowed;
  }

  /// Web: the browser shows its own device picker. Tapping the button opens
  /// it right away (fresh user gesture), no sheet in between.
  bool _browserPicker(CastState state) =>
      !state.isCasting &&
      !state.connecting &&
      state.devices.length == 1 &&
      state.devices.first.id == browserPickerDeviceId;

  @override
  void dispose() {
    final service = _service;
    if (service != null && !service.state.isCasting) {
      unawaited(service.stopDiscovery());
    }
    super.dispose();
  }

  Future<void> _openSheet() async {
    final service = ref.read(castServiceProvider);
    unawaited(service.startDiscovery(activeScan: true));
    final colors = context.linefm;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: colors.surface,
      barrierColor: LinefmPalette.scrim,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LinefmMetrics.radiusCover),
        ),
      ),
      builder: (sheetContext) => NamedSheet(
        label: AppLocalizations.of(sheetContext).castButton,
        child: const CastSheet(),
      ),
    );
    // Aktive Suche beenden, passive läuft weiter, solange der Knopf steht.
    if (mounted) unawaited(service.startDiscovery());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_dormant) {
      return _button(
        label: l10n.castButton,
        active: false,
        onTap: _activating ? null : () => unawaited(_activate()),
      );
    }
    final state = ref.watch(castProvider).value;
    if (state == null ||
        !state.available ||
        (state.devices.isEmpty && !state.isCasting && !state.connecting)) {
      return const SizedBox.shrink();
    }
    final active = state.isCasting;
    final label = active
        ? l10n.castConnectedTo(state.connectedDevice!.name)
        : l10n.castButton;
    if (_browserPicker(state)) {
      final service = ref.read(castServiceProvider);
      return _button(
        label: label,
        active: false,
        onTap: () => unawaited(service.connect(state.devices.first)),
      );
    }
    return _button(label: label, active: active, onTap: _openSheet);
  }

  Widget _button({
    required String label,
    required bool active,
    required VoidCallback? onTap,
  }) {
    final colors = context.linefm;
    final station = ref.watch(activeStationProvider);
    final color = StationStyle.onPlayerBody(
      station.color,
      colors,
      Theme.of(context).brightness,
    );
    // QuietTooltip statt Tooltip: keine verwaiste aria-owns-Verknuepfung im
    // Web (siehe QuietTooltip), Label traegt der Knopf selbst.
    return QuietTooltip(
      message: label,
      child: SemanticFocus(
        builder: (_, focused, onFocus, child) => Semantics(
          container: true,
          button: true,
          label: label,
          excludeSemantics: true,
          onTap: onTap,
          focusable: true,
          focused: focused,
          onFocus: onFocus,
          child: child,
        ),
        child: FocusRing(
          shape: BoxShape.circle,
          borderRadius: LinefmMetrics.minTarget / 2,
          child: SizedBox.square(
            dimension: LinefmMetrics.minTarget,
            child: InkResponse(
              onTap: onTap,
              radius: LinefmMetrics.minTarget / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                ),
                child: Center(
                  child: Icon(
                    active ? Icons.cast_connected : Icons.cast,
                    size: 20,
                    color: color,
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

/// Inhalt des Geräte-Sheets: Geräteliste, bei laufender Übertragung das
/// verbundene Gerät mit "Übertragung beenden".
class CastSheet extends ConsumerWidget {
  const CastSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.linefm;
    final theme = Theme.of(context);
    final service = ref.read(castServiceProvider);
    final state = ref.watch(castProvider).value ?? service.state;

    void close() => Navigator.of(context).pop();

    final rows = <Widget>[];
    if (state.isCasting) {
      rows
        ..add(
          _SheetRow(
            icon: Icons.cast_connected,
            label: l10n.castConnectedTo(state.connectedDevice!.name),
          ),
        )
        ..add(
          _SheetRow(
            icon: Icons.close,
            label: l10n.castDisconnect,
            onTap: () {
              close();
              unawaited(service.disconnect());
            },
          ),
        );
    } else if (state.devices.isEmpty) {
      rows.add(
        _SheetRow(
          icon: Icons.search,
          label: state.connecting ? l10n.castSearching : l10n.castNoDevices,
        ),
      );
    } else {
      for (final device in state.devices) {
        rows.add(
          _SheetRow(
            icon: Icons.cast,
            label: device.id == browserPickerDeviceId
                ? l10n.castChooseDevice
                : device.name,
            onTap: () {
              close();
              unawaited(service.connect(device));
            },
          ),
        );
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LinefmSpace.gutter,
          LinefmSpace.md,
          LinefmSpace.gutter,
          LinefmSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(
                      LinefmMetrics.radiusPill,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: LinefmSpace.lg),
            Semantics(
              header: true,
              child: Text(
                l10n.castButton,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: colors.text,
                ),
              ),
            ),
            const SizedBox(height: LinefmSpace.sm),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.linefm;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LinefmSpace.sm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 32,
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: onTap == null ? colors.muted : colors.text,
                ),
              ),
            ),
            const SizedBox(width: LinefmSpace.lg),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: onTap == null ? colors.muted : colors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return SemanticFocus(
      builder: (_, focused, onFocus, child) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        focusable: true,
        focused: focused,
        onFocus: onFocus,
        child: child,
      ),
      child: FocusRing(
        borderRadius: LinefmMetrics.radiusPopover,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LinefmMetrics.radiusPopover),
          child: content,
        ),
      ),
    );
  }
}
