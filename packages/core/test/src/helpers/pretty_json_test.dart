import 'package:superdeck_core/src/utils/pretty_json.dart';
import 'package:test/test.dart';

void main() {
  group('prettyJson', () {
    test('formats a simple map correctly', () {
      final input = {'name': 'John', 'age': 30};
      final expected = '''{
  "name": "John",
  "age": 30
}''';

      expect(prettyJson(input), equals(expected));
    });

    test('formats a nested map correctly', () {
      final input = {
        'person': {
          'name': 'John',
          'age': 30,
          'address': {'city': 'New York', 'zip': '10001'}
        }
      };

      final expected = '''{
  "person": {
    "name": "John",
    "age": 30,
    "address": {
      "city": "New York",
      "zip": "10001"
    }
  }
}''';

      expect(prettyJson(input), equals(expected));
    });

    test('formats a list correctly', () {
      final input = [1, 2, 3, 4, 5];
      final expected = '''[
  1,
  2,
  3,
  4,
  5
]''';

      expect(prettyJson(input), equals(expected));
    });

    test('formats a complex structure correctly', () {
      final input = {
        'items': [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'}
        ],
        'count': 2
      };

      final expected = '''{
  "items": [
    {
      "id": 1,
      "name": "Item 1"
    },
    {
      "id": 2,
      "name": "Item 2"
    }
  ],
  "count": 2
}''';

      expect(prettyJson(input), equals(expected));
    });
  });
}
