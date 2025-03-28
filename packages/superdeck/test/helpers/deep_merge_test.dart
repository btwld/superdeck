import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/modules/common/helpers/deep_merge.dart';

void main() {
  group('deepMerge', () {
    test('merges two maps with no overlapping keys', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'c': 3, 'd': 4};
      final expected = {'a': 1, 'b': 2, 'c': 3, 'd': 4};
      expect(deepMerge(map1, map2), expected);
    });

    test('merges two maps with overlapping keys', () {
      final map1 = {'a': 1, 'b': 2};
      final map2 = {'b': 3, 'c': 4};
      final expected = {'a': 1, 'b': 3, 'c': 4};
      expect(deepMerge(map1, map2), expected);
    });

    test('merges nested maps', () {
      final map1 = {
        'a': 1,
        'b': {'c': 2, 'd': 3}
      };
      final map2 = {
        'b': {'d': 4, 'e': 5},
        'f': 6
      };
      final expected = {
        'a': 1,
        'b': {'c': 2, 'd': 4, 'e': 5},
        'f': 6
      };
      expect(deepMerge(map1, map2), expected);
    });

    test('merges maps with null values', () {
      final map1 = {'a': 1, 'b': null};
      final map2 = {'b': 2, 'c': null};
      final expected = {'a': 1, 'b': 2, 'c': null};
      expect(deepMerge(map1, map2), expected);
    });

    test('returns an empty map when merging two empty maps', () {
      expect(deepMerge({}, {}), {});
    });
  });
}
