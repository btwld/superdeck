import 'package:superdeck_cli/src/utils/update_pubspec.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  final deckWorkspace = DeckWorkspace();
  final superdeckPath = '${deckWorkspace.superdeckDir.path}/';
  group('updatePubspecAssets', () {
    test('adds superdeck assets to empty pubspec', () {
      final input = '''
name: test_app
description: A test app
version: 1.0.0
''';

      final result = updatePubspecAssets(deckWorkspace, input);
      expect(result.contains(superdeckPath), isTrue);
    });

    test('adds superdeck assets to pubspec with existing flutter section', () {
      final input = '''
name: test_app
flutter:
  uses-material-design: true
''';
      final result = updatePubspecAssets(deckWorkspace, input);
      expect(result.contains(superdeckPath), isTrue);
      expect(result.contains('uses-material-design: true'), isTrue);
    });

    test('preserves existing assets while adding superdeck assets', () {
      final input = '''
name: test_app
flutter:
  assets:
    - assets/images/
    - assets/fonts/
''';
      final result = updatePubspecAssets(deckWorkspace, input);
      expect(result.contains('assets/images/'), isTrue);
      expect(result.contains('assets/fonts/'), isTrue);
      expect(result.contains(superdeckPath), isTrue);
    });

    test('does not duplicate existing superdeck assets', () {
      final input =
          '''
name: test_app
flutter:
  assets:
    - $superdeckPath
''';
      final result = updatePubspecAssets(deckWorkspace, input);

      // Already present; updater returns unchanged content.
      expect(result, equals(input));
      expect(result.split(superdeckPath).length - 1, equals(1));
    });

    test('preserves other flutter configuration', () {
      final input = '''
name: test_app
flutter:
  uses-material-design: true
  fonts:
    - family: CustomFont
      fonts:
        - asset: fonts/CustomFont-Regular.ttf
''';
      final result = updatePubspecAssets(deckWorkspace, input);
      expect(result.contains('uses-material-design: true'), isTrue);
      expect(result.contains('family: CustomFont'), isTrue);
      expect(result.contains('fonts/CustomFont-Regular.ttf'), isTrue);
      expect(result.contains(superdeckPath), isTrue);
    });

    test('adds correct normalized paths without duplicates', () {
      final input = '''
name: test_app
flutter:
  uses-material-design: true
''';
      final result = updatePubspecAssets(deckWorkspace, input);

      expect(result.contains(superdeckPath), isTrue);
      expect(result.contains('./$superdeckPath'), isFalse);
    });

    test('running the updater multiple times does not create duplicates', () {
      final input = '''
name: test_app
flutter:
  assets:
    - assets/
''';
      final firstRun = updatePubspecAssets(deckWorkspace, input);

      expect(firstRun.contains(superdeckPath), isTrue);

      final secondRun = updatePubspecAssets(deckWorkspace, firstRun);

      expect(firstRun, equals(secondRun));
    });
  });
}
