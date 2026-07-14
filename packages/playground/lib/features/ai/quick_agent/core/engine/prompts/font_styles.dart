import '../../../../../../core/domain/design/presentation_typography_catalog.dart';

/// Wizard-facing headline choices backed by the shared typography catalog.
enum HeadlineFont {
  playfairDisplay,
  montserrat,
  poppins,
  oswald,
  lobster;

  PresentationFontDescriptor get descriptor =>
      _catalog.resolve(name) ?? (throw StateError('Unknown font $name'));

  String get title => descriptor.family;
  String get fontFamily => descriptor.family;
  String get description => descriptor.description;
  String get id => name;

  static HeadlineFont? fromId(String id) {
    for (final font in values) {
      if (font.name == id || font.fontFamily == id) return font;
    }
    return null;
  }

  static String get schemaDescription =>
      'Headline font. Choose from: ${values.map((font) => '${font.name} '
          '(${font.description})').join(', ')}.';
}

/// Wizard-facing body choices backed by the shared typography catalog.
enum BodyFont {
  inter,
  openSans,
  lato,
  roboto,
  sourceSerif4;

  PresentationFontDescriptor get descriptor =>
      _catalog.resolve(name) ?? (throw StateError('Unknown font $name'));

  String get title => descriptor.family;
  String get fontFamily => descriptor.family;
  String get description => descriptor.description;
  String get id => name;

  static BodyFont? fromId(String id) {
    for (final font in values) {
      if (font.name == id || font.fontFamily == id) return font;
    }
    return null;
  }

  static String get schemaDescription =>
      'Body font. Choose from: ${values.map((font) => '${font.name} '
          '(${font.description})').join(', ')}.';
}

final _catalog = PresentationTypographyCatalog.withDefaults();
