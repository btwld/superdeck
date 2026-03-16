import 'package:superdeck_cli/src/utils/update_pubspec.dart';
import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  final deckWorkspace = DeckWorkspace();
  final superdeckPath = '${deckWorkspace.superdeckDir.path}/';
  final assetsPath = '${deckWorkspace.assetsDir.path}/';
  group('updatePubspecAssets', () {
    test('adds superdeck assets to empty pubspec', () {
      final input = '''
name: test_app
description: A test app
version: 1.0.0
''';

      final result = updatePubspecAssets(deckWorkspace, input);
      expect(result.contains(superdeckPath), isTrue);
      expect(result.contains(assetsPath), isTrue);
    });

    test('adds superdeck assets to pubspec with existing flutter section', () {
      final input = '''
name: test_app
flutter:
  uses-material-design: true
''';
      final result = updatePubspecAssets(deckWorkspace, input);
      expect(result.contains(superdeckPath), isTrue);
      expect(result.contains(assetsPath), isTrue);
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
      expect(result.contains(assetsPath), isTrue);
    });

    test('does not duplicate existing superdeck assets', () {
      final input =
          '''
name: test_app
flutter:
  assets:
    - $superdeckPath
    - $assetsPath
''';
      final result = updatePubspecAssets(deckWorkspace, input);

      // Should not duplicate - still only 2 total occurrences
      expect(result.split(superdeckPath).length - 1, equals(2));
      expect(result.split(assetsPath).length - 1, equals(1));
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
      expect(result.contains(assetsPath), isTrue);
    });

    test('adds correct normalized paths without duplicates', () {
      final input = '''
name: test_app
flutter:
  uses-material-design: true
''';
      final result = updatePubspecAssets(deckWorkspace, input);

      // Should have exactly the paths we want
      expect(result.contains(superdeckPath), isTrue);
      expect(result.contains(assetsPath), isTrue);

      // Should not have ./ prefix versions
      expect(result.contains('./$superdeckPath'), isFalse);
      expect(result.contains('./$assetsPath'), isFalse);
    });

    test('running setup multiple times does not create duplicates', () {
      final input = '''
name: test_app
flutter:
  assets:
    - assets/
''';
      // Run setup first time
      final firstRun = updatePubspecAssets(deckWorkspace, input);

      // Verify correct paths were added
      expect(firstRun.contains(superdeckPath), isTrue);
      expect(firstRun.contains(assetsPath), isTrue);

      // Run setup second time on the result
      final secondRun = updatePubspecAssets(deckWorkspace, firstRun);

      // Should be identical - no new duplicates added
      expect(firstRun, equals(secondRun));
    });
  });
}
