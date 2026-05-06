import 'package:superdeck_core/superdeck_core.dart';

/// Events emitted during presentation build and watch operations.
sealed class BuildEvent {
  const BuildEvent();
}

/// Emitted when a build starts.
final class BuildStarted extends BuildEvent {
  const BuildStarted();
}

/// Emitted when a build completes successfully.
final class BuildCompleted extends BuildEvent {
  final List<Slide> slides;

  const BuildCompleted(this.slides);
}

/// Emitted when a build fails with an error.
final class BuildFailed extends BuildEvent {
  final Object error;
  final StackTrace? stackTrace;

  const BuildFailed(this.error, [this.stackTrace]);
}
