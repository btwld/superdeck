import 'package:flutter_test/flutter_test.dart';
import 'package:playground/core/domain/design/presentation_typography_catalog.dart';

void main() {
  test('resolves curated fonts by stable ID or exact family name', () {
    final catalog = PresentationTypographyCatalog.withDefaults();

    expect(catalog.resolve('playfair-display')?.family, 'Playfair Display');
    expect(catalog.resolve('Playfair Display')?.id, 'playfair-display');
    expect(catalog.resolve('definitely invented'), isNull);
    expect(
      catalog.forRole(PresentationFontRole.body).map((font) => font.family),
      containsAll(['Inter', 'Source Serif 4', 'DM Sans']),
    );
  });

  test('accepts an application-registered bundled custom family', () {
    const custom = PresentationFontDescriptor(
      id: 'brand-sans',
      family: 'Brand Sans',
      description: 'The application brand family',
      source: PresentationFontSource.bundled,
      roles: {PresentationFontRole.headline, PresentationFontRole.body},
      weights: {400, 600, 700},
    );
    final catalog = PresentationTypographyCatalog.withDefaults(
      registeredFonts: const [custom],
    );

    expect(catalog.resolve('Brand Sans'), same(custom));
    expect(
      catalog.supports('brand-sans', PresentationFontRole.headline),
      isTrue,
    );
    expect(catalog.supports('brand-sans', PresentationFontRole.body), isTrue);
  });
}
