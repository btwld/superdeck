/// Predefined font styles for presentation generation.
///
/// AI selects from enum values, widget loads full metadata.
/// Ensures only valid Google Fonts are used.
library;

/// Headline fonts for presentation titles and headers.
///
/// Enhanced enum where:
/// - Enum value name = ID used in schema (e.g., `montserrat`, `playfairDisplay`)
/// - `title`: Display name for UI
/// - `fontFamily`: Exact Google Fonts family name
/// - `description`: Short description for AI selection
enum HeadlineFont {
  playfairDisplay(
    title: 'Playfair Display',
    fontFamily: 'Playfair Display',
    description: 'Elegant serif - formal presentations',
  ),
  montserrat(
    title: 'Montserrat',
    fontFamily: 'Montserrat',
    description: 'Modern geometric sans - professional',
  ),
  poppins(
    title: 'Poppins',
    fontFamily: 'Poppins',
    description: 'Friendly rounded sans - approachable',
  ),
  oswald(
    title: 'Oswald',
    fontFamily: 'Oswald',
    description: 'Bold condensed - impactful headers',
  ),
  lobster(
    title: 'Lobster',
    fontFamily: 'Lobster',
    description: 'Playful script - creative/casual',
  );

  const HeadlineFont({
    required this.title,
    required this.fontFamily,
    required this.description,
  });

  /// Display name shown to users.
  final String title;

  /// Exact Google Fonts family name for loading.
  final String fontFamily;

  /// Short description for AI selection guidance.
  final String description;

  /// ID is the enum value name (e.g., "montserrat", "playfairDisplay").
  String get id => name;

  /// Finds a font by ID (enum name), returns null if not found.
  static HeadlineFont? fromId(String id) {
    for (final font in values) {
      if (font.name == id) return font;
    }
    return null;
  }

  /// Schema description with all fonts and their descriptions.
  static String get schemaDescription {
    final options = values
        .map((f) => '${f.name} (${f.description})')
        .join(', ');
    return 'Headline font. Choose from: $options.';
  }
}

/// Body fonts for presentation content text.
///
/// Enhanced enum where:
/// - Enum value name = ID used in schema (e.g., `inter`, `openSans`)
/// - `title`: Display name for UI
/// - `fontFamily`: Exact Google Fonts family name
/// - `description`: Short description for AI selection
enum BodyFont {
  inter(
    title: 'Inter',
    fontFamily: 'Inter',
    description: 'Clean modern sans - high readability',
  ),
  openSans(
    title: 'Open Sans',
    fontFamily: 'Open Sans',
    description: 'Friendly humanist - versatile',
  ),
  lato(
    title: 'Lato',
    fontFamily: 'Lato',
    description: 'Warm semi-rounded - professional',
  ),
  roboto(
    title: 'Roboto',
    fontFamily: 'Roboto',
    description: 'Neutral mechanical - technical content',
  ),
  sourceSerif4(
    title: 'Source Serif 4',
    fontFamily: 'Source Serif 4',
    description: 'Readable serif - long-form content',
  );

  const BodyFont({
    required this.title,
    required this.fontFamily,
    required this.description,
  });

  /// Display name shown to users.
  final String title;

  /// Exact Google Fonts family name for loading.
  final String fontFamily;

  /// Short description for AI selection guidance.
  final String description;

  /// ID is the enum value name (e.g., "inter", "openSans").
  String get id => name;

  /// Finds a font by ID (enum name), returns null if not found.
  static BodyFont? fromId(String id) {
    for (final font in values) {
      if (font.name == id) return font;
    }
    return null;
  }

  /// Schema description with all fonts and their descriptions.
  static String get schemaDescription {
    final options = values
        .map((f) => '${f.name} (${f.description})')
        .join(', ');
    return 'Body font. Choose from: $options.';
  }
}
