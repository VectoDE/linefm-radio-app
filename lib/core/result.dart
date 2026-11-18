/// Einfacher Ergebnistyp fuer Dienste ohne Exceptions im Normalfall.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error, [this.stack]);
  final Object error;
  final StackTrace? stack;
}
