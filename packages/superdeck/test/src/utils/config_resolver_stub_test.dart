import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/config_resolver_stub.dart';
import 'package:superdeck_core/superdeck_core.dart';

void main() {
  group('resolveConfiguration (stub)', () {
    test('returns override when provided', () {
      final override = DeckConfiguration(slidesPath: 'override.md');

      final resolved = resolveConfiguration(override);

      expect(resolved, same(override));
    });

    test('returns default when no override is provided', () {
      final resolved = resolveConfiguration(null);

      expect(resolved, DeckConfiguration());
    });
  });
}
