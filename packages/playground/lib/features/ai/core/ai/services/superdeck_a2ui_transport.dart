import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:genui/genui.dart' as genui;

import '../../debug_logger.dart';
import 'superdeck_agent_client.dart';

typedef SuperdeckTransportFactory =
    SuperdeckA2uiTransport Function({
      required String apiKey,
      required String modelName,
      required String systemPrompt,
      required List<dartantic.Tool> tools,
      SuperdeckAgentClientFactory agentClientFactory,
    });

class SuperdeckA2uiTransport implements genui.Transport {
  SuperdeckA2uiTransport({
    required String apiKey,
    required String modelName,
    required String systemPrompt,
    required List<dartantic.Tool> tools,
    SuperdeckAgentClientFactory agentClientFactory =
        DartanticSuperdeckAgentClient.new,
  }) : _client = agentClientFactory(
         apiKey: apiKey,
         modelName: modelName,
         tools: tools,
       ),
       _history = [dartantic.ChatMessage.system(systemPrompt)] {
    _adapter = genui.A2uiTransportAdapter(onSend: _sendToAgent);
  }

  final SuperdeckAgentClient _client;
  final List<dartantic.ChatMessage> _history;
  late final genui.A2uiTransportAdapter _adapter;
  var _disposed = false;

  List<dartantic.ChatMessage> get history => List.unmodifiable(_history);

  @override
  Stream<genui.A2uiMessage> get incomingMessages => _adapter.incomingMessages;

  @override
  Stream<String> get incomingText => _adapter.incomingText;

  @override
  Future<void> sendRequest(genui.ChatMessage message) =>
      _adapter.sendRequest(message);

  Future<void> _sendToAgent(genui.ChatMessage message) async {
    if (_disposed) {
      throw StateError('Transport has been disposed.');
    }

    final prompt = _promptFromMessage(message);
    if (prompt.trim().isEmpty) return;

    final fallbackResponse = StringBuffer();
    final generatedMessages = <dartantic.ChatMessage>[];
    await for (final chunk in _client.sendStream(prompt, history: _history)) {
      if (chunk.text.isNotEmpty) {
        fallbackResponse.write(chunk.text);
        _adapter.addChunk(chunk.text);
      }
      generatedMessages.addAll(chunk.messages);
    }

    if (generatedMessages.isNotEmpty) {
      _history.addAll(generatedMessages);
      return;
    }

    _history
      ..add(dartantic.ChatMessage.user(prompt))
      ..add(dartantic.ChatMessage.model(fallbackResponse.toString()));
  }

  String _promptFromMessage(genui.ChatMessage message) {
    final buffer = StringBuffer();
    for (final part in message.parts) {
      final interactionPart = part.asUiInteractionPart;
      if (interactionPart != null) {
        buffer.write(interactionPart.interaction);
        continue;
      }

      if (part is genui.TextPart) {
        buffer.write(part.text);
      }
    }

    final prompt = buffer.toString();
    debugLog.log('AGENT', 'Forwarding prompt (${prompt.length} chars)');
    return prompt;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _adapter.dispose();
    _client.dispose();
  }
}
