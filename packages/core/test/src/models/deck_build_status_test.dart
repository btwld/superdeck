import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeckBuildPhase', () {
    test('serializes and parses wire values', () {
      expect(DeckBuildPhase.building.wireValue, 'building');
      expect(DeckBuildPhase.fromWireValue('failure'), DeckBuildPhase.failure);
      expect(
        DeckBuildPhase.fromWireValue('unexpected'),
        DeckBuildPhase.unknown,
      );
    });
  });

  group('DeckBuildError', () {
    test('toMap/fromObject round-trip', () {
      const error = DeckBuildError(
        type: 'StateError',
        message: 'Build failed',
        stackTrace: 'stack',
      );

      final parsed = DeckBuildError.fromObject(error.toMap());

      expect(parsed, error);
    });
  });

  group('DeckBuildStatus', () {
    test('toMap/fromObject round-trip', () {
      final timestamp = DateTime.parse('2026-03-10T12:00:00.000Z');
      final status = DeckBuildStatus(
        phase: DeckBuildPhase.success,
        timestamp: timestamp,
        slideCount: 7,
      );

      final parsed = DeckBuildStatus.fromObject(status.toMap());

      expect(parsed, status);
    });

    test('parses unknown phase as unknown', () {
      final parsed = DeckBuildStatus.fromObject({
        'status': 'not-a-phase',
        'timestamp': '2026-03-10T12:00:00.000Z',
      });

      expect(parsed, isNotNull);
      expect(parsed!.phase, DeckBuildPhase.unknown);
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
  });
}
