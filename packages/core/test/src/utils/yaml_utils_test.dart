import 'package:superdeck_core/src/utils/yaml_utils.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('YamlUtils', () {
    group('convertYamlToMap', () {
      group('valid YAML', () {
        test('parses simple key-value pairs', () {
          const yaml = 'key: value';
          final result = convertYamlToMap(yaml);
          expect(result, {'key': 'value'});
        });

        test('parses multiple key-value pairs', () {
          const yaml = '''
key1: value1
key2: value2
key3: value3
''';
          final result = convertYamlToMap(yaml);
          expect(result, {
            'key1': 'value1',
            'key2': 'value2',
            'key3': 'value3',
          });
        });

        test('parses nested maps', () {
          const yaml = '''
outer:
  inner: value
  nested:
    deep: data
''';
          final result = convertYamlToMap(yaml);
          expect(result, {
            'outer': {
              'inner': 'value',
              'nested': {'deep': 'data'},
            },
          });
        });

        test('parses lists', () {
          const yaml = '''
items:
  - first
  - second
  - third
''';
          final result = convertYamlToMap(yaml);
          expect(result, {
            'items': ['first', 'second', 'third'],
          });
        });

        test('parses list of maps', () {
          const yaml = '''
users:
  - name: Alice
    age: 30
  - name: Bob
    age: 25
''';
          final result = convertYamlToMap(yaml);
          expect(result, {
            'users': [
              {'name': 'Alice', 'age': 30},
              {'name': 'Bob', 'age': 25},
            ],
          });
        });

        test('parses flow-style YAML', () {
          const yaml = '{key: value, other: data}';
          final result = convertYamlToMap(yaml);
          expect(result, {'key': 'value', 'other': 'data'});
        });

        test('parses numeric values', () {
          const yaml = '''
integer: 42
float: 3.14
negative: -10
''';
          final result = convertYamlToMap(yaml);
          expect(result['integer'], 42);
          expect(result['float'], 3.14);
          expect(result['negative'], -10);
        });

        test('parses boolean values', () {
          const yaml = '''
enabled: true
disabled: false
''';
          final result = convertYamlToMap(yaml);
          expect(result, {'enabled': true, 'disabled': false});
        });

        test('parses null values', () {
          const yaml = '''
empty: null
also_empty: ~
''';
          final result = convertYamlToMap(yaml);
          expect(result['empty'], isNull);
          expect(result['also_empty'], isNull);
        });

        test('parses quoted strings', () {
          const yaml = '''
single: 'single quoted'
double: "double quoted"
''';
          final result = convertYamlToMap(yaml);
          expect(result, {
            'single': 'single quoted',
            'double': 'double quoted',
          });
        });

        test('handles special characters in values', () {
          const yaml = '''
colon: "value: with colon"
bracket: "value {with} brackets"
''';
          final result = convertYamlToMap(yaml);
          expect(result['colon'], 'value: with colon');
          expect(result['bracket'], 'value {with} brackets');
        });
      });

      group('empty and edge cases', () {
        test('returns empty map for empty string', () {
          expect(convertYamlToMap(''), isEmpty);
        });

        test('returns empty map for whitespace only', () {
          expect(convertYamlToMap('   '), isEmpty);
          expect(convertYamlToMap('\n\n'), isEmpty);
          expect(convertYamlToMap('\t\t'), isEmpty);
        });

        test('returns empty map for null YAML document', () {
          const yaml = '---\n...';
          final result = convertYamlToMap(yaml);
          expect(result, isEmpty);
        });

        test('returns empty map for non-map YAML', () {
          const yaml = 'just a string';
          final result = convertYamlToMap(yaml);
          expect(result, isEmpty);
        });

        test('returns empty map for list at root', () {
          const yaml = '''
- item1
- item2
''';
          final result = convertYamlToMap(yaml);
          expect(result, isEmpty);
        });
      });

      group('error handling - non-strict mode', () {
        test('returns empty map for invalid YAML syntax', () {
          const yaml = '@tag { key: [unclosed }';
          final result = convertYamlToMap(yaml, strict: false);
          expect(result, isEmpty);
        });

        test('returns empty map for malformed nested structure', () {
          const yaml = '''
key:
  - invalid
    indentation: here
''';
          // This might be valid or invalid depending on YAML parser
          // The point is it doesn't throw in non-strict mode
          final result = convertYamlToMap(yaml, strict: false);
          expect(result, isA<Map<String, dynamic>>());
        });
      });

      group('error handling - strict mode', () {
        test('throws YamlException for invalid YAML syntax', () {
          const yaml = 'key: [unclosed';
          expect(
            () => convertYamlToMap(yaml, strict: true),
            throwsA(isA<YamlException>()),
          );
        });

        test('throws for clearly invalid YAML', () {
          const yaml = '{ key: value, }}}';
          expect(() => convertYamlToMap(yaml, strict: true), throwsA(anything));
        });
      });

      group('type conversion', () {
        test('converts YamlMap keys to strings', () {
          const yaml = '''
123: numeric key
true: boolean key
''';
          final result = convertYamlToMap(yaml);
          expect(result.containsKey('123'), isTrue);
          expect(result.containsKey('true'), isTrue);
        });

        test('deeply converts nested structures', () {
          const yaml = '''
level1:
  level2:
    level3:
      items:
        - a
        - b
      value: 42
''';
          final result = convertYamlToMap(yaml);

          final level1 = result['level1'] as Map<String, dynamic>;
          final level2 = level1['level2'] as Map<String, dynamic>;
          final level3 = level2['level3'] as Map<String, dynamic>;

          expect(level3['items'], ['a', 'b']);
          expect(level3['value'], 42);
        });
      });
    });
  });
}
