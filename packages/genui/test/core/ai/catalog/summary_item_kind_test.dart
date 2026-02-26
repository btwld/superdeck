import 'package:flutter_test/flutter_test.dart';

import 'package:superdeck_genui/src/ai/catalog/catalog.dart';

void main() {
  group('SummaryItem kind discriminator', () {
    test('accepts known kind values', () {
      final textItem = SummaryItemType.parse({
        'kind': 'text',
        'label': 'Topic',
        'text': 'Astronomy',
      });
      final styleItem = SummaryItemType.parse({
        'kind': 'style',
        'label': 'Style',
        'title': 'Cosmic Blue',
        'colors': ['#0F172A', '#60A5FA', '#94A3B8'],
        'headlineFont': 'oswald',
        'bodyFont': 'inter',
      });
      final imageItem = SummaryItemType.parse({
        'kind': 'imageStyle',
        'label': 'Image Style',
        'imageStyleId': 'minimalist',
      });

      expect(textItem.kind, SummaryItemKind.text);
      expect(styleItem.kind, SummaryItemKind.style);
      expect(imageItem.kind, SummaryItemKind.imageStyle);
      expect(textItem.shapeValidationError, isNull);
      expect(styleItem.shapeValidationError, isNull);
      expect(imageItem.shapeValidationError, isNull);
    });

    test('rejects unknown kind at schema parse level', () {
      final result = SummaryItemType.safeParse({
        'kind': 'unknown',
        'label': 'Topic',
        'text': 'Astronomy',
      });
      expect(result.getOrNull(), isNull);
    });

    test('flags invalid explicit kind combinations', () {
      final invalidStyle = SummaryItemType.parse({
        'kind': 'style',
        'label': 'Style',
        'title': 'Missing fields',
        'colors': ['#111111'],
      });
      final invalidText = SummaryItemType.parse({
        'kind': 'text',
        'label': 'Topic',
        'text': 'Astronomy',
        'imageStyleId': 'minimalist',
      });

      expect(
        invalidStyle.shapeValidationError,
        contains('requires colors/headlineFont/bodyFont'),
      );
      expect(
        invalidText.shapeValidationError,
        contains('should not include style or imageStyle fields'),
      );
    });

    test('legacy items without kind remain supported', () {
      final legacyStyle = SummaryItemType.parse({
        'label': 'Style',
        'title': 'Cosmic Blue',
        'colors': ['#0F172A', '#60A5FA', '#94A3B8'],
        'headlineFont': 'oswald',
        'bodyFont': 'inter',
      });
      final legacyImage = SummaryItemType.parse({
        'label': 'Image Style',
        'imageStyleId': 'minimalist',
      });
      final legacyText = SummaryItemType.parse({
        'label': 'Topic',
        'title': 'Astronomy',
      });

      expect(legacyStyle.kind, isNull);
      expect(legacyImage.kind, isNull);
      expect(legacyText.kind, isNull);
      expect(legacyStyle.shapeValidationError, isNull);
      expect(legacyImage.shapeValidationError, isNull);
      expect(legacyText.shapeValidationError, isNull);
    });
  });
}
