import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linefm_radio/app/providers.dart';
import 'package:linefm_radio/core/config/app_config.dart';

import '../support/in_memory_prefs_store.dart';
import '../support/test_doubles.dart';

/// Hoererzahl nur mit `showListenerCount: true` (config/features.yaml).
void main() {
  Future<int?> listeners({required bool enabled}) async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(showListenerCount: enabled),
        ),
        prefsProvider.overrideWithValue(InMemoryPrefsStore()),
        nowPlayingRepositoryProvider.overrideWithValue(
          FakeNowPlayingRepository(listeners: 42),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(listenersProvider, (_, _) {});
    addTearDown(sub.close);
    return container.read(listenersProvider.future);
  }

  test('Standard: aus', () {
    expect(const AppConfig().showListenerCount, isFalse);
    expect(AppConfig.fromEnvironment().showListenerCount, isFalse);
  });

  test('aus: keine Hoererzahl', () async {
    expect(await listeners(enabled: false), isNull);
  });

  test('an: Hoererzahl wird geliefert', () async {
    expect(await listeners(enabled: true), 42);
  });
}
