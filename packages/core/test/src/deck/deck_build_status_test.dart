import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeckBuildPhase', () {
    test('enum names match expected wire values', () {
      expect(DeckBuildPhase.building.name, 'building');
      expect(DeckBuildPhase.success.name, 'success');
      expect(DeckBuildPhase.failure.name, 'failure');
      expect(DeckBuildPhase.unknown.name, 'unknown');
    });
  });

  group('DeckBuildError', () {
    test('toJson/fromObject round-trip', () {
      const error = DeckBuildError(message: 'Build failed');

      final parsed = DeckBuildError.fromObject(error.toJson());

      expect(parsed, error);
    });

    test('discards unknown persisted fields', () {
      final parsed = DeckBuildError.fromJson({
        'message': 'Build failed',
        'legacyCode': 42,
      });

      expect(parsed.toJson(), {'message': 'Build failed'});
    });
  });

  group('DeckBuildStatus', () {
    test('toJson/fromObject round-trip', () {
      final timestamp = DateTime.parse('2026-03-10T12:00:00.000Z');
      final status = DeckBuildStatus(
        phase: DeckBuildPhase.success,
        timestamp: timestamp,
        slideCount: 7,
      );

      final parsed = DeckBuildStatus.fromObject(status.toJson());

      expect(parsed, status);
    });

    test('returns null for unknown phase', () {
      final parsed = DeckBuildStatus.fromObject({
        'status': 'not-a-phase',
        'timestamp': '2026-03-10T12:00:00.000Z',
      });

      expect(parsed, isNull);
    });

    test('returns null when timestamp is missing or invalid', () {
      final missing = DeckBuildStatus.fromObject({'status': 'success'});
      final invalid = DeckBuildStatus.fromObject({
        'status': 'success',
        'timestamp': 'not-a-date',
      });

      expect(missing, isNull);
      expect(invalid, isNull);
    });

    test('discards unknown persisted fields', () {
      final parsed = DeckBuildStatus.fromJson({
        'status': 'success',
        'timestamp': '2026-03-10T12:00:00.000Z',
        'legacyProgress': 100,
      });

      expect(parsed.toJson(), isNot(contains('legacyProgress')));
    });
  });
}
