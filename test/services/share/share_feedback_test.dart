import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:linefm_radio/services/share/share_feedback.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/feature_host.dart';

void main() {
  setUp(ignoreCupertinoDelegateWarning);

  testWidgets('zeigt Hinweise als SnackBar (de)', (tester) async {
    final controller = StreamController<ShareFeedback>.broadcast();
    addTearDown(controller.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShareFeedbackListener(
          stream: controller.stream,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    controller.add(const ShareFeedback(ShareFeedbackKind.copied));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('In die Zwischenablage kopiert.'), findsOneWidget);

    controller.add(
      const ShareFeedback(ShareFeedbackKind.savedTo, path: '/x/a.csv'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gespeichert unter /x/a.csv'), findsOneWidget);

    controller.add(const ShareFeedback(ShareFeedbackKind.failed));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Teilen hat nicht geklappt.'), findsOneWidget);
  });
}
