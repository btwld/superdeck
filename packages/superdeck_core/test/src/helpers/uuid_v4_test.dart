import 'package:superdeck_core/src/helpers/uuid_v4.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  group('uuidV4', () {
    test('generates a valid UUID v4 string', () {
      final uuid = uuidV4();
      expect(uuid, isValidUuidV4());
    });

    test('generates unique UUIDs on multiple calls', () {
      final uuid1 = uuidV4();
      final uuid2 = uuidV4();
      final uuid3 = uuidV4();

      expect(uuid1, isNot(equals(uuid2)));
      expect(uuid1, isNot(equals(uuid3)));
      expect(uuid2, isNot(equals(uuid3)));
    });

    test('UUID format is correct', () {
      final uuid = uuidV4();

      // UUID v4 should have 36 characters (32 hex digits + 4 hyphens)
      expect(uuid.length, equals(36));

      // Should have hyphens at correct positions
      expect(uuid[8], equals('-'));
      expect(uuid[13], equals('-'));
      expect(uuid[18], equals('-'));
      expect(uuid[23], equals('-'));

      // The version number should be 4
      expect(uuid[14], equals('4'));

      // The variant should be 8, 9, a, or b
      expect('89ab'.contains(uuid[19]), isTrue);
    });
  });
}
