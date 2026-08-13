import 'package:flutter/widgets.dart';

/// Coordinates asynchronous widget readiness during isolated slide capture.
///
/// Custom widgets that load data or assets can call [track] and complete the
/// returned handle when their capture-safe visual state is ready. Capture waits
/// for all registered handles, subject to its bounded settle limit.
final class SlideCaptureReadiness {
  final _pending = <int, String?>{};
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

    return SlideCaptureReadinessHandle._(() => _pending.remove(id));
  }

  /// Whether every registered asynchronous visual is ready to capture.
  bool get isReady => _pending.isEmpty;

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

  SlideCaptureReadinessHandle._(this._onComplete);

  SlideCaptureReadinessHandle._completed() : _onComplete = null;

  /// Whether this dependency has already signaled readiness.
  bool get isCompleted => _onComplete == null;

  /// Signals readiness once; subsequent calls are no-ops.
  void complete() {
    final callback = _onComplete;
    _onComplete = null;
    callback?.call();
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
