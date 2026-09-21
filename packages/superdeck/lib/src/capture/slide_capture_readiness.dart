import 'package:flutter/widgets.dart';

/// One asynchronous visual that finished without rendering.
typedef SlideCaptureFailure = ({String? label, String reason});

/// Coordinates asynchronous widget readiness during isolated slide capture.
///
/// Custom widgets that load data or assets can call [track] and complete the
/// returned handle when their capture-safe visual state is ready. Capture waits
/// for all registered handles, subject to its bounded settle limit.
///
/// A dependency that gives up reports [SlideCaptureReadinessHandle.fail]
/// instead, which ends the wait and records the reason in [failures]. Readiness
/// alone therefore means *finished*; callers that need *rendered* check
/// [failures] too.
final class SlideCaptureReadiness {
  final _pending = <int, String?>{};
  final _failures = <SlideCaptureFailure>[];
  var _nextId = 0;

  /// Registers pending capture work from the nearest readiness scope.
  ///
  /// Outside isolated capture the returned handle is already complete, so the
  /// same widget can use this API in normal presentation rendering.
  static SlideCaptureReadinessHandle track(
    BuildContext context, {
    String? label,
  }) {
    final readiness = _SlideCaptureReadinessScope.maybeOf(context)?.readiness;

    return readiness?._begin(label) ?? SlideCaptureReadinessHandle._completed();
  }

  SlideCaptureReadinessHandle _begin(String? label) {
    final id = _nextId++;
    _pending[id] = label;

    return SlideCaptureReadinessHandle._(
      onComplete: () => _pending.remove(id),
      onFail: (reason) {
        _pending.remove(id);
        _failures.add((label: label, reason: reason));
      },
    );
  }

  /// Whether every registered asynchronous visual is ready to capture.
  bool get isReady => _pending.isEmpty;

  /// Asynchronous visuals that finished without rendering.
  ///
  /// They are kept for the lifetime of this readiness scope: a dependency that
  /// failed once does not come back on its own.
  List<SlideCaptureFailure> get failures => List.unmodifiable(_failures);

  /// Number of asynchronous visuals still pending.
  int get pendingCount => _pending.length;

  /// Diagnostic labels for asynchronous visuals still pending.
  Iterable<String> get pendingLabels => _pending.values.whereType<String>();

  /// Wraps the isolated slide render tree in this readiness scope.
  Widget bind(Widget child) =>
      _SlideCaptureReadinessScope(readiness: this, child: child);
}

/// Idempotent completion handle for one asynchronous capture dependency.
final class SlideCaptureReadinessHandle {
  VoidCallback? _onComplete;
  void Function(String reason)? _onFail;

  SlideCaptureReadinessHandle._({
    required VoidCallback onComplete,
    required void Function(String reason) onFail,
  }) : _onComplete = onComplete,
       _onFail = onFail;

  SlideCaptureReadinessHandle._completed();

  /// Whether this dependency has already reported an outcome.
  bool get isCompleted => _onComplete == null && _onFail == null;

  /// Signals readiness once; subsequent calls are no-ops.
  void complete() {
    final callback = _onComplete;
    _onComplete = null;
    _onFail = null;
    callback?.call();
  }

  /// Reports that this dependency finished without its visual.
  ///
  /// The wait ends the same way [complete] ends it. [reason] is shown to
  /// whoever asked for the capture, so it names what is missing.
  void fail(String reason) {
    final callback = _onFail;
    _onComplete = null;
    _onFail = null;
    callback?.call(reason);
  }
}

final class _SlideCaptureReadinessScope extends InheritedWidget {
  final SlideCaptureReadiness readiness;

  const _SlideCaptureReadinessScope({
    required this.readiness,
    required super.child,
  });

  static _SlideCaptureReadinessScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SlideCaptureReadinessScope>();

  @override
  bool updateShouldNotify(_SlideCaptureReadinessScope oldWidget) =>
      readiness != oldWidget.readiness;
}
