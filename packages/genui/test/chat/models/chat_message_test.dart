import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck_genui/src/chat/chat_message.dart';

void main() {
  group('SuperdeckChatMessage', () {
    group('SuperdeckUserMessage', () {
      test('stores text correctly', () {
        const message = SuperdeckUserMessage('Hello world');
        expect(message.text, 'Hello world');
      });
    });

    group('SuperdeckAiMessage', () {
      test('stores text correctly', () {
        const message = SuperdeckAiMessage('AI response');
        expect(message.text, 'AI response');
      });
    });

    group('SuperdeckDebugMessage', () {
      test('stores text correctly', () {
        const message = SuperdeckDebugMessage('Debug info');
        expect(message.text, 'Debug info');
      });
    });

    group('SuperdeckJsonDebugMessage', () {
      test('formats valid JSON with pretty printing', () {
        final message = SuperdeckJsonDebugMessage('{"key":"value"}');
        expect(message.text, contains('```json'));
        expect(message.text, contains('"key"'));
        expect(message.text, contains('"value"'));
      });

      test('preserves invalid JSON as-is', () {
        final message = SuperdeckJsonDebugMessage('not valid json');
        expect(message.text, 'not valid json');
      });

      test('handles nested JSON', () {
        final message = SuperdeckJsonDebugMessage(
          '{"outer":{"inner":"value"}}',
        );
        expect(message.text, contains('"outer"'));
        expect(message.text, contains('"inner"'));
      });

      test('handles empty object', () {
        final message = SuperdeckJsonDebugMessage('{}');
        expect(message.text, contains('```json'));
        expect(message.text, contains('{}'));
      });
    });

    group('exhaustive pattern matching', () {
      test('switch expression covers all cases', () {
        String describe(SuperdeckChatMessage message) {
          return switch (message) {
            SuperdeckUserMessage() => 'user',
            SuperdeckAiMessage() => 'ai',
            SuperdeckDebugMessage() => 'debug',
            SuperdeckJsonDebugMessage() => 'json_debug',
          };
        }

        expect(describe(const SuperdeckUserMessage('test')), 'user');
        expect(describe(const SuperdeckAiMessage('test')), 'ai');
        expect(describe(const SuperdeckDebugMessage('test')), 'debug');
        expect(describe(SuperdeckJsonDebugMessage('{"a":1}')), 'json_debug');
      });
    });
  });

  group('UserActionPayload', () {
    group('tryParse', () {
      test('parses valid user action', () {
        const json = '''
        {
          "userAction": {
            "name": "select_option",
            "context": {"message": "Selected A"}
          }
        }
        ''';

        final payload = UserActionPayload.tryParse(json);

        expect(payload, isNotNull);
        expect(payload!.actionName, 'select_option');
        expect(payload.displayMessage, 'Selected A');
      });

      test('returns null for invalid JSON', () {
        final payload = UserActionPayload.tryParse('not json');
        expect(payload, isNull);
      });

      test('returns null for missing userAction key', () {
        final payload = UserActionPayload.tryParse('{"other": "data"}');
        expect(payload, isNull);
      });

      test('returns null for missing name', () {
        final payload = UserActionPayload.tryParse(
          '{"userAction": {"context": {}}}',
        );
        expect(payload, isNull);
      });

      test('returns null for non-string name', () {
        final payload = UserActionPayload.tryParse(
          '{"userAction": {"name": 123}}',
        );
        expect(payload, isNull);
      });

      test('handles missing context gracefully', () {
        const json = '{"userAction": {"name": "action"}}';
        final payload = UserActionPayload.tryParse(json);

        expect(payload, isNotNull);
        expect(payload!.actionName, 'action');
        expect(payload.context, isEmpty);
      });

      test('uses actionName as fallback displayMessage', () {
        const json = '{"userAction": {"name": "my_action", "context": {}}}';
        final payload = UserActionPayload.tryParse(json);

        expect(payload, isNotNull);
        expect(payload!.displayMessage, 'my_action');
      });

      test('returns null for array input', () {
        final payload = UserActionPayload.tryParse('[1, 2, 3]');
        expect(payload, isNull);
      });

      test('returns null when userAction is not a map', () {
        final payload = UserActionPayload.tryParse('{"userAction": "string"}');
        expect(payload, isNull);
      });
    });
  });
}
