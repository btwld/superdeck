import 'package:superdeck_core/superdeck_core.dart';
import 'package:test/test.dart';

void main() {
  group('BuildStatus factories', () {
    test('building factory produces UTC timestamp', () {
      final status = BuildStatus.building();

      expect(status.type, BuildStatusType.building);
      expect(status.timestamp.isUtc, isTrue);
      expect(status.slideCount, isNull);
      expect(status.error, isNull);
    });

    test('success factory carries slide count into JSON', () {
      final status = BuildStatus.success(slideCount: 5);
      final json = status.toJson();

      expect(json['status'], 'success');
      expect(json['slideCount'], 5);
      expect(json.containsKey('error'), isFalse);

      final parsed = BuildStatus.fromJson(json);
      expect(parsed.type, BuildStatusType.success);
      expect(parsed.slideCount, 5);
    });

    test('failure factory captures error metadata', () {
      final stackTrace = StackTrace.current;
      final status = BuildStatus.failure(
        error: FormatException('bad data'),
        stackTrace: stackTrace,
      );

      expect(status.type, BuildStatusType.failure);
      expect(status.error, isNotNull);
      expect(status.error?['type'], 'FormatException');
      expect(status.error?['message'], contains('bad data'));
      expect(status.error?['stackTrace'], contains('build_status_test.dart'));
    });
  });

  group('BuildStatus.fromJson', () {
    test('parses numeric slide count as int', () {
      final json = {
        'status': 'success',
        'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
        'slideCount': 3.9,
      };

      final status = BuildStatus.fromJson(json);
      expect(status.slideCount, 3);
    });

    test('defaults unknown status to BuildStatusUnknown', () {
      final json = {
        'status': 'mystery',
        'timestamp': DateTime.utc(2024, 1, 1).toIso8601String(),
      };

      final status = BuildStatus.fromJson(json);
      expect(status, isA<BuildStatusUnknown>());
      expect(status.type, BuildStatusType.unknown);
    });

    test('throws FormatException when timestamp missing', () {
      expect(
        () => BuildStatus.fromJson({'status': 'success'}),
        throwsFormatException,
      );
    });
  });

  group('BuildStatus helpers', () {
    test('isNewerThan compares timestamps', () {
      final older = BuildStatus.success(timestamp: DateTime.utc(2024, 1, 1));
      final newer = BuildStatus.success(timestamp: DateTime.utc(2024, 1, 2));

      expect(newer.isNewerThan(older), isTrue);
      expect(older.isNewerThan(newer), isFalse);
    });
  });
}
