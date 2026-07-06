import 'dart:convert';

/// Sealed class hierarchy for chat messages in the SuperDeck AI application.
///
/// Uses sealed classes for exhaustive pattern matching on message types.
sealed class SuperdeckChatMessage {
  const SuperdeckChatMessage();
}

/// A message sent by the user.
final class SuperdeckUserMessage extends SuperdeckChatMessage {
  const SuperdeckUserMessage(this.text);

  final String text;
}

/// A response from the AI assistant.
final class SuperdeckAiMessage extends SuperdeckChatMessage {
  const SuperdeckAiMessage(this.text);

  final String text;
}

/// A debug message for development/debugging purposes.
///
/// Only displayed when debug mode is enabled.
final class SuperdeckDebugMessage extends SuperdeckChatMessage {
  const SuperdeckDebugMessage(this.text);

  final String text;
}

/// A debug message containing formatted JSON.
///
/// Automatically formats JSON with pretty-printing and markdown code blocks.
/// Falls back to raw text if JSON parsing fails.
final class SuperdeckJsonDebugMessage extends SuperdeckChatMessage {
  SuperdeckJsonDebugMessage(String json) {
    String jsonMD(String content) => '```json\n$content```';

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final prettyJson = JsonEncoder.withIndent('  ').convert(map);
      text = jsonMD(prettyJson);
    } catch (e) {
      text = json;
    }
  }

  late final String text;
}

/// Typed parser for user action payloads from GenUI.
///
/// Safely extracts and validates the action structure from JSON.
/// Expected GenUI v0.9 format:
/// ```json
/// {
///   "version": "v0.9",
///   "action": {
///     "name": "action_name",
///     "context": { "message": "Display text", ... }
///   }
/// }
/// ```
class UserActionPayload {
  final String actionName;
  final Map<String, dynamic> context;

  const UserActionPayload({required this.actionName, required this.context});

  /// The message to display in chat, extracted from context.
  String get displayMessage => context['message'] as String? ?? actionName;

  /// Attempts to parse a JSON string into a [UserActionPayload].
  ///
  /// Returns null if parsing fails or the structure is unexpected.
  static UserActionPayload? tryParse(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      if (json is! Map<String, dynamic>) return null;

      final userAction = json['action'] ?? json['userAction'];
      if (userAction is! Map<String, dynamic>) return null;

      final name = userAction['name'];
      if (name is! String) return null;

      final context = userAction['context'];
      final contextMap = context is Map<String, dynamic>
          ? context
          : <String, dynamic>{};

      return UserActionPayload(actionName: name, context: contextMap);
    } catch (_) {
      return null;
    }
  }
}
