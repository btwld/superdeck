import 'package:flutter_test/flutter_test.dart';
import 'package:superdeck/src/utils/uri_validator.dart';

void main() {
  group('UriValidator', () {
    group('validate - valid URIs', () {
      test('accepts valid HTTP URL', () {
        final uri = UriValidator.validate('http://example.com/image.png');
        expect(uri, isNotNull);
        expect(uri!.scheme, 'http');
      });

      test('accepts valid HTTPS URL', () {
        final uri = UriValidator.validate('https://example.com/image.png');
        expect(uri, isNotNull);
        expect(uri!.scheme, 'https');
      });

      test('accepts relative asset path', () {
        final uri = UriValidator.validate('assets/logo.png');
        expect(uri, isNotNull);
        expect(uri!.scheme, isEmpty);
      });

      test('accepts valid file path (no traversal)', () {
        final uri = UriValidator.validate('file:///tmp/image.png');
        expect(uri, isNotNull);
        expect(uri!.scheme, 'file');
      });
    });

    group('validate - null/empty', () {
      test('returns null for null source', () {
        final uri = UriValidator.validate(null);
        expect(uri, isNull);
      });

      test('returns null for empty string', () {
        final uri = UriValidator.validate('');
        expect(uri, isNull);
      });

      test('returns null for whitespace-only string', () {
        final uri = UriValidator.validate('   ');
        expect(uri, isNull);
      });
    });

    group('validate - malformed URIs', () {
      test('throws on URI with no scheme delimiter', () {
        expect(
          () => UriValidator.validate('://broken'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws on URI with invalid characters', () {
        expect(
          () => UriValidator.validate('ht!tp://invalid'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws on completely malformed URI', () {
        expect(
          () => UriValidator.validate('[::]:invalid'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('validate - unsupported schemes', () {
      test('throws on javascript: scheme', () {
        expect(
          () => UriValidator.validate('javascript:alert("xss")'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Unsupported URI scheme'),
            ),
          ),
        );
      });

      test('throws on data: scheme', () {
        expect(
          () => UriValidator.validate('data:image/png;base64,abc123'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Unsupported URI scheme'),
            ),
          ),
        );
      });

      test('throws on blob: scheme', () {
        expect(
          () => UriValidator.validate('blob:abc-123'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Unsupported URI scheme'),
            ),
          ),
        );
      });

      test('throws on asset: scheme (not supported)', () {
        expect(
          () => UriValidator.validate('asset://assets/logo.png'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Unsupported URI scheme'),
            ),
          ),
        );
      });
    });

    group('validate - path traversal prevention', () {
      test('throws on .. in file path', () {
        expect(
          () => UriValidator.validate('file:///../../../etc/passwd'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on .. in relative path', () {
        expect(
          () => UriValidator.validate('../../../secrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('allows normal file path', () {
        final uri = UriValidator.validate('file:///tmp/cache/image.png');
        expect(uri, isNotNull);
        expect(uri!.path, '/tmp/cache/image.png');
      });
    });

    group('validate - protocol-relative URIs', () {
      test('throws on protocol-relative URIs', () {
        expect(
          () => UriValidator.validate('//example.com/image.png'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Protocol-relative URIs are not supported'),
            ),
          ),
        );
      });
    });

    group('validate - network URIs', () {
      test('accepts localhost URLs (intentionally permissive)', () {
        final uri = UriValidator.validate('http://localhost:8080/image.png');
        expect(uri, isNotNull);
        expect(uri!.host, 'localhost');
      });

      test('accepts private IP addresses (intentionally permissive)', () {
        final uri = UriValidator.validate('http://192.168.1.1/image.png');
        expect(uri, isNotNull);
        expect(uri!.host, '192.168.1.1');
      });

      test('accepts 127.0.0.1 (intentionally permissive)', () {
        final uri = UriValidator.validate('http://127.0.0.1/image.png');
        expect(uri, isNotNull);
        expect(uri!.host, '127.0.0.1');
      });
    });
  });
}
