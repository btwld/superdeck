import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:superdeck/src/markdown/builders/image_element_builder.dart';

/// Security regression tests for [ImageElementBuilder].
///
/// This file only covers the unsupported no-[BuildContext] path.
/// Widget tests in `image_element_rendering_test.dart` cover URI validation
/// and rendering behavior.
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
  });
}
