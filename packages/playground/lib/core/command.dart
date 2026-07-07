import 'dart:async';

import 'package:flutter/foundation.dart';

import 'result.dart';

typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, A> = Future<Result<T>> Function(A);

/// Encapsulates an async action, exposing its running and error states and
/// ensuring it cannot be launched again until it finishes.
///
/// Use [Command0] for actions without arguments and [Command1] for actions
/// with a single argument. Actions must return a [Result].
///
/// A command is *not* a store: it represents an action, not state. Consume its
/// result by listening for changes, then call [clearResult] once handled.
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool _running = false;

  /// True while the action is running.
  bool get running => _running;

  Result<T>? _result;

  /// True if the action completed with an error.
  bool get error => _result is Failure;

  /// True if the action completed successfully.
  bool get completed => _result is Ok;

  /// The last action result, or null if never run / cleared.
  Result<T>? get result => _result;

  /// Clears the last action result.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(CommandAction0<T> action) async {
    // Prevent re-entrancy — e.g. multiple taps on a button.
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command] without arguments.
abstract class Command0<T> extends Command<T> {
  Command0();

  Future<Result<T>> action();

  /// Executes the action.
  Future<void> call() => _execute(action);
}

/// A [Command] with a single argument.
abstract class Command1<T, A> extends Command<T> {
  Command1();

  Future<Result<T>> action(A argument);

  /// Executes the action with [argument].
  Future<void> call(A argument) => _execute(() => action(argument));
}
