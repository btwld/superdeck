import 'package:superdeck/src/parsers/string_option_parser.dart';
import 'package:test/test.dart';

void main() {
  group('$StringOptionsParser', () {
    final parser = const StringOptionsParser();
    test('Parses single boolean option without value', () {
      expect(parser.parse('showLineNumbers=true').value,
          {'showLineNumbers': true});
    });

    // number example
    test('Parses number option', () {
      expect(parser.parse('count=10').value, {'count': 10});
      expect(parser.parse('count=10.5').value, {'count': 10.5});
      expect(parser.parse('count=-10.5').value, {'count': -10.5});
    });

    test('Parses single boolean option without equal sign', () {
      expect(parser.parse('showLineNumbers').value, {'showLineNumbers': true});
    });

    test('Parses boolean options with true and false', () {
      expect(parser.parse('showLineNumbers=true').value,
          {'showLineNumbers': true});
      expect(parser.parse('showLineNumbers=false').value,
          {'showLineNumbers': false});
    });

    test('Parses string options with quotes', () {
      expect(parser.parse('fileName="example.dart"').value,
          {'fileName': 'example.dart'});
      expect(parser.parse('anotherOption="another_example.dart"').value,
          {'anotherOption': 'another_example.dart'});
    });

    test('Parses list options', () {
      expect(
        parser.parse('options=["option1", "option2", "option3"]').value,
        {
          'options': ['option1', 'option2', 'option3']
        },
      );
      expect(parser.parse('lines=[2-5,3]').value, {
        'lines': [2, 3, 4, 5]
      });
    });

    test('Parses multiple options on the same line separated by spaces', () {
      expect(parser.parse('flex=1 align="center"').value,
          {'flex': 1, 'align': 'center'});
      expect(parser.parse('flex=3 align="top_left"').value,
          {'flex': 3, 'align': 'top_left'});
    });

    test('Handles mixed types', () {
      expect(
        parser
            .parse(
                'showLineNumbers=true fileName="test.dart" options=["opt1", "opt2"] flex=2')
            .value,
        {
          'showLineNumbers': true,
          'fileName': 'test.dart',
          'options': ['opt1', 'opt2'],
          'flex': 2,
        },
      );
    });

    test('Handles expressions without values gracefully', () {
      expect(
        parser.parse('showLineNumbers fileName="test.dart"').value,
        {
          'showLineNumbers': true,
          'fileName': 'test.dart',
        },
      );
    });

    test('Handles lists with quoted items', () {
      expect(
        parser.parse('options=["option one", "option two"]').value,
        {
          'options': ['option one', 'option two']
        },
      );
    });

    test('Handles numeric values', () {
      expect(parser.parse('count=10 threshold=15.5').value,
          {'count': 10, 'threshold': 15.5});
    });

    test('Handles extended key characters', () {
      expect(
        parser
            .parse(
                'user-name="JohnDoe" user.email="john.doe@example.com" isAdmin=true')
            .value,
        {
          'user-name': 'JohnDoe',
          'user.email': 'john.doe@example.com',
          'isAdmin': true,
        },
      );
    });

    test('Handles empty input', () {
      expect(parser.parse('').value, {});
    });

    test('Handles keys with underscores and numbers', () {
      expect(parser.parse('key_1=10 key_2="value"').value,
          {'key_1': 10, 'key_2': 'value'});
    });

    test('Handles keys with camelCase and PascalCase', () {
      expect(parser.parse('camelCaseKey=true PascalCaseKey="value"').value,
          {'camelCaseKey': true, 'PascalCaseKey': 'value'});
    });

    test('Handles values with special characters', () {
      expect(parser.parse('key="!@#\$%^&*()_+-=[]{}|;:,.<>?"').value,
          {'key': '!@#\$%^&*()_+-=[]{}|;:,.<>?'});
    });

    test('Handles negative numeric values', () {
      expect(parser.parse('negativeInt=-10 negativeDouble=-3.14').value,
          {'negativeInt': -10, 'negativeDouble': -3.14});
    });

    test('Handles list options with numeric values', () {
      expect(parser.parse('numbers=[1, 2, 3]').value, {
        'numbers': [1, 2, 3]
      });
    });

    test('Handles list options with boolean values', () {
      expect(parser.parse('booleans=[true, false]').value, {
        'booleans': [true, false]
      });
    });
  });
}
