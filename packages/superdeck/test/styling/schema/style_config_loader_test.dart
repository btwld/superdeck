import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/styling/schema/style_config_loader.dart';

void main() {
  group('StyleConfigLoader', () {
    group('fromYamlString', () {
      test('parses valid YAML into StyleConfiguration', () {
        final yaml = '''
base:
  h1:
    fontSize: 96.0
styles:
  - name: title
    h1:
      fontSize: 120.0
''';
        final result = StyleConfigLoader.fromYamlString(yaml);

        expect(result, isNotNull);
        expect(result!.baseStyle, isNotNull);
        expect(result.styles, hasLength(1));
        expect(result.styles.containsKey('title'), isTrue);
      });

      test('returns null for empty string', () {
        final result = StyleConfigLoader.fromYamlString('');
        expect(result, isNull);
      });

      test('returns null for whitespace-only string', () {
        final result = StyleConfigLoader.fromYamlString('   \n\t  ');
        expect(result, isNull);
      });

      test('returns null for invalid YAML syntax', () {
        final invalidYaml = 'invalid: yaml: [';
        final result = StyleConfigLoader.fromYamlString(invalidYaml);
        expect(result, isNull);
      });

      test('returns null for schema validation failure', () {
        // fontsize is a typo (should be fontSize) - strict validation catches this
        final yaml = '''
base:
  h1:
    fontsize: 96.0
''';
        final result = StyleConfigLoader.fromYamlString(yaml);
        expect(result, isNull);
      });

      test('returns null for empty map', () {
        final yaml = '{}';
        final result = StyleConfigLoader.fromYamlString(yaml);
        expect(result, isNull);
      });
    });

    group('load', () {
      test('uses injected loader and parses result', () async {
        final yaml = '''
base:
  h1:
    fontSize: 96.0
''';
        final result = await StyleConfigLoader.load(
          loader: () async => yaml,
        );

        expect(result, isNotNull);
        expect(result!.baseStyle, isNotNull);
      });

      test('returns null when loader returns null', () async {
        final result = await StyleConfigLoader.load(
          loader: () async => null,
        );

        expect(result, isNull);
      });

      test('returns null when loader returns invalid YAML', () async {
        final result = await StyleConfigLoader.load(
          loader: () async => 'invalid: yaml: [',
        );

        expect(result, isNull);
      });
    });
  });
}
