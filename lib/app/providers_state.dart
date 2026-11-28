part of 'providers.dart';

// ----------------------------------------------------------- Persistiert

class FavoritesNotifier extends Notifier<List<Favorite>> {
  @override
  List<Favorite> build() => ref.read(prefsProvider).readFavorites();

  void toggle(Favorite favorite) {
    state = FavoritesLogic.toggle(state, favorite);
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
  }

  void remove(String key) {
    state = FavoritesLogic.remove(state, key);
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
  }

  /// "Rueckgaengig" nach dem Entfernen: setzt [favorite] wieder an
  /// [index]. Ist er inzwischen wieder da, bleibt die Liste unveraendert.
  void restore(Favorite favorite, int index) {
    if (FavoritesLogic.contains(state, favorite.key)) return;
    final next = <Favorite>[...state]
      ..insert(index.clamp(0, state.length), favorite);
    state = next;
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
  }

  /// Fuehrt importierte Favoriten mit den vorhandenen zusammen (Doppelte
  /// zaehlen einmal) und liefert die Zahl der neuen.
  int importFavorites(List<Favorite> imported) {
    final merged = FavoritesImport.merge(state, imported);
    state = merged.favorites;
    unawaited(
      ref.read(prefsProvider).writeFavorites(state).catchError(_logPrefsError),
    );
    return merged.added;
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Favorite>>(
  FavoritesNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(prefsProvider).readSettings();

  void update(AppSettings Function(AppSettings current) change) {
    state = change(state);
    unawaited(
      ref.read(prefsProvider).writeSettings(state).catchError(_logPrefsError),
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Speicher-Bestaetigung (Speicher-Hinweis, auf allen Plattformen).
class StorageConsentNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(prefsProvider).storageConsent;

  Future<void> set({required bool value}) async {
    state = value;
    await ref.read(prefsProvider).setStorageConsent(value: value);
  }
}

final storageConsentProvider = NotifierProvider<StorageConsentNotifier, bool>(
  StorageConsentNotifier.new,
);

/// null = noch nicht entschieden.
class TelemetryConsentNotifier extends Notifier<bool?> {
  @override
  bool? build() => ref.read(prefsProvider).readTelemetryConsent();

  Future<void> set({required bool? value}) async {
    state = value;
    await ref.read(prefsProvider).writeTelemetryConsent(value: value);
    await ref.read(telemetryProvider).setConsent(value: value ?? false);
  }
}

final telemetryConsentProvider =
    NotifierProvider<TelemetryConsentNotifier, bool?>(
      TelemetryConsentNotifier.new,
    );

// ------------------------------------------------------- Timer, Wecker, Cast

class SleepTimerNotifier extends Notifier<SleepTimerState> {
  @override
  SleepTimerState build() {
    final service = ref.watch(sleepTimerServiceProvider);
    // Ablauf, Ausblenden und Restzeit meldet der Dienst selbst.
    final sub = service.states.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return service.state;
  }

  Future<void> start(SleepTimerMode mode, {Track? currentTrack}) async {
    final service = ref.read(sleepTimerServiceProvider);
    await service.start(mode, currentTrack: currentTrack);
    state = service.state;
  }

  Future<void> cancel() async {
    final service = ref.read(sleepTimerServiceProvider);
    await service.cancel();
    state = service.state;
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
      SleepTimerNotifier.new,
    );

class AlarmNotifier extends Notifier<List<AlarmRule>> {
  @override
  List<AlarmRule> build() {
    final stored = ref.read(prefsProvider).readAlarms();
    // Aeltere einmalige Regeln ohne festen Termin bekommen ihn jetzt.
    return AlarmSchedule.withFiresAt(
      stored,
      stored,
      ref.read(clockProvider).now(),
    );
  }

  Future<void> setRules(List<AlarmRule> rules) async {
    // Einmalige Regeln bekommen beim Einschalten/Aendern ihren festen Termin.
    final next = AlarmSchedule.withFiresAt(
      rules,
      state,
      ref.read(clockProvider).now(),
    );
    state = next;
    await ref.read(prefsProvider).writeAlarms(next);
    await ref.read(alarmCoordinatorProvider).rescheduleAll(next);
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, List<AlarmRule>>(
  AlarmNotifier.new,
);

final castProvider = StreamProvider<CastState>(
  (ref) => ref.watch(castServiceProvider).states,
);
