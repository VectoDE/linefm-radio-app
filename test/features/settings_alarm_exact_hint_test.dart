import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/features/alarm/alarm_bootstrap.dart';
import 'package:linefm_radio/features/alarm/alarm_hooks.dart';
import 'package:linefm_radio/features/alarm/alarm_screen.dart';
import 'package:linefm_radio/l10n/gen/app_localizations_de.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';
import 'settings_alarm_helpers.dart';

void main() {
  final l10n = AppLocalizationsDe();

  testWidgets('exact-alarm hint disappears on return to the app', (
    tester,
  ) async {
    useSize(tester, 420, 2600);
    var exact = false;
    final host = FeatureHost(
      noopAlarm: false,

      extra: <Override>[
        alarmCoordinatorProvider.overrideWithValue(RecordingAlarms()),
        alarmStatusCheckProvider.overrideWithValue(
          () async => AlarmPermissionStatus(exactOk: exact),
        ),
      ],
    );
    await tester.pumpWidget(
      host.app(const AlarmBootstrap(child: AlarmScreen()), scaffold: false),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.alarmExactMissingNote), findsOneWidget);

    // Permission granted in the system settings while the app was away.
    exact = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.alarmExactMissingNote), findsNothing);
  });
}
