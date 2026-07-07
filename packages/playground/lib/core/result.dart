/// Utility type that wraps the outcome of an operation that can fail.
///
/// Evaluate a result with a switch:
/// ```dart
/// switch (result) {
///   case Ok(:final value):
///     print(value);
///   case Failure(:final error):
///     print(error);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result] holding [value].
  const factory Result.ok(T value) = Ok._;

  /// Creates a failed [Result] holding [error].
  const factory Result.error(Exception error) = Failure._;
}

/// A successful [Result] carrying a [value].
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  /// The successful value.
  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// A failed [Result] carrying an [error].
final class Failure<T> extends Result<T> {
  const Failure._(this.error);

  /// The failure error.
  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}
