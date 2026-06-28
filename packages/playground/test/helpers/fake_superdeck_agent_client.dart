import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:playground/features/ai/core/ai/services/superdeck_agent_client.dart';

class FakeSuperdeckAgentClient implements SuperdeckAgentClient {
  FakeSuperdeckAgentClient({
    List<String> chunks = const [],
    Stream<SuperdeckAgentResponseChunk>? responseStream,
  }) : chunks = List.unmodifiable(chunks),
       _responseStream = responseStream;

  final List<String> chunks;
  final Stream<SuperdeckAgentResponseChunk>? _responseStream;
  final prompts = <String>[];
  final histories = <List<dartantic.ChatMessage>>[];
  String? capturedApiKey;
  String? capturedModelName;
  var disposed = false;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    prompts.add(prompt);
    histories.add(history.toList());

    final responseStream = _responseStream;
    if (responseStream != null) {
      yield* responseStream;
      return;
    }

    for (final chunk in chunks) {
      yield SuperdeckAgentResponseChunk(text: chunk);
    }
  }

  @override
  void dispose() {
    disposed = true;
  }
}

String dartanticMessageText(dartantic.ChatMessage message) {
  return message.parts
      .whereType<dartantic.TextPart>()
      .map((e) => e.text)
      .join();
}

class QueuedSuperdeckAgentClient implements SuperdeckAgentClient {
  final prompts = <String>[];
  final histories = <List<dartantic.ChatMessage>>[];
  final _gates = <Completer<void>>[];
  var activeInvocations = 0;
  var maxActiveInvocations = 0;
  var disposed = false;

  @override
  Stream<SuperdeckAgentResponseChunk> sendStream(
    String prompt, {
    required Iterable<dartantic.ChatMessage> history,
  }) async* {
    prompts.add(prompt);
    histories.add(history.toList());
    activeInvocations++;
    if (activeInvocations > maxActiveInvocations) {
      maxActiveInvocations = activeInvocations;
    }

    final gate = Completer<void>();
    _gates.add(gate);
    try {
      await gate.future;
      yield const SuperdeckAgentResponseChunk(text: 'Done');
    } finally {
      activeInvocations--;
    }
  }

  void completeNext() {
    if (_gates.isEmpty) {
      throw StateError('No queued request to complete.');
    }
    _gates.removeAt(0).complete();
  }

  @override
  void dispose() {
    disposed = true;
  }
}
