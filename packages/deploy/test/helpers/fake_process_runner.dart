import 'dart:io';

/// Records process invocations and returns canned [ProcessResult]s, so deploy
/// flows can be tested without shelling out to real executables.
class FakeProcessRunner {
  /// Every invocation captured, in order.
  final List<RecordedInvocation> invocations = [];

  /// Optional responder; return a [ProcessResult] for a matched invocation, or
  /// `null` to fall back to the default success result.
  final ProcessResult? Function(RecordedInvocation invocation)? responder;

  FakeProcessRunner({this.responder});

  Future<ProcessResult> call(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final invocation = RecordedInvocation(
      executable,
      arguments,
      workingDirectory,
    );
    invocations.add(invocation);

    return responder?.call(invocation) ?? ProcessResult(0, 0, '', '');
  }

  /// Convenience: the arguments of the first invocation for [executable].
  List<String>? argsFor(String executable) {
    for (final invocation in invocations) {
      if (invocation.executable == executable) return invocation.arguments;
    }

    return null;
  }
}

/// A single captured process invocation.
class RecordedInvocation {
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;

  const RecordedInvocation(
    this.executable,
    this.arguments,
    this.workingDirectory,
  );
}
