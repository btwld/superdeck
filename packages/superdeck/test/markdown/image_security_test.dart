import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck/src/markdown/builders/image_element_builder.dart';

/// Integration tests for ImageElementBuilder security features.
///
/// These tests verify that malicious or malformed URIs are properly handled
/// and don't cause crashes or security vulnerabilities.
///
/// NOTE: ImageElementBuilder now requires BuildContext (as a block element).
/// These unit tests document that visitElementAfter throws UnsupportedError.
/// Real rendering happens through visitElementAfterWithContext in widget tests.
/// See image_element_rendering_test.dart for integration tests.
void main() {
  group('ImageElementBuilder - Security', () {
    late ImageElementBuilder builder;

    setUp(() {
      builder = ImageElementBuilder();
    });

    test('visitElementAfter throws UnsupportedError (requires context)', () {
      final element = md.Element.empty('img')..attributes['src'] = 'test.png';

      expect(
        () => builder.visitElementAfter(element, null),
        throwsA(isA<UnsupportedError>()),
      );
    });

    // NOTE: Security validation tests (URI validation, path traversal, etc.)
    // are tested indirectly through the widget tests in image_element_rendering_test.dart
    // since ImageElementBuilder now requires BuildContext access. The UriValidator
    // class handles all security validation and is used by visitElementAfterWithContext.
    //
    // Tested security features include:
    // - Malformed URIs → Error widget
    // - Path traversal (../..) → Error widget
    // - Unsupported schemes (javascript:, data:, blob:, asset:) → Error widget
    // - Empty/null src → Error widget
    // - Protocol-relative URLs (//example.com) → Error widget
    // - Valid HTTPS/HTTP/file:// URLs → Renders correctly
    // - Relative paths without traversal → Renders correctly
  });
}
