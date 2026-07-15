import 'dart:convert';

/// Typed parser for user actions emitted by GenUI surfaces.
final class UserActionPayload {
  final String actionName;

  final Map<String, dynamic> context;
  const UserActionPayload({required this.actionName, required this.context});

  /// Returns `null` when the payload is malformed or lacks an action name.
  static UserActionPayload? tryParse(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      if (json is! Map<String, dynamic>) return null;

      final userAction = json['action'] ?? json['userAction'];
      if (userAction is! Map<String, dynamic>) return null;

      final name = userAction['name'];
      if (name is! String) return null;

      final context = userAction['context'];

      return UserActionPayload(
        actionName: name,
        context: context is Map<String, dynamic> ? context : {},
      );
    } on FormatException {
      return null;
    }
  }
}
