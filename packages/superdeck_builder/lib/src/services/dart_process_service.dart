import 'dart:io';

import '../utils/process_utils.dart';
import 'disposable.dart';

/// Service for interacting with Dart processes
/// @deprecated Use ProcessUtils instead
class DartProcessService implements Disposable {
  final Map<String, String> _environmentOverrides;

  DartProcessService({Map<String, String>? environmentOverrides})
      : _environmentOverrides = environmentOverrides ?? {};

  /// Run a Dart command with arguments
  Future<ProcessResult> run(List<String> args) {
    return ProcessUtils.runDartCommand(
      args,
      environmentOverrides: _environmentOverrides,
    );
  }

  /// Format Dart code using dart format
  Future<String> format(
    String code, {
    int? lineLength,
    bool fix = true,
  }) {
    return ProcessUtils.formatDartCode(
      code,
      lineLength: lineLength,
      fix: fix,
      environmentOverrides: _environmentOverrides,
    );
  }

  @override
  Future<void> dispose() async {
    // Nothing to dispose in this service
    return Future.value();
  }
}
