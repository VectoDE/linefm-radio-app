import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/platform/desktop/window_reveal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowRevealChannel, (call) async {
          calls.add(call.method);
          return null;
        });
  });

  test('reveals the window only once the loader is presented', () async {
    final presented = Completer<void>();
    final done = revealWindowWhenPresented(
      isWindows: true,
      presented: () => presented.future,
    );
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
    presented.complete();
    await done;
    expect(calls, <String>['reveal']);
  });

  test('does nothing outside Windows', () async {
    await revealWindowWhenPresented(isWindows: false);
    expect(calls, isEmpty);
  });
}
