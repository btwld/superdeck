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
      // === BASIC TRAVERSAL TESTS ===
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

      test('throws on single .. segment', () {
        expect(
          () => UriValidator.validate('assets/../secret.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      // === BACKSLASH TRAVERSAL TESTS ===
      test('throws on backslash traversal', () {
        expect(
          () => UriValidator.validate(r'..\..\..\secrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on mixed slash/backslash traversal', () {
        expect(
          () => UriValidator.validate(r'../..\..\secrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on backslash traversal in file URI', () {
        expect(
          () => UriValidator.validate(
            r'file:///C:\Users\..\..\..\Windows\System32',
          ),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      // === PERCENT-ENCODED SEPARATOR TESTS ===
      test('throws on percent-encoded forward slash traversal', () {
        // %2f is URL-encoded /
        expect(
          () => UriValidator.validate('..%2f..%2f..%2fsecrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on uppercase percent-encoded forward slash', () {
        // %2F (uppercase) is also URL-encoded /
        expect(
          () => UriValidator.validate('..%2F..%2F..%2Fsecrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on percent-encoded backslash traversal', () {
        // %5c is URL-encoded \
        expect(
          () => UriValidator.validate('..%5c..%5c..%5csecrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on uppercase percent-encoded backslash', () {
        // %5C (uppercase) is also URL-encoded \
        expect(
          () => UriValidator.validate('..%5C..%5C..%5Csecrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      // === PERCENT-ENCODED DOT TESTS ===
      test('throws on mixed case percent-encoded traversal', () {
        // Mixed case: %2E%2e (uppercase E, lowercase e)
        expect(
          () => UriValidator.validate('%2E%2e/%2e%2E/secrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on fully lowercase percent-encoded dots', () {
        // %2e%2e is URL-encoded ..
        expect(
          () => UriValidator.validate('%2e%2e/%2e%2e/secrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on fully uppercase percent-encoded dots', () {
        // %2E%2E is URL-encoded ..
        expect(
          () => UriValidator.validate('%2E%2E/%2E%2E/secrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      test('throws on percent-encoded dots with encoded separator', () {
        // Combined: %2e%2e (encoded ..) with %2f (encoded /)
        expect(
          () => UriValidator.validate('%2e%2e%2f%2e%2e%2fsecrets.txt'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Path traversal'),
            ),
          ),
        );
      });

      // === HTTP/HTTPS EXEMPTION TESTS ===
      test('allows .. in HTTP URL path (intentionally permissive)', () {
        // HTTP URLs are exempt from traversal checks because:
        // 1. The server controls what path resolves to
        // 2. Browsers already handle this safely
        final uri = UriValidator.validate(
          'http://example.com/../../../etc/passwd',
        );
        expect(uri, isNotNull);
        expect(uri!.scheme, 'http');
      });

      test('allows .. in HTTPS URL path (intentionally permissive)', () {
        final uri = UriValidator.validate(
          'https://example.com/../../../etc/passwd',
        );
        expect(uri, isNotNull);
        expect(uri!.scheme, 'https');
      });

      // === SAFE DOUBLE-DOT FILENAME TESTS ===
      test('allows filenames containing double dots', () {
        // Filenames like '..config.png' should be allowed
        final uri = UriValidator.validate('assets/..config.png');
        expect(uri, isNotNull);
        expect(uri!.path, 'assets/..config.png');
      });

      test('allows filenames with dots in middle', () {
        // Filenames like 'foo..bar.txt' should be allowed
        final uri = UriValidator.validate('data/foo..bar.txt');
        expect(uri, isNotNull);
        expect(uri!.path, 'data/foo..bar.txt');
      });

      test('allows filename starting with triple dots', () {
        final uri = UriValidator.validate('assets/...config.png');
        expect(uri, isNotNull);
        expect(uri!.path, 'assets/...config.png');
      });

      test('allows filename ending with double dots', () {
        final uri = UriValidator.validate('assets/config..png');
        expect(uri, isNotNull);
        expect(uri!.path, 'assets/config..png');
      });

      test('allows directory with dots in name (not traversal)', () {
        // Directory name 'foo..bar' is not traversal
        final uri = UriValidator.validate('foo..bar/image.png');
        expect(uri, isNotNull);
        expect(uri!.path, 'foo..bar/image.png');
      });

      test('allows file URI with dots in filename', () {
        final uri = UriValidator.validate('file:///tmp/..hidden/..config.txt');
        expect(uri, isNotNull);
        expect(uri!.path, '/tmp/..hidden/..config.txt');
      });

      // === SAFE PATH TESTS ===
      test('allows normal file path', () {
        final uri = UriValidator.validate('file:///tmp/cache/image.png');
        expect(uri, isNotNull);
        expect(uri!.path, '/tmp/cache/image.png');
      });

      test('allows deeply nested relative path', () {
        final uri = UriValidator.validate('assets/images/icons/small/logo.png');
        expect(uri, isNotNull);
        expect(uri!.path, 'assets/images/icons/small/logo.png');
      });

      test('allows single dot in path (current directory)', () {
        // Note: Uri.parse normalizes './' away, so the path becomes 'assets/logo.png'
        final uri = UriValidator.validate('./assets/logo.png');
        expect(uri, isNotNull);
        // The important thing is that it doesn't throw (single dot is not traversal)
        expect(uri!.path, 'assets/logo.png'); // Uri normalizes ./ away
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
