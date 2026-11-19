import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/logging.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/ui/theme/station_style.dart';
import 'package:linefm_radio/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Kanal zur nativen Seite (iOS/macOS). Antwortet `isAvailable` mit `true`,
/// wenn die Platform View [airPlayViewType] registriert ist.
const MethodChannel airPlayChannel = MethodChannel('de.linefm.app/airplay');

/// Typ der Platform View mit `AVRoutePickerView`.
const String airPlayViewType = 'de.linefm.app/airplay_route_picker';

bool get _isApple =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Fragt die native Seite, ob der Picker bereitsteht. Fehlt die native
/// Umsetzung (`MissingPluginException`), bleibt der Knopf ausgeblendet statt
/// eine nicht registrierte Platform View anzulegen.
Future<bool> airPlayAvailable([MethodChannel channel = airPlayChannel]) async {
  if (!_isApple) return false;
  try {
    return await channel.invokeMethod<bool>('isAvailable') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException catch (e) {
    logError('AirPlay nicht verfügbar', e);
    return false;
  }
}

/// AirPlay-Knopf (AVRoutePickerView als Platform View, iOS/macOS). Auf allen
/// anderen Plattformen und ohne native Umsetzung leer.
class AirPlayButton extends ConsumerStatefulWidget {
  const AirPlayButton({super.key});

  @override
  ConsumerState<AirPlayButton> createState() => _AirPlayButtonState();
}

class _AirPlayButtonState extends ConsumerState<AirPlayButton> {
  late final Future<bool> _available = airPlayAvailable();

  @override
  Widget build(BuildContext context) {
    if (!_isApple) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: _available,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        final colors = context.linefm;
        final station = ref.watch(activeStationProvider);
        final color = StationStyle.onPlayerBody(
          station.color,
          colors,
          Theme.of(context).brightness,
        );
        final label = AppLocalizations.of(context).airplayButton;
        const size = LinefmMetrics.minTarget;
        final params = <String, Object?>{
          'tintColor': color.toARGB32(),
          'activeTintColor': colors.accent.toARGB32(),
        };
        return Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.32)),
              ),
              child: ClipOval(
                child: defaultTargetPlatform == TargetPlatform.iOS
                    ? UiKitView(
                        viewType: airPlayViewType,
                        creationParams: params,
                        creationParamsCodec: const StandardMessageCodec(),
                      )
                    : AppKitView(
                        viewType: airPlayViewType,
                        creationParams: params,
                        creationParamsCodec: const StandardMessageCodec(),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
