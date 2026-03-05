import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseCodeFenceLine', () {
    group('backtick fences', () {
      test('parses 3 backticks', () {
        final result = parseCodeFenceLine('```');
        expect(result, isNotNull);
        expect(result!.marker, '```');
        expect(result.rest, '');
      });

      test('parses 4+ backticks', () {
        final result = parseCodeFenceLine('````');
        expect(result, isNotNull);
        expect(result!.marker, '````');
      });

      test('parses backticks with language', () {
        final result = parseCodeFenceLine('```dart');
        expect(result, isNotNull);
        expect(result!.marker, '```');
        expect(result.rest, 'dart');
      });

      test('parses backticks with trailing content', () {
        final result = parseCodeFenceLine('```dart {lineLength: 80}');
        expect(result, isNotNull);
        expect(result!.marker, '```');
        expect(result.rest, 'dart {lineLength: 80}');
      });
    });

    group('tilde fences', () {
      test('parses 3 tildes', () {
        final result = parseCodeFenceLine('~~~');
        expect(result, isNotNull);
        expect(result!.marker, '~~~');
        expect(result.rest, '');
      });

      test('parses 4+ tildes', () {
        final result = parseCodeFenceLine('~~~~');
        expect(result, isNotNull);
        expect(result!.marker, '~~~~');
      });

      test('parses tildes with language', () {
        final result = parseCodeFenceLine('~~~dart');
        expect(result, isNotNull);
        expect(result!.marker, '~~~');
        expect(result.rest, 'dart');
      });
    });

    group('leading spaces', () {
      test('allows 1 leading space', () {
        final result = parseCodeFenceLine(' ```');
        expect(result, isNotNull);
        expect(result!.marker, '```');
      });

      test('allows 2 leading spaces', () {
        final result = parseCodeFenceLine('  ```');
        expect(result, isNotNull);
        expect(result!.marker, '```');
      });

      test('allows 3 leading spaces', () {
        final result = parseCodeFenceLine('   ```');
        expect(result, isNotNull);
        expect(result!.marker, '```');
      });

      test('rejects 4 leading spaces', () {
        final result = parseCodeFenceLine('    ```');
        expect(result, isNull);
      });
    });

    group('boundary lengths', () {
      test('rejects 2 backticks', () {
        final result = parseCodeFenceLine('``');
        expect(result, isNull);
      });

      test('rejects 2 tildes', () {
        final result = parseCodeFenceLine('~~');
        expect(result, isNull);
      });

      test('rejects 1 backtick', () {
        final result = parseCodeFenceLine('`');
        expect(result, isNull);
      });
    });

    group('non-fence lines', () {
      test('returns null for plain text', () {
        expect(parseCodeFenceLine('hello world'), isNull);
      });

      test('returns null for dashes', () {
        expect(parseCodeFenceLine('---'), isNull);
      });

      test('returns null for empty string', () {
        expect(parseCodeFenceLine(''), isNull);
      });
    });
  });

  group('canCloseCodeFence', () {
    test('closes backtick with matching backtick', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '```'),
        isTrue,
      );
    });

    test('closes tilde with matching tilde', () {
      expect(
        canCloseCodeFence(marker: '~~~', minLength: 3, line: '~~~'),
        isTrue,
      );
    });

    test('closes with longer marker', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '````'),
        isTrue,
      );
    });

    test('rejects shorter marker', () {
      expect(
        canCloseCodeFence(marker: '````', minLength: 4, line: '```'),
        isFalse,
      );
    });

    test('rejects different marker type', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '~~~'),
        isFalse,
      );
    });

    test('rejects tilde closing backtick', () {
      expect(
        canCloseCodeFence(marker: '~~~', minLength: 3, line: '```'),
        isFalse,
      );
    });

    test('rejects trailing content', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '```dart'),
        isFalse,
      );
    });

    test('allows trailing whitespace', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '```  '),
        isTrue,
      );
    });

    test('rejects non-fence line', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: 'not a fence'),
        isFalse,
      );
    });

    test('allows leading spaces on closing fence', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '  ```'),
        isTrue,
      );
    });

    test('rejects 4 leading spaces on closing fence', () {
      expect(
        canCloseCodeFence(marker: '```', minLength: 3, line: '    ```'),
        isFalse,
      );
    });
  });
}
