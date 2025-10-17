import 'dart:io';

/// Run a Dart command with arguments
Future<ProcessResult> runDartCommand(
  List<String> args, {
  Map<String, String>? environmentOverrides,
}) {
  return Process.run(
    'dart',
    args,
    environment: environmentOverrides?.isNotEmpty == true
        ? environmentOverrides
        : null,
  );
}
