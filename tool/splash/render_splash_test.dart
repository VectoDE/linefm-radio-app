// Renders the native splash images from the Flutter loader's word mark
// (LoaderMark), so the native splash and the first app frame are identical.
//
// Run after changing LoaderMark, the brand font or the brand colours:
//   flutter test tool/splash/render_splash_test.dart
// It writes the PNGs for Android (before 12) and iOS; commit them.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/features/loader/app_loader.dart';
import 'package:linefm_radio/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../test/golden_support.dart';

/// Room above and below for the -7 degree skew, the same on both sides so the
/// mark stays centred in the image.
const double _skewRoom = 32;

const Map<String, double> _android = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

const Map<String, double> _ios = <String, double>{
  'LaunchImage.png': 1,
  'LaunchImage@2x.png': 2,
  'LaunchImage@3x.png': 3,
};

void main() {
  testWidgets('render native splash mark', (tester) async {
    await loadAppFonts();
    final key = GlobalKey();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('de'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: _skewRoom),
              // First frame of the animated mark, as the app shows it.
              child: LoaderMark(compact: true, animate: true),
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final size = boundary.size;

    Future<void> write(String path, double ratio) async {
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: ratio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(path).writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    for (final MapEntry(key: density, value: ratio) in _android.entries) {
      await write(
        'android/app/src/main/res/drawable-$density/launch_mark.png',
        ratio,
      );
    }
    for (final MapEntry(key: name, value: ratio) in _ios.entries) {
      await write(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/$name',
        ratio,
      );
    }
    // Logical size for launch_background.xml and LaunchScreen.storyboard.
    debugPrint('SPLASH_MARK ${size.width.ceil()} x ${size.height.ceil()}');
  });
}
