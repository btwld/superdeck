import 'package:flutter_test/flutter_test.dart';
import 'package:playground/features/ai/wizard/core/ai/catalog/catalog_data_normalizer.dart';

void main() {
  group('normalizeCatalogData', () {
    test('promotes literalNumber ints to doubles', () {
      final result = normalizeCatalogData({'literalNumber': 5});
      expect((result as Map)['literalNumber'], 5.0);
      expect(result['literalNumber'], isA<double>());
    });

    test('leaves literalNumber that is already a double untouched', () {
      final result = normalizeCatalogData({'literalNumber': 5.5}) as Map;
      expect(result['literalNumber'], 5.5);
    });

    test('does not coerce other integer keys', () {
      final result = normalizeCatalogData({'count': 5}) as Map;
      expect(result['count'], 5);
      expect(result['count'], isA<int>());
    });

    test('recurses into nested maps', () {
      final result =
          normalizeCatalogData({
                'outer': {'literalNumber': 3},
              })
              as Map;
      expect((result['outer'] as Map)['literalNumber'], 3.0);
    });

    test('recurses into lists', () {
      final result =
          normalizeCatalogData([
                {'literalNumber': 1},
                {'literalNumber': 2},
              ])
              as List;
      expect((result[0] as Map)['literalNumber'], 1.0);
      expect((result[1] as Map)['literalNumber'], 2.0);
    });

    test('drops non-string keys', () {
      final result = normalizeCatalogData({1: 'a', 'b': 'c'}) as Map;
      expect(result.containsKey(1), isFalse);
      expect(result['b'], 'c');
    });

    test('passes through scalars and null unchanged', () {
      expect(normalizeCatalogData('text'), 'text');
      expect(normalizeCatalogData(42), 42);
      expect(normalizeCatalogData(null), isNull);
    });
  });
}
