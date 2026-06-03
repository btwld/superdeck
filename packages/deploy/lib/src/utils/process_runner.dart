import 'dart:io';

/// Runs an external process and returns its [ProcessResult].
///
/// Abstracted as a typedef so tests can inject a fake runner instead of
/// shelling out to real `git` or `flutter` executables.
typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      String? workingDirectory,
    });

/// Default [ProcessRunner] backed by [Process.run].
Future<ProcessResult> defaultProcessRunner(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
}
