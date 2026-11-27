import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/core/config/app_config.dart';
import 'package:linefm_radio/features/about/about_screen.dart';
import 'package:linefm_radio/features/about/radiogruppe_logo.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:material_ui/material_ui.dart';

import 'feature_host.dart';

/// Credit-Zeile: sichtbarer Text ohne das Herz-Symbol (WidgetSpan).
Finder madeByText() => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      w.textSpan?.toPlainText(includePlaceholders: false) ==
          'Made by Tim Hauke with ',
);

void main() {
  setUp(() => loaderShownThisProcess = false);

  group('Ladebildschirm', () {
    testWidgets('zeigt die Credits im Wortlaut', (tester) async {
      await tester.pumpWidget(
        FeatureHost().app(const AppLoader(), scaffold: false),
      );
      expect(madeByText(), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('LINEFM'), findsOneWidget);
    });

    testWidgets('Kaltstart: Loader steht, dann blendet er aus', (tester) async {
      await tester.pumpWidget(
        FeatureHost().app(
          const LoaderGate(
            minDuration: Duration(milliseconds: 500),
            child: Text('App'),
          ),
          scaffold: false,
        ),
      );
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('App'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(
        LoaderGate.fadeDuration + const Duration(milliseconds: 50),
      );
      expect(find.byType(AppLoader), findsNothing);
      expect(find.text('App'), findsOneWidget);
    });

    testWidgets('Kind ist waehrend des Loaders fuer Bedienung gesperrt', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        FeatureHost().app(
          LoaderGate(
            minDuration: const Duration(milliseconds: 500),
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Tippen'),
              ),
            ),
          ),
          scaffold: false,
        ),
      );
      await tester.tap(find.text('Tippen'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(
        LoaderGate.fadeDuration + const Duration(milliseconds: 50),
      );
      await tester.tap(find.text('Tippen'));
      expect(taps, 1);
    });

    testWidgets('Warmstart im selben Prozess zeigt keinen Loader', (
      tester,
    ) async {
      loaderShownThisProcess = true;
      await tester.pumpWidget(
        FeatureHost().app(
          const LoaderGate(child: Text('App')),
          scaffold: false,
        ),
      );
      expect(find.byType(AppLoader), findsNothing);
      expect(find.text('App'), findsOneWidget);
    });

    test('no fixed minimum time, short fade', () {
      expect(const LoaderGate(child: SizedBox()).minDuration, Duration.zero);
      expect(LoaderGate.fadeDuration, const Duration(milliseconds: 150));
    });

    testWidgets('default gate fades out right after the first frame', (
      tester,
    ) async {
      loaderShownThisProcess = false;
      await tester.pumpWidget(
        FeatureHost().app(
          const LoaderGate(child: Text('App')),
          scaffold: false,
        ),
      );
      expect(find.byType(AppLoader), findsOneWidget);
      await tester.pump();
      await tester.pump(LoaderGate.fadeDuration);
      await tester.pump();
      expect(find.byType(AppLoader), findsNothing);
      expect(
        find.text('App'),
        findsOneWidget,
      ); // The dot animation is gone with the loader: no ticker left when idle.
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('Ueber-Bereich', () {
    setUp(() {});
    testWidgets('Credits deutsch im Wortlaut', (tester) async {
      useSize(tester, 420, 1600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const AboutScreen(), scaffold: false));
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();
      expect(madeByText(), findsOneWidget);
      expect(find.bySemanticsLabel('Made by Tim Hauke with ♥'), findsOneWidget);
      handle.dispose();
      expect(find.text('Ein Angebot von'), findsOneWidget);
      expect(
        find.text('Entwickelt von Tim Hauke (VectoDE) für LineFM Studios'),
        findsOneWidget,
      );
      expect(
        find.text('LINEFM und die App gehören LineFM Studios.'),
        findsOneWidget,
      );
      expect(find.text('Entwicklungsversion (?)'), findsOneWidget);
    });

    testWidgets('Credits englisch im Wortlaut', (tester) async {
      useSize(tester, 420, 1600);
      final host = FeatureHost();
      await tester.pumpWidget(
        host.app(
          const AboutScreen(),
          locale: const Locale('en'),
          scaffold: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(madeByText(), findsOneWidget);
      expect(find.text('A service of'), findsOneWidget);
      expect(
        find.text('Developed by Tim Hauke (VectoDE) for LineFM Studios'),
        findsOneWidget,
      );
      expect(
        find.text('LINEFM and this app belong to LineFM Studios.'),
        findsOneWidget,
      );
    });

    testWidgets('Entwickler-Link fuehrt auf github.com/VectoDE', (
      tester,
    ) async {
      useSize(tester, 420, 1600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const AboutScreen(), scaffold: false));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Entwickelt von Tim Hauke (VectoDE) für LineFM Studios'),
      );
      await tester.pump();
      expect(host.opened.single.toString(), 'https://github.com/VectoDE');
    });

    testWidgets('Autor in der Credit-Zeile ist ein Link auf GitHub', (
      tester,
    ) async {
      useSize(tester, 420, 1600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const AboutScreen(), scaffold: false));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('Tim Hauke').first);
      await tester.pump();
      expect(host.opened.single.toString(), 'https://github.com/VectoDE');
    });

    testWidgets('RadioGruppe-Logo kommt zur Laufzeit von radiogruppe.de', (
      tester,
    ) async {
      useSize(tester, 420, 1600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const AboutScreen(), scaffold: false));
      await tester.pump();
      final logo = tester
          .widgetList<Image>(find.byType(Image))
          .map((i) => i.image)
          .whereType<NetworkImage>()
          .single;
      expect(logo.url, 'https://radiogruppe.de/assets/img/rgd-logo-dark.png');
      expect(radioGruppeLogoUrl, logo.url);
      // Gebuendeltes Asset wird nicht verwendet.
      expect(
        tester
            .widgetList<Image>(find.byType(Image))
            .map((i) => i.image)
            .whereType<AssetImage>(),
        isEmpty,
      );
    });

    testWidgets('Fallback-Text, wenn das Logo nicht laedt', (tester) async {
      useSize(tester, 420, 1600);
      final host = FeatureHost();
      await tester.pumpWidget(host.app(const AboutScreen(), scaffold: false));
      await tester.pumpAndSettle();
      // Im Test liefert das Netz einen Fehler, also erscheint der Name.
      expect(find.text('RadioGruppe Deutschland'), findsOneWidget);
    });

    testWidgets('Vertrauens-Badges nur mit konfigurierter URL', (tester) async {
      useSize(tester, 420, 1600);
      await tester.pumpWidget(
        FeatureHost().app(const AboutScreen(), scaffold: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Website-Prüfung bei Gridinsoft'), findsNothing);
      expect(find.text('Bewertungen bei Trustpilot'), findsNothing);

      await tester.pumpWidget(
        FeatureHost(
          config: const AppConfig(
            trustGridinsoftUrl: 'https://gridinsoft.com/x',
            trustTrustpilotUrl: 'https://trustpilot.com/y',
          ),
        ).app(const AboutScreen(), scaffold: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Website-Prüfung bei Gridinsoft'), findsOneWidget);
      expect(find.text('Bewertungen bei Trustpilot'), findsOneWidget);
    });
  });
}
